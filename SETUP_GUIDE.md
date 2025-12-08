# Axis - Setup Guide

Complete setup instructions for the Axis life operating system.

## Prerequisites

### Flutter Development
- **Flutter SDK**: 3.16.0 or higher
  ```bash
  flutter --version
  ```
- **Xcode**: 15.0+ (for iOS/macOS development)
- **CocoaPods**: Latest version
  ```bash
  sudo gem install cocoapods
  ```

### Backend Development
- **Python**: 3.11+
- **Google Cloud Account**: For Firestore
- **Firebase Project**: Set up at https://console.firebase.google.com

## Part 1: Firebase Setup

### 1. Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click "Add project"
3. Name your project (e.g., "axis-app")
4. Enable Google Analytics (optional)
5. Create project

### 2. Enable Firestore

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location (closest to your users)
5. Click "Enable"

### 3. Set Up Firestore Security Rules

In Firestore → Rules tab, paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

Click "Publish"

### 4. Enable Authentication

1. Go to "Authentication" → "Sign-in method"
2. Enable "Email/Password"
3. (Optional) Enable "Google" sign-in
4. Save

### 5. Add iOS App

1. In Project Settings, click "Add app" → iOS
2. iOS bundle ID: `com.example.axis` (or your own)
3. Download `GoogleService-Info.plist`
4. Save for later

### 6. Add macOS App

1. Click "Add app" → "Apple" (macOS)
2. macOS bundle ID: `com.example.axis`
3. Download `GoogleService-Info.plist` (separate from iOS)
4. Save for later

### 7. Get Service Account Key (for Backend)

1. Go to Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download JSON file
4. Save as `service-account-key.json`
5. **Keep this file secure** (never commit to git)

## Part 2: Flutter App Setup

### 1. Create Flutter Project Structure

```bash
cd /Users/diggy/Productive
cd axis
```

The structure is already created. Now configure Firebase.

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase for iOS

```bash
# Copy GoogleService-Info.plist to iOS project
cp /path/to/GoogleService-Info.plist ios/Runner/

# Open Xcode
open ios/Runner.xcworkspace
```

In Xcode:
1. Right-click Runner → Add Files to "Runner"
2. Select `GoogleService-Info.plist`
3. Ensure "Copy items if needed" is checked
4. Click Add

### 4. Configure Firebase for macOS

```bash
# Copy GoogleService-Info.plist to macOS project
cp /path/to/GoogleService-Info.plist macos/Runner/

# Open Xcode
open macos/Runner.xcworkspace
```

In Xcode:
1. Right-click Runner → Add Files to "Runner"
2. Select `GoogleService-Info.plist`
3. Click Add

### 5. Update Firebase Options

Edit `lib/firebase_options.dart` and replace placeholders with your actual values from Firebase Console → Project Settings:

```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',
  appId: 'YOUR_IOS_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_STORAGE_BUCKET',
  iosBundleId: 'com.example.axis',
);

static const FirebaseOptions macos = FirebaseOptions(
  apiKey: 'YOUR_MACOS_API_KEY',
  appId: 'YOUR_MACOS_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_STORAGE_BUCKET',
  iosBundleId: 'com.example.axis',
);
```

### 6. Update AI Backend URL

Edit `lib/core/constants/app_constants.dart`:

```dart
static const String aiBackendUrl = 'http://localhost:8000'; // For local testing
// static const String aiBackendUrl = 'https://your-backend.run.app'; // For production
```

### 7. Run the App

```bash
# List available devices
flutter devices

# Run on iOS simulator
flutter run -d "iPhone 15 Pro"

# Run on macOS
flutter run -d macos

# Run on physical device
flutter run -d <device-id>
```

## Part 3: Python AI Backend Setup

### 1. Create Virtual Environment

```bash
cd /Users/diggy/Productive/ai_backend

python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure Firestore Credentials

```bash
# Copy service account key
cp /path/to/service-account-key.json ./service-account-key.json

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/service-account-key.json"

# Add to ~/.zshrc or ~/.bashrc for persistence
echo 'export GOOGLE_APPLICATION_CREDENTIALS="/Users/diggy/Productive/ai_backend/service-account-key.json"' >> ~/.zshrc
```

### 4. Run the Backend

```bash
# Development server with auto-reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at:
- **API**: http://localhost:8000
- **Docs**: http://localhost:8000/docs

### 5. Test the API

```bash
curl http://localhost:8000/

# Test recommendation endpoint
curl -X POST http://localhost:8000/api/v1/recommendations/next-day \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user-123",
    "targetDate": "2025-12-05T00:00:00Z",
    "lookbackDays": 14
  }'
```

## Part 4: Development Workflow

### Running Everything Locally

**Terminal 1 - Backend:**
```bash
cd ai_backend
source venv/bin/activate
uvicorn main:app --reload
```

**Terminal 2 - Flutter:**
```bash
cd axis
flutter run -d macos  # or ios
```

### Hot Reload

- **Flutter**: Save any Dart file, changes auto-reload
- **Python**: Auto-reloads with `--reload` flag

### Debugging

**Flutter:**
```bash
# Run in debug mode
flutter run --debug

# Enable verbose logging
flutter run --verbose
```

**Python:**
```bash
# Set log level
export LOG_LEVEL=DEBUG
uvicorn main:app --reload --log-level debug
```

## Part 5: Production Deployment

### Deploy Backend to Cloud Run

```bash
cd ai_backend

# Set project ID
export PROJECT_ID="your-project-id"

# Build and push Docker image
gcloud builds submit --tag gcr.io/$PROJECT_ID/axis-ai-backend

# Deploy to Cloud Run
gcloud run deploy axis-ai-backend \
  --image gcr.io/$PROJECT_ID/axis-ai-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars GOOGLE_APPLICATION_CREDENTIALS=/app/service-account-key.json

# Get the deployed URL
gcloud run services describe axis-ai-backend --region us-central1 --format 'value(status.url)'
```

### Update Flutter App with Production URL

Edit `lib/core/constants/app_constants.dart`:

```dart
static const String aiBackendUrl = 'https://axis-ai-backend-xxxxx.run.app';
```

### Build Flutter for Release

**iOS:**
```bash
# Build for App Store
flutter build ios --release

# Open in Xcode for archiving
open ios/Runner.xcworkspace
```

In Xcode:
1. Select "Any iOS Device" as target
2. Product → Archive
3. Follow App Store Connect upload process

**macOS:**
```bash
# Build for Mac App Store
flutter build macos --release

# Open in Xcode
open build/macos/Build/Products/Release/axis.app
```

## Part 6: Troubleshooting

### Common Issues

**Issue: Firebase not initializing**
```
Solution: Ensure GoogleService-Info.plist is properly added to Xcode project
- Check Build Phases → Copy Bundle Resources
- Verify file is included
```

**Issue: Firestore permission denied**
```
Solution: Check security rules and ensure user is authenticated
- Go to Firestore Console → Rules
- Verify rules allow authenticated users
```

**Issue: Backend can't connect to Firestore**
```
Solution: Check credentials
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

**Issue: Hot reload not working**
```
Solution: 
flutter clean
flutter pub get
flutter run
```

### Logs and Debugging

**View Flutter logs:**
```bash
flutter logs
```

**View Firestore data:**
- Go to Firebase Console → Firestore Database
- Browse collections and documents

**View backend logs:**
```bash
# Local
tail -f /var/log/axis-backend.log

# Cloud Run
gcloud run logs read axis-ai-backend --limit 100
```

## Part 7: Data Seeding (Optional)

To test with sample data, create a script:

```dart
// lib/dev/seed_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedData(String userId) async {
  final firestore = FirebaseFirestore.instance;
  
  // Create sample habits
  await firestore.collection('users').doc(userId).collection('habits').add({
    'name': 'Morning Meditation',
    'description': '10 minutes of mindfulness',
    'domain': 'health',
    'frequency': 'daily',
    'targetPerPeriod': 1,
    'icon': '🧘',
    'color': '#10B981',
    'archived': false,
    'createdAt': Timestamp.now(),
    'updatedAt': Timestamp.now(),
  });
  
  // Add more sample data...
  
  print('Data seeded successfully');
}
```

Run from your app or create a standalone script.

## Next Steps

1. ✅ Complete all widget implementations (see IMPLEMENTATION_GUIDE.md)
2. ✅ Test all features end-to-end
3. ✅ Add error handling and validation
4. ✅ Implement offline support
5. ✅ Add unit and widget tests
6. ✅ Set up CI/CD pipeline
7. ✅ Submit to App Store / Mac App Store

## Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)

## Support

For issues and questions:
- Check ARCHITECTURE.md for design decisions
- Check IMPLEMENTATION_GUIDE.md for code patterns
- Review logs for error messages
- Consult Firebase/Flutter documentation
