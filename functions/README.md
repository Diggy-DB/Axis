# Firebase Cloud Functions Setup

This directory contains Firebase Cloud Functions for the Axis productivity app.

## Functions

### generateDailyInsights (Scheduled)
Runs every day at midnight (UTC) to:
- Process all users' reflections from yesterday
- Generate AI-powered insights using OpenAI GPT-4o-mini
- Create daily summaries with personalized messages
- Update reflections with next-day prompts

### generateInsightsForUser (Callable)
Manual HTTP callable function for testing:
- Allows users to trigger insight generation on demand
- Useful for testing without waiting for scheduled run

## Setup

1. **Install dependencies:**
   ```bash
   cd functions
   npm install
   ```

2. **Set OpenAI API Key:**
   ```bash
   firebase functions:config:set openai.key="your-api-key-here"
   ```

3. **Deploy functions:**
   ```bash
   firebase deploy --only functions
   ```

## Testing Locally

Run functions locally with emulator:
```bash
firebase emulators:start --only functions
```

## Cost Estimation

- GPT-4o-mini: ~$0.15 per 1M input tokens, ~$0.60 per 1M output tokens
- Per user per day: ~$0.0003
- 1000 active users/day: ~$9/month

## Environment Variables

The function reads the OpenAI API key from Firebase config:
```bash
# View current config
firebase functions:config:get

# Set config
firebase functions:config:set openai.key="sk-..."
```

## Monitoring

View logs:
```bash
firebase functions:log
```

View specific function logs:
```bash
firebase functions:log --only generateDailyInsights
```
