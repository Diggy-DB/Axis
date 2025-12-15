from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
from typing import List, Dict, Optional
import os

from services.recommendation_engine import RecommendationEngine
from services.firestore_client import get_firestore_client
from models.recommendation import NextDayRecommendationRequest

# Initialize FastAPI app
app = FastAPI(
    title="Axis AI Backend",
    description="AI recommendation engine for Axis productivity app",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
firestore_client = get_firestore_client()
recommendation_engine = RecommendationEngine(firestore_client)


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "Axis AI Backend",
        "version": "1.0.0"
    }


@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "services": {
            "firestore": "connected",
            "recommendation_engine": "ready"
        }
    }


@app.post("/api/v1/recommendations/next-day")
async def get_next_day_recommendation(request: NextDayRecommendationRequest):
    """
    Generate AI recommendation for the next day
    
    Args:
        request: NextDayRecommendationRequest with userId, targetDate, and lookbackDays
    
    Returns:
        AIRecommendation with habit recommendations, insights, and domain balance
    """
    try:
        recommendation = await recommendation_engine.generate_next_day_recommendation(
            request
        )
        
        # Convert to dict for JSON response
        return {
            "dateFor": recommendation.dateFor.isoformat(),
            "generatedAt": recommendation.generatedAt.isoformat(),
            "recommendedHabits": [
                {
                    "habitId": h.habitId,
                    "habitName": h.habitName,
                    "priority": h.priority.value,
                    "reason": h.reason
                }
                for h in recommendation.recommendedHabits
            ],
            "suggestedTaskLimit": recommendation.suggestedTaskLimit,
            "domainBalance": {
                domain.value: score
                for domain, score in recommendation.domainBalance.items()
            },
            "insights": recommendation.insights,
            "focusArea": recommendation.focusArea.value if recommendation.focusArea else None,
            "confidence": recommendation.confidence
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate recommendation: {str(e)}"
        )


class DataSubmission(BaseModel):
    """Model for user data submission"""
    userId: str
    habits: List[Dict]
    habitLogs: List[Dict]
    tasks: List[Dict]
    reflections: List[Dict]


@app.post("/api/v1/data/submit")
async def submit_user_data(data: DataSubmission):
    """
    Submit user data for analysis (optional, for training)
    
    Args:
        data: User's habits, logs, tasks, and reflections
    
    Returns:
        Success confirmation
    """
    # This endpoint can be used for collecting training data
    # For now, just acknowledge receipt
    return {
        "status": "received",
        "userId": data.userId,
        "timestamp": datetime.now().isoformat()
    }


@app.get("/api/v1/insights/domain/{domain}")
async def get_domain_insights(domain: str, userId: str):
    """
    Get insights for a specific life domain
    
    Args:
        domain: Life domain name
        userId: User ID
    
    Returns:
        List of insights for the domain
    """
    # Placeholder for domain-specific insights
    # Can be enhanced with more sophisticated analysis
    return {
        "domain": domain,
        "insights": [
            f"Focus on consistency in your {domain} habits",
            "Small daily actions lead to big changes"
        ]
    }


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8080"))
    uvicorn.run(app, host="0.0.0.0", port=port)
