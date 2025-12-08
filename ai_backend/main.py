from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Optional
from datetime import datetime, timedelta
import logging

from services.recommendation_engine import RecommendationEngine
from services.firestore_client import FirestoreClient
from models.recommendation import RecommendationRequest, RecommendationResponse

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Axis AI Backend",
    description="AI recommendation engine for the Axis life operating system",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
firestore_client = FirestoreClient()
recommendation_engine = RecommendationEngine(firestore_client)


@app.get("/")
async def root():
    return {
        "name": "Axis AI Backend",
        "version": "1.0.0",
        "status": "running"
    }


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.post("/api/v1/recommendations/next-day", response_model=RecommendationResponse)
async def get_next_day_recommendation(request: RecommendationRequest):
    """
    Generate AI-powered recommendation for the next day based on user's history.
    
    Args:
        request: Contains userId, targetDate, and lookbackDays
        
    Returns:
        Recommendation with suggested habits, task limits, and insights
    """
    try:
        logger.info(f"Generating recommendation for user {request.userId}")
        
        # Generate recommendation
        recommendation = await recommendation_engine.generate_recommendation(
            user_id=request.userId,
            target_date=request.targetDate,
            lookback_days=request.lookbackDays
        )
        
        logger.info(f"Successfully generated recommendation for user {request.userId}")
        return recommendation
        
    except Exception as e:
        logger.error(f"Error generating recommendation: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/insights/domain/{domain_name}")
async def get_domain_insights(domain_name: str, userId: str):
    """
    Get AI insights for a specific life domain.
    
    Args:
        domain_name: Name of the domain (health, wealth, etc.)
        userId: User ID
        
    Returns:
        List of insights for the domain
    """
    try:
        insights = await recommendation_engine.get_domain_insights(
            user_id=userId,
            domain=domain_name
        )
        
        return {"insights": insights}
        
    except Exception as e:
        logger.error(f"Error getting domain insights: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/data/submit")
async def submit_user_data(data: dict):
    """
    Submit user data for analysis and model training (optional).
    
    This endpoint can be used to collect anonymized data for improving
    the recommendation engine with machine learning.
    """
    try:
        logger.info(f"Received data submission from user {data.get('userId')}")
        # Process and store data for training
        # This is optional and can be implemented later
        return {"status": "success", "message": "Data received"}
        
    except Exception as e:
        logger.error(f"Error processing data submission: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
