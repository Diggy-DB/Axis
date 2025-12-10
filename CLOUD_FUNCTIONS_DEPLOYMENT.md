# Firebase Cloud Functions Deployment Guide

## Prerequisites

✅ Firebase project initialized
✅ OpenAI API key available
✅ Node.js 18+ installed (you have v20)
✅ Firebase CLI installed

## Step 1: Configure OpenAI API Key

Set your OpenAI API key for the Cloud Functions:

```bash
cd /Users/diggy/Productive
firebase functions:config:set openai.key="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"
```

Verify the config:
```bash
firebase functions:config:get
```

## Step 2: Deploy Functions

Deploy the functions to Firebase:

```bash
cd /Users/diggy/Productive
firebase deploy --only functions
```

This will deploy:
- `generateDailyInsights` - Scheduled function (runs at midnight UTC)
- `generateInsightsForUser` - HTTP callable function (for manual testing)

## Step 3: Test the Function

### Option A: Wait for scheduled run
The function will automatically run at midnight UTC.

### Option B: Manual test (recommended)
Call the function manually from your Flutter app:

```dart
import 'package:cloud_functions/cloud_functions.dart';

// Add to your reflection screen or test button
Future<void> testGenerateInsights() async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('generateInsightsForUser');
    final result = await callable.call();
    print('Success: ${result.data}');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Option C: Test with Firebase CLI
```bash
firebase functions:shell
# Then call: generateInsightsForUser({})
```

## Step 4: Monitor Logs

View function logs:
```bash
firebase functions:log
```

Or view in Firebase Console:
https://console.firebase.google.com/project/axis-90942/functions

## Cost Management

**Expected costs:**
- GPT-4o-mini: ~$0.0003 per user per day
- 100 users: ~$0.90/month
- 1000 users: ~$9/month

**Monitor usage in:**
- OpenAI Dashboard: https://platform.openai.com/usage
- Firebase Console: Functions usage metrics

## Troubleshooting

### "Permission denied" error
Make sure Firestore rules allow Cloud Functions to write dailySummaries:
```javascript
match /dailySummaries/{summaryId} {
  allow read: if isOwner(userId);
  allow write: if false; // Cloud Function writes via Admin SDK
}
```

### Function timeout
Default timeout is 60s. Increase if needed:
```javascript
exports.generateDailyInsights = functions
  .runWith({ timeoutSeconds: 300 }) // 5 minutes
  .pubsub.schedule('0 0 * * *')
  ...
```

### OpenAI rate limits
Free tier: 200 requests/day, 40k tokens/minute
If you hit limits, consider:
- Upgrading OpenAI plan
- Batching requests
- Adding retry logic

## Schedule Customization

Change the schedule (currently midnight UTC):

```javascript
// Run at 6 AM EST (11:00 UTC)
.schedule('0 11 * * *')

// Run at user's local midnight (requires time zone handling)
// You'd need to store user time zones and schedule per-user
```

## Next Steps

1. ✅ Set OpenAI API key config
2. ✅ Deploy functions
3. ✅ Test with manual call
4. ✅ Verify daily summaries appear on home page
5. ✅ Monitor costs and logs

## Additional Features to Consider

- **Error notifications**: Send admin email on function failures
- **Usage analytics**: Track which users use reflections
- **Rate limiting**: Prevent abuse of manual trigger
- **Batch processing**: Process users in batches to avoid timeouts
- **Retry logic**: Retry failed API calls with exponential backoff
