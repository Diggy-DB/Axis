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

2. **Store the OpenAI API key as a secret** (the functions read it from `OPENAI_API_KEY`):
   ```bash
   firebase functions:secrets:set OPENAI_API_KEY
   ```
   The CLI prompts for the key, so it never appears in your shell history or in this repo.

3. **Deploy functions:**
   ```bash
   firebase deploy --only functions
   ```

## Testing Locally

Run functions locally with emulator:
```bash
firebase emulators:start --only functions
```

## Environment Variables

Both functions declare `OPENAI_API_KEY` as a Secret Manager secret (`runWith({ secrets: ['OPENAI_API_KEY'] })`):
```bash
# Set or rotate the key (prompts for the value)
firebase functions:secrets:set OPENAI_API_KEY

# List its versions without printing the value
firebase functions:secrets:get OPENAI_API_KEY
```
For the local emulator, put `OPENAI_API_KEY=...` in `functions/.secret.local`, which is git-ignored.

## Monitoring

View logs:
```bash
firebase functions:log
```

View specific function logs:
```bash
firebase functions:log --only generateDailyInsights
```
