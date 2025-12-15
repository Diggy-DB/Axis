from datetime import datetime, timedelta
from typing import List, Dict
from models.recommendation import (
    AIRecommendation,
    RecommendedHabit,
    RecommendationPriority,
    LifeDomain,
    NextDayRecommendationRequest
)
from services.firestore_client import FirestoreClient
from services.pattern_analyzer import PatternAnalyzer
from services.domain_balancer import DomainBalancer


class RecommendationEngine:
    """AI recommendation engine for next-day habit suggestions"""
    
    def __init__(self, firestore_client: FirestoreClient):
        self.firestore = firestore_client
        self.pattern_analyzer = PatternAnalyzer()
        self.domain_balancer = DomainBalancer()
    
    async def generate_next_day_recommendation(
        self,
        request: NextDayRecommendationRequest
    ) -> AIRecommendation:
        """Generate AI recommendation for next day"""
        
        # Fetch user data
        habits = await self._fetch_user_habits(request.userId)
        habit_logs = await self._fetch_habit_logs(
            request.userId,
            request.lookbackDays
        )
        tasks = await self._fetch_recent_tasks(
            request.userId,
            request.lookbackDays
        )
        
        # Analyze patterns
        completion_rates = self.pattern_analyzer.analyze_habit_completion_patterns(
            habit_logs, habits, request.lookbackDays
        )
        struggling_domains = self.pattern_analyzer.identify_struggling_domains(
            habits, completion_rates
        )
        
        # Generate recommendations
        recommended_habits = self._select_recommended_habits(
            habits,
            completion_rates,
            struggling_domains
        )
        
        # Calculate domain balance
        recommended_habit_ids = [h.habitId for h in recommended_habits]
        domain_balance = self.domain_balancer.calculate_domain_balance(
            habits,
            recommended_habit_ids
        )
        
        # Suggest focus area
        focus_area = self.domain_balancer.suggest_focus_area(
            struggling_domains,
            domain_balance
        )
        
        # Generate insights
        insights = self._generate_insights(
            completion_rates,
            struggling_domains,
            len(tasks)
        )
        
        # Suggest task limit
        task_limit = self._suggest_task_limit(tasks)
        
        return AIRecommendation(
            dateFor=request.targetDate,
            generatedAt=datetime.now(),
            recommendedHabits=recommended_habits,
            suggestedTaskLimit=task_limit,
            domainBalance=domain_balance,
            insights=insights,
            focusArea=focus_area,
            confidence=0.7  # Can be improved with ML model
        )
    
    def _select_recommended_habits(
        self,
        habits: List[Dict],
        completion_rates: Dict[str, float],
        struggling_domains: List[LifeDomain]
    ) -> List[RecommendedHabit]:
        """Select which habits to recommend"""
        recommendations = []
        
        # Prioritize habits in struggling domains
        for habit in habits:
            habit_id = habit.get('id')
            if not habit_id:
                continue
            
            domain = habit.get('lifeDomain')
            completion_rate = completion_rates.get(habit_id, 0)
            
            # Determine priority
            priority = RecommendationPriority.MEDIUM
            reason = "Maintain your momentum"
            
            try:
                domain_enum = LifeDomain(domain) if domain else None
                if domain_enum in struggling_domains:
                    priority = RecommendationPriority.HIGH
                    reason = f"Focus on {domain_enum.value} - needs attention"
                elif completion_rate > 0.8:
                    priority = RecommendationPriority.HIGH
                    reason = "Great streak! Keep it going"
                elif completion_rate < 0.3:
                    priority = RecommendationPriority.LOW
                    reason = "Consider starting small"
            except (ValueError, AttributeError):
                pass
            
            recommendations.append(RecommendedHabit(
                habitId=habit_id,
                habitName=habit.get('name', 'Unnamed Habit'),
                priority=priority,
                reason=reason
            ))
        
        # Sort by priority
        priority_order = {
            RecommendationPriority.HIGH: 0,
            RecommendationPriority.MEDIUM: 1,
            RecommendationPriority.LOW: 2
        }
        recommendations.sort(key=lambda x: priority_order[x.priority])
        
        return recommendations
    
    def _generate_insights(
        self,
        completion_rates: Dict[str, float],
        struggling_domains: List[LifeDomain],
        task_count: int
    ) -> List[str]:
        """Generate insights for the user"""
        insights = []
        
        if struggling_domains:
            domain_names = ", ".join([d.value for d in struggling_domains])
            insights.append(f"Consider focusing on: {domain_names}")
        
        avg_completion = (
            sum(completion_rates.values()) / len(completion_rates)
            if completion_rates else 0
        )
        
        if avg_completion > 0.7:
            insights.append("You're doing great! Keep up the momentum")
        elif avg_completion < 0.4:
            insights.append("Start small - focus on 1-2 habits today")
        
        if task_count > 10:
            insights.append("You've been busy - don't forget self-care")
        
        return insights
    
    def _suggest_task_limit(self, tasks: List[Dict]) -> int:
        """Suggest optimal task limit based on recent activity"""
        if not tasks:
            return 4
        
        # Count completed tasks
        completed = sum(1 for t in tasks if t.get('status') == 'completed')
        completion_rate = completed / len(tasks) if tasks else 0
        
        if completion_rate > 0.8:
            return 6  # User handles more tasks well
        elif completion_rate < 0.5:
            return 3  # User should focus on fewer tasks
        else:
            return 4  # Default
    
    async def _fetch_user_habits(self, user_id: str) -> List[Dict]:
        """Fetch user habits from Firestore"""
        try:
            habits_ref = self.firestore.db.collection('habits')
            query = habits_ref.where('userId', '==', user_id)
            docs = query.stream()
            
            habits = []
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                habits.append(data)
            
            return habits
        except Exception as e:
            print(f"Error fetching habits: {e}")
            return []
    
    async def _fetch_habit_logs(
        self,
        user_id: str,
        lookback_days: int
    ) -> List[Dict]:
        """Fetch recent habit logs from Firestore"""
        try:
            cutoff_date = datetime.now() - timedelta(days=lookback_days)
            
            logs_ref = self.firestore.db.collection('habitLogs')
            query = logs_ref.where('userId', '==', user_id).where(
                'date', '>=', cutoff_date
            )
            docs = query.stream()
            
            logs = []
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                logs.append(data)
            
            return logs
        except Exception as e:
            print(f"Error fetching habit logs: {e}")
            return []
    
    async def _fetch_recent_tasks(
        self,
        user_id: str,
        lookback_days: int
    ) -> List[Dict]:
        """Fetch recent tasks from Firestore"""
        try:
            cutoff_date = datetime.now() - timedelta(days=lookback_days)
            
            tasks_ref = self.firestore.db.collection('tasks')
            query = tasks_ref.where('userId', '==', user_id).where(
                'scheduledDate', '>=', cutoff_date
            )
            docs = query.stream()
            
            tasks = []
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                tasks.append(data)
            
            return tasks
        except Exception as e:
            print(f"Error fetching tasks: {e}")
            return []
