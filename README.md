# Axis - Your Life Operating System

<div align="center">

![Axis Logo](assets/images/logo.png)

**A production-ready, multi-platform life management application**

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange.svg)](https://firebase.google.com)
[![Python](https://img.shields.io/badge/Python-3.11+-green.svg)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[Features](#features) • [Architecture](#architecture) • [Setup](#setup) • [Documentation](#documentation) • [Contributing](#contributing)

</div>

---

## Overview

**Axis** is a comprehensive life operating system that helps you manage your daily activities, build lasting habits, and maintain balance across all areas of life. Built with Flutter for seamless multi-platform support (iOS, iPadOS, macOS) and powered by AI recommendations.

### 🎯 Core Philosophy

Life is multidimensional. Axis organizes your habits into 6 fundamental life domains:

1. **Health** 💚 - Physical, mental, emotional, and spiritual well-being
2. **Wealth** 💰 - Financial stability and mindset
3. **Relationships** 💖 - Connections with self and others
4. **Career** 💼 - Purpose and professional growth
5. **Growth** 🌱 - Learning, hobbies, and self-improvement
6. **Spirituality** ✨ - Meaning, impact, and higher purpose

## Features

### 📱 Multi-Platform Support
- **iPhone**: Optimized mobile experience with bottom navigation
- **iPad**: Tablet layout with side navigation and multi-column views
- **MacBook**: Desktop-class app with native macOS integration

### 🏠 Home Dashboard
- Active habit streaks with visual indicators
- Today's task preview
- Mini calendar with event markers
- AI-powered daily recommendations
- Domain balance overview

### 📅 Calendar
- Monthly and weekly views
- Task and habit scheduling
- Event creation and management
- Day detail view with all activities

### ✅ Task Management
- Create, edit, and complete tasks
- Filter by status (Today, Upcoming, Completed)
- Priority levels (Low, Medium, High)
- Domain categorization
- Due date tracking

### 🔄 Habit Tracking
- Organize habits by 6 life domains
- Daily, weekly, or custom frequency
- Streak tracking and visualization
- Quick check-in from home screen
- Progress analytics

### 📔 Daily Reflection
- Guided journaling prompts
- Mood and energy tracking (1-10 scale)
- Gratitude, wins, and challenges
- Tag system for easy retrieval
- Timeline view of past reflections

### 🤖 AI Recommendations
- Analyzes 14 days of behavior patterns
- Identifies neglected life domains
- Prioritizes habits (Critical, High, Medium)
- Suggests optimal task limits
- Provides actionable insights

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Application                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         Presentation (Screens & Widgets)              │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │     Business Logic (Providers - State Management)     │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │        Data Layer (Models & Repositories)             │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │      Cloud Firestore (Database)      │
        └──────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │   Python AI Backend (FastAPI)        │
        │   - Recommendation Engine             │
        │   - Pattern Analysis                  │
        │   - Domain Balancing                  │
        └──────────────────────────────────────┘
```

### Tech Stack

**Frontend:**
- Flutter 3.16+ (Dart)
- Provider for state management
- Go Router for navigation
- Firebase SDK (Auth, Firestore)

**Backend:**
- Python 3.11+ with FastAPI
- Google Cloud Firestore
- Pydantic for data validation

**Infrastructure:**
- Firebase Authentication
- Cloud Firestore (NoSQL database)
- Cloud Run (Backend hosting)
- Firebase Analytics

## Quick Start

### Prerequisites
- Flutter SDK 3.16+
- Xcode 15+ (for iOS/macOS)
- Python 3.11+
- Firebase account

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/axis.git
cd axis
```

### 2. Set Up Firebase

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed Firebase configuration.

### 3. Install Dependencies

**Flutter:**
```bash
cd axis
flutter pub get
```

**Python Backend:**
```bash
cd ai_backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 4. Configure

- Add `GoogleService-Info.plist` to iOS and macOS projects
- Update `firebase_options.dart` with your Firebase config
- Set Firestore credentials for backend

### 5. Run

**Start Backend:**
```bash
cd ai_backend
uvicorn main:app --reload
```

**Run Flutter App:**
```bash
cd axis
flutter run -d macos  # or ios
```

## Project Structure

```
axis/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # App widget
│   ├── core/
│   │   ├── constants/               # Enums, colors, constants
│   │   ├── theme/                   # Light/dark themes
│   │   ├── router/                  # Navigation
│   │   └── utils/                   # Helper functions
│   ├── models/                      # Data models
│   │   ├── user.dart
│   │   ├── habit.dart
│   │   ├── task.dart
│   │   ├── reflection.dart
│   │   └── recommendation.dart
│   ├── repositories/                # Data access layer
│   │   ├── habit_repository.dart
│   │   ├── task_repository.dart
│   │   └── reflection_repository.dart
│   ├── services/                    # External services
│   │   ├── ai_service.dart
│   │   └── firestore_service.dart
│   ├── providers/                   # State management
│   │   ├── auth_provider.dart
│   │   ├── habit_provider.dart
│   │   ├── task_provider.dart
│   │   ├── reflection_provider.dart
│   │   └── ai_provider.dart
│   ├── screens/                     # Main screens
│   │   ├── home/
│   │   ├── calendar/
│   │   ├── tasks/
│   │   ├── habits/
│   │   └── reflection/
│   └── widgets/                     # Reusable components
│       ├── navigation/
│       ├── cards/
│       └── forms/
│
├── ai_backend/
│   ├── main.py                      # FastAPI app
│   ├── models/                      # Pydantic models
│   ├── services/                    # Business logic
│   │   ├── recommendation_engine.py
│   │   ├── pattern_analyzer.py
│   │   ├── domain_balancer.py
│   │   └── firestore_client.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── README.md
│
├── test/                            # Tests
├── pubspec.yaml                     # Flutter dependencies
├── ARCHITECTURE.md                  # Architecture details
├── SETUP_GUIDE.md                   # Setup instructions
└── README.md                        # This file
```

## Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design and architecture decisions
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Detailed setup and configuration
- **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** - Code patterns and examples
- **[ai_backend/README.md](ai_backend/README.md)** - Backend API documentation

## Screenshots

<div align="center">

| Home Dashboard | Habits by Domain | Reflection |
|----------------|------------------|------------|
| ![Home](assets/screenshots/home.png) | ![Habits](assets/screenshots/habits.png) | ![Reflection](assets/screenshots/reflection.png) |

</div>

## Development

### Running Tests

```bash
# Flutter tests
cd axis
flutter test

# Python tests
cd ai_backend
pytest
```

### Code Style

**Flutter:**
```bash
flutter analyze
flutter format lib/
```

**Python:**
```bash
black .
flake8
```

### Building for Production

**iOS:**
```bash
flutter build ios --release
```

**macOS:**
```bash
flutter build macos --release
```

**Backend:**
```bash
docker build -t axis-ai-backend .
gcloud run deploy axis-ai-backend --image gcr.io/PROJECT_ID/axis-ai-backend
```

## Roadmap

### v1.0 (Current)
- ✅ Core habit tracking
- ✅ Task management
- ✅ Daily reflection
- ✅ AI recommendations (rule-based)
- ✅ Multi-platform support

### v1.1 (Planned)
- [ ] Social features (share progress)
- [ ] Apple Watch companion app
- [ ] Offline mode improvements
- [ ] Backup/export functionality
- [ ] Custom themes

### v2.0 (Future)
- [ ] ML-powered recommendations
- [ ] Collaborative habits (with friends)
- [ ] Integration with health apps (Apple Health, Google Fit)
- [ ] Advanced analytics and insights
- [ ] Habit templates and marketplace

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Areas We Need Help
- UI/UX improvements
- Additional AI recommendation algorithms
- Localization (i18n)
- Testing and QA
- Documentation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Backend powered by [FastAPI](https://fastapi.tiangolo.com)
- Database by [Firebase](https://firebase.google.com)
- Icons by [Font Awesome](https://fontawesome.com)

## Contact

- **GitHub Issues**: For bug reports and feature requests
- **Email**: support@axis-app.com
- **Twitter**: [@AxisApp](https://twitter.com/axisapp)

---

<div align="center">
  
**Made with ❤️ for anyone seeking balance in life**

[⬆ back to top](#axis---your-life-operating-system)

</div>
