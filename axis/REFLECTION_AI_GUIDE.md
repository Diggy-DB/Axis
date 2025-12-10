# Daily Reflection with AI Integration

This document explains the new AI-powered reflection system in Axis.

## Overview

The reflection system combines daily journaling with AI assistance to provide:
- **Actual schedule tracking**: Record what you actually did vs. what you planned
- **Completed tasks display**: See all tasks you completed that day
- **AI-generated prompts**: Get personalized reflection prompts for the next day
- **Daily AI summaries**: Receive motivational messages on the home page

## Features

### 1. Daily Reflection Page

Each day's reflection includes three main sections:

#### Completed Tasks
- Automatically pulls tasks marked as completed on that date
- Shows task titles with checkmarks
- Displays total count of completed tasks

#### Actual Schedule (Calendar Filler)
- Hourly timetable where you record what you actually did
- Similar to the calendar page but editable
- Shows activity name, start/end times, and duration
- Helps track productive hours vs. planned schedule

#### Reflection Writing
- Main reflection text field
- Optional fields:
  - **Mood** (1-10 scale)
  - **Energy** (1-10 scale)
  - **Gratitude**: What are you grateful for?
  - **Wins**: What went well today?
  - **Challenges**: What was difficult?

### 2. AI Integration

#### Personalized AI Agent
Each user has their own AI agent that:
- Learns from their profile (3 onboarding questions):
  1. **Core values** (answer1 in UserModel)
  2. **Worldview & purpose** (answer2 in UserModel)
  3. **Ambitions** (answer3 in UserModel)
- Analyzes reflection patterns over time
- Generates personalized prompts and feedback

#### AI Features

**Next Day Prompts (Midnight Generation)**
Every midnight, the AI:
1. Reviews the day's reflection
2. Identifies themes (motivation, challenges, wins)
3. Generates an encouraging prompt for tomorrow
4. Example: If user felt unmotivated → "What small step can you take today to reconnect with your goals?"

**Daily Summary for Home Page (Midnight Generation)**
Every midnight, the AI creates a summary message like:
```
You did great yesterday! You accomplished 6 tasks completely, 
and were productive for 4.5 hours. Your reflection showed 
that you're more active in your community. That's amazing 
improvement. Keep it up!
```

The summary includes:
- Task completion count
- Productive hours (calculated from actual schedule)
- Key insights from reflection text
- Patterns compared to previous days
- Motivational encouragement aligned with user's values

## Implementation

### Models

**Reflection Model** (`lib/models/reflection.dart`)
```dart
class Reflection {
  final String id;
  final DateTime date;
  final String text;
  final int? mood;
  final int? energy;
  final String? gratitude;
  final String? challenges;
  final String? wins;
  final List<String> completedTaskIds;
  final List<ActualScheduleEntry> actualSchedule;
  final String? aiPromptForNextDay;
  // ...
}

class ActualScheduleEntry {
  final String activity;
  final DateTime startTime;
  final DateTime endTime;
}
```

**Daily Summary Model** (`lib/models/daily_summary.dart`)
```dart
class DailySummary {
  final DateTime date;
  final String aiMessage;
  final int tasksCompleted;
  final double productiveHours;
  final String? keyInsight;
  // ...
}
```

### Services

**OpenAI Service** (`lib/services/openai_service.dart`)

Three main methods:

1. `generateNextDayPrompt()`: Creates personalized prompt for tomorrow
2. `generateDailySummary()`: Creates home page summary message
3. `extractKeyInsight()`: Pulls key patterns from reflection

Uses GPT-4o-mini for cost-effectiveness (~$0.15 per 1M input tokens).

### Configuration

**Setup OpenAI API Key:**

1. Get API key from https://platform.openai.com/api-keys
2. Update `.env` file:
```
OPENAI_API_KEY=sk-your-actual-key-here
```

3. The app loads this in `main.dart`:
```dart
await AppConfig.load();
```

### Firestore Structure

```
users/{userId}/
  ├── reflections/{reflectionId}
  │   ├── date: Timestamp
  │   ├── text: String
  │   ├── mood: int?
  │   ├── energy: int?
  │   ├── gratitude: String?
  │   ├── challenges: String?
  │   ├── wins: String?
  │   ├── completedTaskIds: Array<String>
  │   ├── actualSchedule: Array<Map>
  │   ├── aiPromptForNextDay: String?
  │   ├── createdAt: Timestamp
  │   └── updatedAt: Timestamp
  │
  └── dailySummaries/{summaryId}
      ├── date: Timestamp
      ├── aiMessage: String
      ├── tasksCompleted: int
      ├── productiveHours: double
      ├── keyInsight: String?
      └── createdAt: Timestamp
```

### Midnight Job (Cloud Function)

A Firebase Cloud Function should run at midnight to:

```javascript
exports.generateDailyAI = functions.pubsub
  .schedule('0 0 * * *') // Every midnight
  .timeZone('UTC')
  .onRun(async (context) => {
    // For each user:
    // 1. Get today's reflection
    // 2. Get completed tasks
    // 3. Calculate productive hours from actualSchedule
    // 4. Call OpenAI service to generate:
    //    - aiPromptForNextDay (save to reflection)
    //    - dailySummary message (save to dailySummaries collection)
  });
```

## UI Screens

### Reflection Screen
- Date selector with prev/next navigation
- Three expandable sections
- Edit buttons for schedule and reflection text
- Displays AI prompt in highlighted box

### Home Page Integration
- New "Daily Insight" card at top
- Shows AI-generated summary
- Displays key metrics (tasks, hours)
- Motivational message

## Security & Privacy

- **API Keys**: Never commit .env file (in .gitignore)
- **User Data**: Reflections are private per user
- **OpenAI**: Only sends reflection text + user profile, no PII
- **Rate Limiting**: Consider implementing to prevent API overuse

## Cost Estimation

**OpenAI API Costs (GPT-4o-mini)**:
- Input: $0.15 per 1M tokens (~$0.0001 per reflection)
- Output: $0.60 per 1M tokens (~$0.0001 per response)
- **Per user per day**: ~$0.0003 (3 API calls)
- **1000 active users**: ~$9/month

## Future Enhancements

1. **Voice Reflections**: Speech-to-text integration
2. **Reflection Themes**: AI categorizes entries by themes
3. **Progress Tracking**: AI identifies long-term patterns
4. **Weekly/Monthly Reports**: Comprehensive AI analysis
5. **Mood Visualization**: Charts showing mood/energy trends
6. **Reflection Reminders**: Push notifications at optimal times

## Testing

To test AI features:
1. Create a test reflection with mood and text
2. Manually trigger midnight function or wait
3. Check for:
   - `aiPromptForNextDay` in reflection doc
   - New document in `dailySummaries` collection
   - Summary displayed on home page next day

## Troubleshooting

**"OPENAI_API_KEY not configured" error**
- Check `.env` file exists in project root
- Verify API key is set correctly
- Restart app after changing .env

**AI responses seem generic**
- Ensure user profile (3 questions) is filled
- Check if previous reflections exist
- Verify OpenAI API key has proper permissions

**Firestore security rules**
- Ensure reflections collection has read/write for user
- Daily summaries should be readable by user

## Resources

- OpenAI API Docs: https://platform.openai.com/docs
- GPT-4o-mini: https://platform.openai.com/docs/models/gpt-4o-mini
- Firebase Functions: https://firebase.google.com/docs/functions
- Cloud Scheduler: https://firebase.google.com/docs/functions/schedule-functions
