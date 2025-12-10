# Reflection System - Implementation Checklist

## ✅ Completed

### Models
- [x] Updated `Reflection` model with:
  - `completedTaskIds` - IDs of tasks completed that day
  - `actualSchedule` - List of ActualScheduleEntry (what user actually did)
  - `aiPromptForNextDay` - AI-generated prompt for next day
- [x] Created `ActualScheduleEntry` class for schedule entries
- [x] Created `DailySummary` model for AI summaries on home page

### Services
- [x] Created `OpenAIService` with three methods:
  - `generateNextDayPrompt()` - Creates personalized prompt
  - `generateDailySummary()` - Creates home page message
  - `extractKeyInsight()` - Extracts key patterns
- [x] Created `AppConfig` for loading environment variables

### UI
- [x] Implemented `ReflectionScreen` with:
  - Date selector with navigation
  - Completed tasks section (auto-populated from tasks)
  - Actual schedule section (hourly calendar filler)
  - Reflection text section with mood/energy/gratitude/wins/challenges
  - Display of AI-generated next day prompt

### Configuration
- [x] Added `flutter_dotenv` to pubspec.yaml
- [x] Added `.env` to assets
- [x] Updated `.env` file with OPENAI_API_KEY placeholder
- [x] Created comprehensive `REFLECTION_AI_GUIDE.md`

### Providers
- [x] Added `getReflectionForDate()` method to ReflectionProvider

## 🔨 To Do

### 1. Install Dependencies
```bash
cd axis
flutter pub get
```

### 2. Configure OpenAI API Key
1. Get API key from https://platform.openai.com/api-keys
2. Update `.env`:
   ```
   OPENAI_API_KEY=sk-your-actual-key-here
   ```

### 3. Initialize AppConfig in main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await AppConfig.load();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ... rest of main()
}
```

### 4. Create Reflection Editor Screens

#### Schedule Editor (`_ScheduleEditorScreen`)
Create a screen where users can:
- Add time blocks (activity, start time, end time)
- Edit existing time blocks
- Delete time blocks
- Save to reflection's `actualSchedule`

UI should be similar to calendar page but editable.

#### Reflection Text Editor (`_ReflectionEditorScreen`)
Create a form with:
- Text field for main reflection
- Sliders for mood (1-10) and energy (1-10)
- Optional text fields for gratitude, wins, challenges
- Save button that creates/updates Reflection document

### 5. Create DailySummary Repository

```dart
// lib/repositories/daily_summary_repository.dart
class DailySummaryRepository {
  final String userId;
  
  Stream<DailySummary?> streamTodaySummary();
  Future<DailySummary?> getSummaryForDate(DateTime date);
  Future<void> createSummary(DailySummary summary);
}
```

### 6. Create DailySummary Provider

```dart
// lib/providers/daily_summary_provider.dart
class DailySummaryProvider extends ChangeNotifier {
  DailySummary? _todaySummary;
  
  DailySummary? get todaySummary => _todaySummary;
  
  void updateUser(String? userId) {
    // Subscribe to today's summary stream
  }
}
```

### 7. Add Daily Summary to Home Page

In `lib/widgets/home/daily_insight_section.dart`:
```dart
class DailyInsightSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final summaryProvider = Provider.of<DailySummaryProvider>(context);
    final summary = summaryProvider.todaySummary;
    
    if (summary == null) return SizedBox.shrink();
    
    return Card(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome),
              Text('Daily Insight'),
            ],
          ),
          Text(summary.aiMessage),
          Row(
            children: [
              Text('${summary.tasksCompleted} tasks'),
              Text('${summary.productiveHours}h productive'),
            ],
          ),
        ],
      ),
    );
  }
}
```

Add this widget to home_screen.dart at the top.

### 8. Create Firebase Cloud Function for Midnight AI Generation

Create `functions/src/index.ts`:
```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

admin.initializeApp();

export const generateDailyAI = functions.pubsub
  .schedule('0 0 * * *') // Every midnight UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    const db = admin.firestore();
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    // Get all users
    const usersSnapshot = await db.collection('users').get();
    
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      
      // Get today's reflection
      const reflectionsSnapshot = await db
        .collection(`users/${userId}/reflections`)
        .where('date', '==', today)
        .limit(1)
        .get();
      
      if (reflectionsSnapshot.empty) continue;
      
      const reflection = reflectionsSnapshot.docs[0].data();
      
      // Get completed tasks
      const tasksSnapshot = await db
        .collection(`users/${userId}/tasks`)
        .where('status', '==', 'completed')
        .where('completedAt', '>=', today)
        .get();
      
      // Calculate productive hours
      const productiveHours = calculateProductiveHours(reflection.actualSchedule);
      
      // Call your OpenAI service
      const aiMessage = await generateAISummary(
        reflection,
        tasksSnapshot.size,
        productiveHours,
        userDoc.data()
      );
      
      // Generate next day prompt
      const nextDayPrompt = await generateNextPrompt(
        reflection,
        userDoc.data()
      );
      
      // Save next day prompt to reflection
      await reflectionsSnapshot.docs[0].ref.update({
        aiPromptForNextDay: nextDayPrompt
      });
      
      // Create daily summary
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);
      
      await db.collection(`users/${userId}/dailySummaries`).add({
        date: tomorrow,
        aiMessage: aiMessage,
        tasksCompleted: tasksSnapshot.size,
        productiveHours: productiveHours,
        createdAt: new Date()
      });
    }
    
    return null;
  });

function calculateProductiveHours(actualSchedule: any[]): number {
  if (!actualSchedule) return 0;
  
  let totalMinutes = 0;
  for (const entry of actualSchedule) {
    const start = entry.startTime.toDate();
    const end = entry.endTime.toDate();
    totalMinutes += (end.getTime() - start.getTime()) / (1000 * 60);
  }
  
  return totalMinutes / 60;
}
```

Deploy with:
```bash
cd functions
npm install
firebase deploy --only functions
```

### 9. Update Firestore Security Rules

Add to `firestore.rules`:
```
match /users/{userId}/dailySummaries/{summaryId} {
  allow read: if isOwner(userId);
  allow write: if false; // Only Cloud Function can write
}
```

### 10. Create Firestore Indexes

The actual schedule queries may need indexes. If you see errors, click the provided link to create them automatically.

### 11. Testing

1. Create a reflection with some text
2. Mark some tasks as completed
3. Fill in the actual schedule
4. Wait for midnight OR manually call the Cloud Function
5. Check home page for AI summary next day
6. Check reflection for next day's prompt

## Optional Enhancements

- [ ] Add reflection streaks (days in a row)
- [ ] Weekly reflection summaries
- [ ] Export reflections as PDF
- [ ] Voice input for reflections
- [ ] Reminder notifications at optimal time
- [ ] Reflection templates for different moods
- [ ] Share reflection insights with accountability partner

## Notes

- The reflection system is ready but needs the editor screens implemented
- AI features require OpenAI API key and Cloud Function deployment
- Consider rate limiting AI calls in production
- Monitor OpenAI costs in their dashboard
- Test thoroughly before enabling for all users
