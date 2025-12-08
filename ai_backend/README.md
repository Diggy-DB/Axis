# Axis AI Backend

AI recommendation engine for the Axis life operating system.

## Features

- Rule-based recommendation engine (v1)
- Analyzes habit completion patterns
- Calculates life domain balance
- Provides personalized daily recommendations
- RESTful API built with FastAPI
- Firestore integration for data access

## Setup

### Prerequisites

- Python 3.11+
- Google Cloud Firestore credentials
- pip

### Installation

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Configuration

1. Set up Google Cloud Firestore credentials:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
   ```

2. (Optional) Configure environment variables:
   ```bash
   export PORT=8000
   export LOG_LEVEL=INFO
   ```

### Running Locally

```bash
# Development server with auto-reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Production server
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

The API will be available at `http://localhost:8000`

API documentation (Swagger UI): `http://localhost:8000/docs`

## API Endpoints

### `GET /`
Health check and service info.

### `POST /api/v1/recommendations/next-day`
Generate recommendation for the next day.

**Request body:**
```json
{
  "userId": "user123",
  "targetDate": "2025-12-05T00:00:00Z",
  "lookbackDays": 14
}
```

**Response:**
```json
{
  "dateFor": "2025-12-05T00:00:00Z",
  "generatedAt": "2025-12-04T20:00:00Z",
  "recommendedHabits": [
    {
      "habitId": "habit123",
      "habitName": "Morning Meditation",
      "priority": "high",
      "reason": "6-day streak, keep momentum"
    }
  ],
  "suggestedTaskLimit": 4,
  "domainBalance": {
    "health": 0.75,
    "wealth": 0.60,
    ...
  },
  "insights": [
    "Your health domain is thriving!",
    "Relationships need more attention"
  ],
  "focusArea": "relationships",
  "confidence": 0.85
}
```

### `GET /api/v1/insights/domain/{domain_name}`
Get insights for a specific domain.

**Parameters:**
- `domain_name`: health, wealth, relationships, career, growth, spirituality
- `userId`: User ID (query parameter)

## Architecture

```
ai_backend/
├── main.py                    # FastAPI application
├── models/
│   └── recommendation.py      # Pydantic models
├── services/
│   ├── firestore_client.py    # Firestore data access
│   ├── recommendation_engine.py  # Core recommendation logic
│   ├── pattern_analyzer.py    # Behavior pattern analysis
│   └── domain_balancer.py     # Life domain scoring
├── requirements.txt
├── Dockerfile
└── README.md
```

## Recommendation Algorithm

The current version (v1) uses a rule-based approach:

1. **Pattern Analysis**
   - Habit completion rates
   - Streak calculations
   - Task completion patterns

2. **Domain Scoring**
   - Completion rate per domain (70% weight)
   - Habit diversity within domain (30% weight)
   - Recent activity boost

3. **Habit Prioritization**
   - **Critical**: Neglected domain + low completion rate
   - **High**: Active streaks or neglected domain
   - **Medium**: Moderate activity

4. **Task Limit Calculation**
   - Based on historical completion rate
   - Adjusted for ambition vs. realism

5. **Insight Generation**
   - Domain balance analysis
   - Task completion patterns
   - Reflection sentiment (if available)

## Future Enhancements

### Machine Learning Integration

The system is designed to support ML models:

```python
# Replace rule-based engine with ML model
class MLRecommendationEngine(RecommendationEngine):
    def __init__(self):
        self.model = load_trained_model()
    
    def generate_recommendation(self, user_data):
        features = self.extract_features(user_data)
        prediction = self.model.predict(features)
        return self.format_recommendation(prediction)
```

### Potential ML Features

- LSTM for time-series pattern prediction
- Collaborative filtering for habit suggestions
- NLP for reflection sentiment analysis
- Reinforcement learning for optimal scheduling

### C++ Integration

For performance-critical operations:

```python
import ctypes

# Load C++ library
ml_lib = ctypes.CDLL('./ml_core.so')

# Call C++ function
result = ml_lib.predict_next_habits(user_features)
```

## Deployment

### Docker

```bash
# Build image
docker build -t axis-ai-backend .

# Run container
docker run -p 8000:8000 \
  -e GOOGLE_APPLICATION_CREDENTIALS=/app/credentials.json \
  -v /path/to/credentials.json:/app/credentials.json \
  axis-ai-backend
```

### Cloud Run (Google Cloud)

```bash
# Build and push to Container Registry
gcloud builds submit --tag gcr.io/PROJECT_ID/axis-ai-backend

# Deploy to Cloud Run
gcloud run deploy axis-ai-backend \
  --image gcr.io/PROJECT_ID/axis-ai-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

### Environment Variables

- `GOOGLE_APPLICATION_CREDENTIALS`: Path to Firestore credentials
- `PORT`: Server port (default: 8000)
- `LOG_LEVEL`: Logging level (default: INFO)

## Testing

```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest tests/

# With coverage
pytest --cov=. tests/
```

## Monitoring

- Use Cloud Logging for production logs
- Set up Cloud Monitoring alerts for:
  - API response times
  - Error rates
  - Recommendation generation failures

## License

MIT License - see LICENSE file for details
