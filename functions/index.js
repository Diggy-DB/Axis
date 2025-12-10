const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { OpenAI } = require('openai');

admin.initializeApp();

// Initialize OpenAI - will be initialized in function handlers with secret access
let openai;

/**
 * Scheduled function that runs at midnight (00:00) every day
 * Generates AI insights for users who completed reflections
 */
exports.generateDailyInsights = functions
  .runWith({ secrets: ['OPENAI_API_KEY'] })
  .pubsub
  .schedule('0 0 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    // Initialize OpenAI with the secret
    if (process.env.OPENAI_API_KEY) {
      openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    }
    console.log('Starting daily insights generation...');
    
    const db = admin.firestore();
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    try {
      // Get all users
      const usersSnapshot = await db.collection('users').get();
      console.log(`Processing ${usersSnapshot.size} users...`);

      const promises = usersSnapshot.docs.map(async (userDoc) => {
        const userId = userDoc.id;
        const userData = userDoc.data();
        
        try {
          // Get yesterday's reflection
          const reflectionsSnapshot = await db
            .collection(`users/${userId}/reflections`)
            .where('date', '>=', admin.firestore.Timestamp.fromDate(yesterday))
            .where('date', '<', admin.firestore.Timestamp.fromDate(today))
            .limit(1)
            .get();

          if (reflectionsSnapshot.empty) {
            console.log(`No reflection found for user ${userId}`);
            return null;
          }

          const reflectionDoc = reflectionsSnapshot.docs[0];
          const reflection = reflectionDoc.data();

          // Get completed tasks from yesterday
          const tasksSnapshot = await db
            .collection(`users/${userId}/tasks`)
            .where('completedAt', '>=', admin.firestore.Timestamp.fromDate(yesterday))
            .where('completedAt', '<', admin.firestore.Timestamp.fromDate(today))
            .get();

          const completedTasks = tasksSnapshot.docs.map(doc => doc.data());
          const tasksCompleted = completedTasks.length;

          // Calculate productive hours from actual schedule
          let productiveHours = 0;
          if (reflection.actualSchedule && Array.isArray(reflection.actualSchedule)) {
            reflection.actualSchedule.forEach(entry => {
              const start = entry.startTime.toDate();
              const end = entry.endTime.toDate();
              const hours = (end - start) / (1000 * 60 * 60);
              productiveHours += hours;
            });
          }

          // Generate AI prompt for next day
          const aiPromptForNextDay = await generateNextDayPrompt(
            reflection,
            userData,
            completedTasks
          );

          // Update reflection with AI prompt
          await reflectionDoc.ref.update({
            aiPromptForNextDay,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Generate daily summary
          const aiMessage = await generateDailySummary(
            reflection,
            completedTasks,
            productiveHours,
            userData
          );

          // Get key insight from recent reflections
          const recentReflectionsSnapshot = await db
            .collection(`users/${userId}/reflections`)
            .orderBy('date', 'desc')
            .limit(7)
            .get();

          const recentReflections = recentReflectionsSnapshot.docs.map(doc => doc.data());
          const keyInsight = await extractKeyInsight(recentReflections, userData);

          // Create daily summary for today
          await db.collection(`users/${userId}/dailySummaries`).add({
            date: admin.firestore.Timestamp.fromDate(today),
            aiMessage,
            tasksCompleted,
            productiveHours,
            keyInsight,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          console.log(`Generated insights for user ${userId}`);
          return { userId, success: true };
        } catch (error) {
          console.error(`Error processing user ${userId}:`, error);
          return { userId, success: false, error: error.message };
        }
      });

      const results = await Promise.all(promises);
      const successCount = results.filter(r => r?.success).length;
      console.log(`Completed: ${successCount}/${usersSnapshot.size} users processed successfully`);

      return null;
    } catch (error) {
      console.error('Error in generateDailyInsights:', error);
      throw error;
    }
  });

/**
 * Generate personalized prompt for next day
 */
async function generateNextDayPrompt(reflection, user, completedTasks) {
  if (!openai) {
    return 'Focus on your priorities today and make progress toward your goals.';
  }

  const taskTitles = completedTasks.map(t => t.title).join(', ');
  
  const prompt = `You are a personal productivity coach. Based on this user's reflection from yesterday, generate a brief, motivational prompt for today.

User Profile:
- Core Values: ${user.coreValues || 'Not specified'}
- Worldview: ${user.worldview || 'Not specified'}
- Ambition: ${user.ambition || 'Not specified'}

Yesterday's Reflection:
- Main thoughts: ${reflection.text}
- Mood: ${reflection.mood}/10
- Energy: ${reflection.energy}/10
- Tasks completed: ${taskTitles || 'None'}
${reflection.challenges ? `- Challenges: ${reflection.challenges}` : ''}
${reflection.wins ? `- Wins: ${reflection.wins}` : ''}

Generate a concise, personalized prompt (2-3 sentences) that:
1. Acknowledges their progress or challenges
2. Aligns with their values and ambition
3. Motivates them for today
4. Is encouraging but realistic

Keep it brief and actionable.`;

  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 150,
      temperature: 0.7,
    });

    return response.choices[0].message.content.trim();
  } catch (error) {
    console.error('Error generating next day prompt:', error);
    return 'Focus on your priorities today and make progress toward your goals.';
  }
}

/**
 * Generate daily summary message
 */
async function generateDailySummary(reflection, completedTasks, productiveHours, user) {
  if (!openai) {
    return `You completed ${completedTasks.length} tasks and logged ${productiveHours.toFixed(1)} productive hours. Keep up the great work!`;
  }

  const taskTitles = completedTasks.map(t => t.title).join(', ');
  
  const prompt = `You are a personal productivity coach. Create a brief, motivational summary for the user's home screen.

User Profile:
- Core Values: ${user.coreValues || 'Not specified'}
- Ambition: ${user.ambition || 'Not specified'}

Yesterday's Performance:
- Tasks completed: ${completedTasks.length}
- Productive hours: ${productiveHours.toFixed(1)}
- Mood: ${reflection.mood}/10
- Energy: ${reflection.energy}/10

Generate a warm, encouraging message (2-3 sentences) that:
1. Celebrates their accomplishments
2. References their productive hours and tasks
3. Motivates them to continue
4. Feels personal and uplifting

Keep it concise and positive.`;

  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 120,
      temperature: 0.8,
    });

    return response.choices[0].message.content.trim();
  } catch (error) {
    console.error('Error generating daily summary:', error);
    return `You completed ${completedTasks.length} tasks and logged ${productiveHours.toFixed(1)} productive hours. Keep up the great work!`;
  }
}

/**
 * Extract key insight from recent reflections
 */
async function extractKeyInsight(reflections, user) {
  if (reflections.length < 3) {
    return null; // Not enough data for patterns
  }

  if (!openai) {
    return null; // OpenAI not configured
  }

  const reflectionSummaries = reflections.map((r, index) => 
    `Day ${index + 1}: Mood ${r.mood}/10, Energy ${r.energy}/10${r.challenges ? `, Challenges: ${r.challenges}` : ''}`
  ).join('\n');

  const prompt = `You are an insightful productivity coach. Analyze these recent daily reflections and identify ONE key pattern or insight.

User Profile:
- Core Values: ${user.coreValues || 'Not specified'}

Recent Reflections:
${reflectionSummaries}

Identify ONE actionable insight about:
- Recurring patterns (mood, energy, challenges)
- Potential improvements
- Strengths to leverage

Provide a single, clear sentence (15-20 words max).`;

  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 50,
      temperature: 0.6,
    });

    return response.choices[0].message.content.trim();
  } catch (error) {
    console.error('Error extracting key insight:', error);
    return null;
  }
}

/**
 * Manual trigger function for testing (HTTP callable)
 */
exports.generateInsightsForUser = functions
  .runWith({ secrets: ['OPENAI_API_KEY'] })
  .https.onCall(async (data, context) => {
    // Initialize OpenAI with the secret
    if (process.env.OPENAI_API_KEY) {
      openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    }
    
    // Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to generate insights.'
      );
    }

    const userId = context.auth.uid;
    console.log(`Manual insight generation requested for user ${userId}`);

    const db = admin.firestore();
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    try {
      // Get user data
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'User not found');
      }
      const userData = userDoc.data();

      // Get yesterday's reflection
      const reflectionsSnapshot = await db
        .collection(`users/${userId}/reflections`)
        .where('date', '>=', admin.firestore.Timestamp.fromDate(yesterday))
        .where('date', '<', admin.firestore.Timestamp.fromDate(today))
        .limit(1)
        .get();

      if (reflectionsSnapshot.empty) {
        throw new functions.https.HttpsError('not-found', 'No reflection found for yesterday');
      }

      const reflectionDoc = reflectionsSnapshot.docs[0];
      const reflection = reflectionDoc.data();

      // Get completed tasks from yesterday
      const tasksSnapshot = await db
        .collection(`users/${userId}/tasks`)
        .where('completedAt', '>=', admin.firestore.Timestamp.fromDate(yesterday))
        .where('completedAt', '<', admin.firestore.Timestamp.fromDate(today))
        .get();

      const completedTasks = tasksSnapshot.docs.map(doc => doc.data());
      const tasksCompleted = completedTasks.length;

      // Calculate productive hours
      let productiveHours = 0;
      if (reflection.actualSchedule && Array.isArray(reflection.actualSchedule)) {
        reflection.actualSchedule.forEach(entry => {
          const start = entry.startTime.toDate();
          const end = entry.endTime.toDate();
          const hours = (end - start) / (1000 * 60 * 60);
          productiveHours += hours;
        });
      }

      // Generate AI content
      const aiPromptForNextDay = await generateNextDayPrompt(reflection, userData, completedTasks);
      const aiMessage = await generateDailySummary(reflection, completedTasks, productiveHours, userData);

      // Get recent reflections for key insight
      const recentReflectionsSnapshot = await db
        .collection(`users/${userId}/reflections`)
        .orderBy('date', 'desc')
        .limit(7)
        .get();

      const recentReflections = recentReflectionsSnapshot.docs.map(doc => doc.data());
      const keyInsight = await extractKeyInsight(recentReflections, userData);

      // Update reflection
      await reflectionDoc.ref.update({
        aiPromptForNextDay,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Create daily summary
      await db.collection(`users/${userId}/dailySummaries`).add({
        date: admin.firestore.Timestamp.fromDate(today),
        aiMessage,
        tasksCompleted,
        productiveHours,
        keyInsight,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: 'Insights generated successfully',
        summary: {
          tasksCompleted,
          productiveHours,
          aiMessage,
        },
      };
    } catch (error) {
      console.error('Error generating insights:', error);
      // Provide more detailed error message
      if (error.code) {
        throw error; // Re-throw HttpsError with proper code
      }
      throw new functions.https.HttpsError('internal', error.message || 'An unexpected error occurred');
    }
  });
