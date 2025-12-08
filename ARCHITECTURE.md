# Axis - Life Operating System Architecture

## Overview
Axis is a multi-platform life management application built with Flutter, supporting iOS, iPadOS, and macOS. It integrates daily planning, habit tracking across 6 life domains, task management, calendar scheduling, and AI-powered recommendations.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Application                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Presentation Layer                       │  │
│  │  - Responsive Navigation (Bottom/Side)                │  │
│  │  - 5 Main Pages (Home, Calendar, ToDo, Habit, Reflect)│ │
│  │  - Adaptive Widgets (iOS/macOS styling)              │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Business Logic Layer                     │  │
│  │  - Providers/BLoCs (State Management)                 │  │
│  │  - Services (Firestore, AI, Analytics)               │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Data Layer                               │  │
│  │  - Models (User, Habit, Task, Reflection)            │  │
│  │  - Repositories (Data abstraction)                    │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │      Cloud Firestore Database        │
        │  - users/{userId}                    │
        │  - habits, tasks, reflections, logs  │
        └──────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │   Python AI Backend (FastAPI)        │
        │  - Recommendation Engine              │
        │  - Pattern Analysis                   │
        │  - Domain Balancing Logic             │
        │  Optional: C++ Core for ML            │
        └──────────────────────────────────────┘
```

## Technology Stack

### Frontend
- **Framework**: Flutter 3.x+
- **State Management**: Provider (simple, scalable, official recommendation)
- **Routing**: Go Router (for deep linking support)
- **Local Cache**: Shared Preferences + Hive (offline support)
- **Platform Integration**: Platform channels for native features

### Backend
- **Database**: Google Cloud Firestore
  - Real-time sync
  - Offline persistence
  - Automatic scaling
  
- **AI Service**: Python (FastAPI) + Optional C++
  - Deployed on Cloud Run or similar
  - RESTful API
  - JWT authentication

### Additional Services
- **Authentication**: Firebase Auth
- **Analytics**: Firebase Analytics
- **Notifications**: Firebase Cloud Messaging

## State Management Strategy

Using **Provider** pattern:

```dart
ChangeNotifier Providers:
- AuthProvider (user state, login/logout)
- HabitProvider (habits CRUD, streak calculation)
- TaskProvider (tasks CRUD, filtering)
- ReflectionProvider (daily entries)
- CalendarProvider (date selection, events)
- AIProvider (recommendations, loading states)
- ThemeProvider (light/dark mode)
```

Benefits:
- Simple to understand and maintain
- Official Flutter recommendation
- Good performance with selective rebuilds
- Easy testing

## Responsive Navigation Pattern

```dart
Widget build(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final useDrawer = width >= 600; // iPad/Mac threshold
  
  return useDrawer 
    ? _buildSideNavigation()
    : _buildBottomNavigation();
}
```

- **Mobile (< 600dp)**: BottomNavigationBar
- **Tablet/Desktop (≥ 600dp)**: NavigationRail

## Data Flow Example: Home Page Load

```
1. User opens app
   └─> AuthProvider.initialize()
       └─> Check Firebase Auth state
       
2. Navigate to Home page
   └─> HomeProvider.loadDashboard()
       ├─> TaskRepository.getTodayTasks() → Firestore query
       ├─> HabitRepository.getTodayHabits() → Firestore query
       ├─> HabitRepository.calculateStreaks() → Local computation
       └─> AIService.getTodayRecommendation() → HTTP call to Python backend
           └─> Backend analyzes:
               - Last 7 days habit completion
               - Task completion rates
               - Domain balance
               - Reflection sentiment
           └─> Returns: priority habits, task limit, focus areas
       
3. UI rebuilds with data
   └─> StreamBuilders listen to Firestore changes (real-time updates)
```

## Firestore Schema Design

### Collection Structure

```
users/{userId}
├── profile/
│   ├── displayName: string
│   ├── email: string
│   ├── photoURL: string
│   ├── createdAt: timestamp
│   ├── timezone: string
│   └── preferences: map
│       ├── theme: "light" | "dark"
│       ├── firstDayOfWeek: int
│       └── notificationsEnabled: bool
│
├── habits/{habitId}
│   ├── name: string
│   ├── description: string
│   ├── domain: "health" | "wealth" | "relationships" | "career" | "growth" | "spirituality"
│   ├── frequency: "daily" | "weekly" | "custom"
│   ├── targetPerPeriod: int (e.g., 3 for 3x/week)
│   ├── timeOfDay: string? ("morning" | "afternoon" | "evening")
│   ├── reminderEnabled: bool
│   ├── reminderTime: timestamp?
│   ├── color: string (hex)
│   ├── icon: string (emoji or icon name)
│   ├── archived: bool
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp
│
├── habit_logs/{logId}
│   ├── habitId: reference
│   ├── date: timestamp (normalized to start of day)
│   ├── status: "completed" | "skipped" | "partial"
│   ├── notes: string?
│   ├── completedAt: timestamp?
│   └── createdAt: timestamp
│   [Indexed on: habitId + date]
│
├── tasks/{taskId}
│   ├── title: string
│   ├── description: string?
│   ├── dueDate: timestamp? (null = no date)
│   ├── scheduledDate: timestamp? (null = someday)
│   ├── status: "pending" | "in_progress" | "completed"
│   ├── priority: "low" | "medium" | "high"
│   ├── domain: string? (one of 6 domains)
│   ├── linkedHabitId: reference?
│   ├── estimatedMinutes: int?
│   ├── completedAt: timestamp?
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp
│   [Indexed on: status + scheduledDate]
│
├── reflections/{reflectionId}
│   ├── date: timestamp (normalized to start of day)
│   ├── text: string
│   ├── mood: int? (1-10 scale)
│   ├── energy: int? (1-10 scale)
│   ├── gratitude: string?
│   ├── challenges: string?
│   ├── wins: string?
│   ├── tags: array<string>
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp
│   [Indexed on: date DESC]
│
└── ai_recommendations/{recId}
    ├── dateFor: timestamp (the date this recommendation is for)
    ├── generatedAt: timestamp
    ├── recommendedHabits: array<map>
    │   ├── habitId: reference
    │   ├── priority: "critical" | "high" | "medium"
    │   └── reason: string
    ├── suggestedTaskLimit: int
    ├── domainBalance: map<domain, score>
    ├── insights: array<string>
    ├── focusArea: string (domain name)
    └── confidence: float (0-1)
```

### Schema Design Decisions

1. **Denormalization**: habitId stored as reference for joins, but we cache habit names in logs for faster queries
2. **Date Normalization**: All dates stored as start-of-day UTC timestamps for consistent querying
3. **Composite Indexes**: 
   - `habit_logs`: (habitId, date) for streak calculation
   - `tasks`: (status, scheduledDate) for filtered views
   - `reflections`: (date DESC) for timeline view
4. **Subcollections**: Keep user data isolated per user for security rules
5. **AI Recommendations**: Stored to avoid recomputation and show history

### Firestore Security Rules

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

## AI Backend Architecture

### Python Service (FastAPI)

```
ai_backend/
├── main.py (FastAPI app)
├── models/
│   ├── recommendation.py (Pydantic models)
│   └── user_data.py
├── services/
│   ├── recommendation_engine.py (core logic)
│   ├── pattern_analyzer.py
│   └── domain_balancer.py
├── utils/
│   ├── firestore_client.py
│   └── date_helpers.py
├── requirements.txt
└── Dockerfile
```

### API Contract

**Endpoint**: `POST /api/v1/recommendations/next-day`

**Request**:
```json
{
  "userId": "string",
  "targetDate": "2025-12-05T00:00:00Z",
  "lookbackDays": 14
}
```

**Response**:
```json
{
  "dateFor": "2025-12-05T00:00:00Z",
  "generatedAt": "2025-12-04T20:00:00Z",
  "recommendedHabits": [
    {
      "habitId": "habit123",
      "habitName": "Morning Meditation",
      "priority": "high",
      "reason": "Completed 6/7 days this week, maintaining momentum"
    },
    {
      "habitId": "habit456",
      "habitName": "Exercise",
      "priority": "critical",
      "reason": "Not completed in 4 days, health domain needs attention"
    }
  ],
  "suggestedTaskLimit": 4,
  "domainBalance": {
    "health": 0.6,
    "wealth": 0.8,
    "relationships": 0.4,
    "career": 0.9,
    "growth": 0.5,
    "spirituality": 0.3
  },
  "insights": [
    "Your health domain score is good, but relationships need more focus",
    "You typically complete 3-4 tasks per day; let's aim for 4 tomorrow",
    "Spirituality has been neglected for 2 weeks"
  ],
  "focusArea": "relationships",
  "confidence": 0.85
}
```

### Recommendation Algorithm (Rule-Based v1)

```python
def generate_recommendation(user_data: UserData) -> Recommendation:
    """
    Rule-based recommendation engine that will be replaced with ML later.
    """
    
    # 1. Calculate completion rates per domain
    domain_scores = calculate_domain_scores(user_data.habit_logs)
    
    # 2. Identify neglected domains (score < 0.5)
    neglected = [d for d, score in domain_scores.items() if score < 0.5]
    
    # 3. Calculate habit streaks and priorities
    habit_priorities = []
    for habit in user_data.habits:
        streak = calculate_streak(habit.id, user_data.habit_logs)
        completion_rate = calculate_completion_rate(habit.id, 14)
        
        if streak >= 3 and completion_rate >= 0.7:
            # Maintain momentum
            habit_priorities.append((habit, "high", f"{streak} day streak"))
        elif habit.domain in neglected:
            # Critical for domain balance
            habit_priorities.append((habit, "critical", f"{habit.domain} needs attention"))
        elif streak == 0 and completion_rate < 0.3:
            # Re-engagement opportunity
            habit_priorities.append((habit, "medium", "Let's restart this"))
    
    # 4. Analyze task completion patterns
    avg_tasks = calculate_avg_daily_tasks(user_data.tasks)
    suggested_limit = int(avg_tasks * 1.2)  # Slightly ambitious
    
    # 5. Sentiment analysis of reflections (simple keyword matching for v1)
    recent_reflections = get_recent_reflections(7)
    sentiment_score = analyze_sentiment(recent_reflections)
    
    # 6. Generate insights
    insights = generate_insights(domain_scores, neglected, sentiment_score)
    
    return Recommendation(
        recommended_habits=habit_priorities[:6],  # Top 6
        suggested_task_limit=suggested_limit,
        domain_balance=domain_scores,
        insights=insights,
        focus_area=neglected[0] if neglected else max(domain_scores),
        confidence=calculate_confidence(user_data)
    )
```

### Future ML Enhancement

The system is designed to plug in ML models:
- Replace rule-based logic with TensorFlow/PyTorch models
- Train on user behavior patterns
- Use C++ backend for inference performance:
  ```python
  import ctypes
  ml_lib = ctypes.CDLL('./ml_core.so')
  prediction = ml_lib.predict(features)
  ```

## UX/Design Guidelines

### Color Palette (6 Domain Colors)

- **Health**: Green (#10B981) - vitality, growth
- **Wealth**: Gold (#F59E0B) - prosperity, value
- **Relationships**: Pink (#EC4899) - warmth, connection
- **Career**: Blue (#3B82F6) - professionalism, trust
- **Growth**: Purple (#8B5CF6) - creativity, expansion
- **Spirituality**: Indigo (#6366F1) - depth, transcendence

### Typography
- **Headers**: SF Pro Display (iOS/macOS native)
- **Body**: SF Pro Text
- **Monospace**: SF Mono (for numbers, streaks)

### Layout Principles

1. **Whitespace**: Generous padding (16-24dp) for breathing room
2. **Cards**: Elevated cards with subtle shadows for grouping
3. **Consistency**: Same components across platforms, adapt styling
4. **Feedback**: Micro-interactions (haptics on iOS, animations)
5. **Accessibility**: 
   - Min touch target 44x44
   - Color contrast ratio 4.5:1+
   - Screen reader support

### Platform Adaptations

#### iPhone
- Bottom navigation (5 items)
- Floating action buttons
- Pull-to-refresh
- Haptic feedback
- Safe area insets

#### iPad
- Side navigation (NavigationRail)
- Master-detail views where appropriate
- Multi-column layouts
- Drag and drop support

#### macOS
- Native menu bar integration
- Keyboard shortcuts
- Hover states
- Window management

## Performance Considerations

1. **Lazy Loading**: Paginate long lists (habits, reflections)
2. **Caching**: Cache Firestore queries with local persistence
3. **Optimistic Updates**: Update UI immediately, sync to Firestore async
4. **Image Optimization**: Use cached_network_image for profile pics
5. **Bundle Size**: Tree-shaking, code splitting by route

## Security

1. **Authentication**: Firebase Auth with email/password + social providers
2. **Authorization**: Firestore security rules (user can only access own data)
3. **API Security**: JWT tokens for AI backend
4. **Data Encryption**: Firestore encryption at rest (default)
5. **Input Validation**: Both client and server-side

## Testing Strategy

1. **Unit Tests**: Models, repositories, business logic
2. **Widget Tests**: Individual screen components
3. **Integration Tests**: End-to-end flows
4. **Golden Tests**: Visual regression testing
5. **Backend Tests**: pytest for Python AI service

## Deployment

### Flutter App
- **iOS**: TestFlight → App Store
- **macOS**: Notarization → Mac App Store or direct distribution
- **CI/CD**: GitHub Actions with Codemagic

### Backend
- **Python AI Service**: Docker → Cloud Run (auto-scaling)
- **Firestore**: Managed service, no deployment needed
- **Environment**: Dev → Staging → Production

## Project Structure

```
axis/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── router/
│   ├── models/
│   │   ├── user.dart
│   │   ├── habit.dart
│   │   ├── task.dart
│   │   ├── reflection.dart
│   │   └── recommendation.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── habit_repository.dart
│   │   ├── task_repository.dart
│   │   ├── reflection_repository.dart
│   │   └── ai_repository.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── habit_provider.dart
│   │   ├── task_provider.dart
│   │   ├── reflection_provider.dart
│   │   ├── calendar_provider.dart
│   │   └── theme_provider.dart
│   ├── services/
│   │   ├── firestore_service.dart
│   │   ├── ai_service.dart
│   │   └── analytics_service.dart
│   ├── screens/
│   │   ├── home/
│   │   ├── calendar/
│   │   ├── tasks/
│   │   ├── habits/
│   │   └── reflection/
│   └── widgets/
│       ├── navigation/
│       ├── cards/
│       ├── forms/
│       └── common/
├── ai_backend/
│   ├── main.py
│   ├── models/
│   ├── services/
│   └── utils/
└── test/
```

This architecture is designed for:
- **Scalability**: Can handle thousands of users with Firestore's auto-scaling
- **Maintainability**: Clean separation of concerns, modular code
- **Extensibility**: Easy to add new features, swap AI models
- **Performance**: Optimized queries, caching, lazy loading
- **User Experience**: Responsive, adaptive, delightful interactions
