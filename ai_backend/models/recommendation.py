from pydantic import BaseModel, Field
from typing import List, Dict, Optional
from datetime import datetime
from enum import Enum


class LifeDomain(str, Enum):
    """Life domains for habit categorization"""
    HEALTH_AND_ENERGY = "healthAndEnergy"
    RELATIONSHIPS = "relationships"
    WORK_AND_CAREER = "workAndCareer"
    PERSONAL_GROWTH = "personalGrowth"
    RECREATION = "recreation"


class RecommendationPriority(str, Enum):
    """Priority levels for habit recommendations"""
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class RecommendedHabit(BaseModel):
    """A habit recommendation for a specific day"""
    habitId: str
    habitName: str
    priority: RecommendationPriority
    reason: str


class AIRecommendation(BaseModel):
    """AI-generated recommendation for a specific day"""
    id: str = ""
    dateFor: datetime
    generatedAt: datetime
    recommendedHabits: List[RecommendedHabit]
    suggestedTaskLimit: int = Field(default=4, ge=1, le=10)
    domainBalance: Dict[LifeDomain, float]
    insights: List[str]
    focusArea: Optional[LifeDomain] = None
    confidence: float = Field(default=0.5, ge=0.0, le=1.0)


class NextDayRecommendationRequest(BaseModel):
    """Request for next day recommendation"""
    userId: str
    targetDate: datetime
    lookbackDays: int = 7
