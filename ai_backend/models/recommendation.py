from pydantic import BaseModel
from typing import List, Dict, Optional
from datetime import datetime
from enum import Enum


class LifeDomain(str, Enum):
    HEALTH = "health"
    WEALTH = "wealth"
    RELATIONSHIPS = "relationships"
    CAREER = "career"
    GROWTH = "growth"
    SPIRITUALITY = "spirituality"


class RecommendationPriority(str, Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"


class RecommendationRequest(BaseModel):
    userId: str
    targetDate: datetime
    lookbackDays: int = 14


class RecommendedHabit(BaseModel):
    habitId: str
    habitName: str
    priority: RecommendationPriority
    reason: str


class RecommendationResponse(BaseModel):
    dateFor: datetime
    generatedAt: datetime
    recommendedHabits: List[RecommendedHabit]
    suggestedTaskLimit: int
    domainBalance: Dict[str, float]
    insights: List[str]
    focusArea: Optional[str]
    confidence: float


class HabitLog(BaseModel):
    habitId: str
    date: datetime
    status: str  # completed, skipped, partial


class Task(BaseModel):
    id: str
    title: str
    status: str
    scheduledDate: Optional[datetime]
    completedAt: Optional[datetime]


class Reflection(BaseModel):
    id: str
    date: datetime
    text: str
    mood: Optional[int]
    energy: Optional[int]
