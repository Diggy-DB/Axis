from typing import List, Dict, Any
from datetime import datetime, timedelta
import logging
from collections import defaultdict

from models.recommendation import (
    RecommendationResponse,
    RecommendedHabit,
    RecommendationPriority,
    LifeDomain
)
from services.firestore_client import FirestoreClient
from services.pattern_analyzer import PatternAnalyzer
from services.domain_balancer import DomainBalancer

logger = logging.getLogger(__name__)


class RecommendationEngine:
    """
    Rule-based recommendation engine (v1).
    
    This can be replaced with ML models later. The architecture is designed
    to support model swapping without changing the API contract.
    """
    
    def __init__(self, firestore_client: FirestoreClient):
        self.firestore = firestore_client
        self.pattern_analyzer = PatternAnalyzer()
        self.domain_balancer = DomainBalancer()
        
    async def generate_recommendation(
        self,
        user_id: str,
        target_date: datetime,
        lookback_days: int = 14
    ) -> RecommendationResponse:
        """
        Generate recommendation for the target date based on user's history.
        
        Algorithm:
        1. Analyze habit completion patterns
        2. Calculate domain balance scores
        3. Identify neglected areas
        4. Prioritize habits based on streaks and domain needs
        5. Analyze task completion patterns
        6. Generate actionable insights
        """
        
        # Fetch user data
        start_date = target_date - timedelta(days=lookback_days)
        
        habits = self.firestore.get_user_habits(user_id)
        habit_logs = self.firestore.get_habit_logs(user_id, start_date, target_date)
        tasks = self.firestore.get_user_tasks(user_id, start_date, target_date)
        reflections = self.firestore.get_user_reflections(user_id, start_date, target_date)
        
        # Analyze patterns
        habit_patterns = self.pattern_analyzer.analyze_habit_patterns(
            habits, habit_logs, lookback_days
        )
        task_patterns = self.pattern_analyzer.analyze_task_patterns(
            tasks, lookback_days
        )
        
        # Calculate domain balance
        domain_scores = self.domain_balancer.calculate_domain_scores(
            habits, habit_logs, lookback_days
        )
        
        # Identify focus area (most neglected domain)
        focus_area = min(domain_scores.items(), key=lambda x: x[1])[0]
        
        # Prioritize habits
        recommended_habits = self._prioritize_habits(
            habits, habit_patterns, domain_scores, focus_area
        )
        
        # Suggest task limit
        suggested_task_limit = self._calculate_task_limit(task_patterns)
        
        # Generate insights
        insights = self._generate_insights(
            domain_scores, task_patterns, habit_patterns, reflections
        )
        
        # Calculate confidence score
        confidence = self._calculate_confidence(
            len(habit_logs), len(tasks), lookback_days
        )
        
        recommendation = RecommendationResponse(
            dateFor=target_date,
            generatedAt=datetime.now(),
            recommendedHabits=recommended_habits[:6],  # Top 6 habits
            suggestedTaskLimit=suggested_task_limit,
            domainBalance=domain_scores,
            insights=insights,
            focusArea=focus_area,
            confidence=confidence
        )
        
        # Save recommendation to Firestore
        self.firestore.save_recommendation(
            user_id,
            recommendation.dict()
        )
        
        return recommendation
    
    def _prioritize_habits(
        self,
        habits: List[Dict],
        patterns: Dict[str, Any],
        domain_scores: Dict[str, float],
        focus_area: str
    ) -> List[RecommendedHabit]:
        """Prioritize habits based on multiple factors."""
        
        prioritized = []
        
        for habit in habits:
            habit_id = habit['id']
            habit_name = habit['name']
            domain = habit['domain']
            
            # Get habit-specific patterns
            completion_rate = patterns.get(habit_id, {}).get('completion_rate', 0.0)
            streak = patterns.get(habit_id, {}).get('current_streak', 0)
            
            # Determine priority
            priority = RecommendationPriority.MEDIUM
            reason = ""
            
            # Critical: Domain needs attention and habit is being neglected
            if domain == focus_area and completion_rate < 0.3:
                priority = RecommendationPriority.CRITICAL
                reason = f"{domain.capitalize()} domain needs attention. Let's restart this habit."
            
            # High: Active streak that should be maintained
            elif streak >= 3 and completion_rate >= 0.7:
                priority = RecommendationPriority.HIGH
                reason = f"You're on a {streak}-day streak! Keep the momentum going."
            
            # High: Domain is neglected but habit has some activity
            elif domain == focus_area and completion_rate >= 0.3:
                priority = RecommendationPriority.HIGH
                reason = f"{domain.capitalize()} domain needs more focus."
            
            # Medium: Recently started or moderate activity
            elif 0.3 <= completion_rate < 0.7:
                priority = RecommendationPriority.MEDIUM
                reason = "Building consistency with this habit."
            
            # Skip completely neglected habits (unless critical for domain)
            elif completion_rate < 0.1 and domain != focus_area:
                continue
            
            prioritized.append(
                RecommendedHabit(
                    habitId=habit_id,
                    habitName=habit_name,
                    priority=priority,
                    reason=reason
                )
            )
        
        # Sort by priority (critical > high > medium), then by completion rate
        priority_order = {
            RecommendationPriority.CRITICAL: 0,
            RecommendationPriority.HIGH: 1,
            RecommendationPriority.MEDIUM: 2
        }
        
        prioritized.sort(
            key=lambda x: (
                priority_order[x.priority],
                -patterns.get(x.habitId, {}).get('completion_rate', 0.0)
            )
        )
        
        return prioritized
    
    def _calculate_task_limit(self, task_patterns: Dict[str, Any]) -> int:
        """Calculate suggested task limit based on completion patterns."""
        
        avg_completed = task_patterns.get('avg_completed_per_day', 3.0)
        completion_rate = task_patterns.get('completion_rate', 0.5)
        
        # Be slightly ambitious but realistic
        if completion_rate >= 0.8:
            # User is doing great, can handle a bit more
            suggested = int(avg_completed * 1.3)
        elif completion_rate >= 0.5:
            # Moderate performance, slight increase
            suggested = int(avg_completed * 1.2)
        else:
            # Struggling, suggest maintaining or reducing
            suggested = max(int(avg_completed * 0.9), 3)
        
        # Keep within reasonable bounds
        return min(max(suggested, 3), 8)
    
    def _generate_insights(
        self,
        domain_scores: Dict[str, float],
        task_patterns: Dict[str, Any],
        habit_patterns: Dict[str, Any],
        reflections: List[Dict]
    ) -> List[str]:
        """Generate actionable insights based on analysis."""
        
        insights = []
        
        # Domain insights
        neglected_domains = [
            domain for domain, score in domain_scores.items()
            if score < 0.4
        ]
        
        if neglected_domains:
            domains_str = ", ".join([d.capitalize() for d in neglected_domains[:2]])
            insights.append(
                f"Your {domains_str} domain{'s' if len(neglected_domains) > 1 else ''} "
                f"need{'s' if len(neglected_domains) == 1 else ''} more attention."
            )
        
        # Task completion insights
        avg_completed = task_patterns.get('avg_completed_per_day', 0)
        completion_rate = task_patterns.get('completion_rate', 0)
        
        if completion_rate < 0.5:
            insights.append(
                f"You typically complete {int(avg_completed)} tasks per day. "
                "Consider breaking larger tasks into smaller chunks."
            )
        elif completion_rate >= 0.8:
            insights.append(
                f"Great job! You're completing {int(completion_rate * 100)}% of your tasks. "
                "You might be ready for slightly bigger challenges."
            )
        
        # Reflection-based insights
        if reflections:
            recent_moods = [r.get('mood', 5) for r in reflections if r.get('mood')]
            if recent_moods:
                avg_mood = sum(recent_moods) / len(recent_moods)
                if avg_mood < 5:
                    insights.append(
                        "Your recent reflections show lower mood scores. "
                        "Consider prioritizing self-care habits."
                    )
                elif avg_mood >= 7:
                    insights.append(
                        "Your mood has been great! Keep up the positive momentum."
                    )
        
        # Habit streak insights
        total_habits = len(habit_patterns)
        active_streaks = sum(
            1 for p in habit_patterns.values()
            if p.get('current_streak', 0) >= 3
        )
        
        if active_streaks >= 3:
            insights.append(
                f"You have {active_streaks} active streaks going! "
                "Consistency is key to lasting change."
            )
        
        return insights
    
    def _calculate_confidence(
        self,
        num_logs: int,
        num_tasks: int,
        lookback_days: int
    ) -> float:
        """Calculate confidence score based on available data."""
        
        # More data = higher confidence
        expected_data_points = lookback_days * 2  # Rough estimate
        actual_data_points = num_logs + num_tasks
        
        confidence = min(actual_data_points / expected_data_points, 1.0)
        
        # Minimum confidence of 0.3 with any data
        return max(confidence, 0.3 if actual_data_points > 0 else 0.1)
    
    async def get_domain_insights(
        self,
        user_id: str,
        domain: str
    ) -> List[str]:
        """Get specific insights for a domain."""
        
        insights = []
        
        # Fetch data for the last 30 days
        end_date = datetime.now()
        start_date = end_date - timedelta(days=30)
        
        habits = [
            h for h in self.firestore.get_user_habits(user_id)
            if h.get('domain') == domain
        ]
        habit_logs = self.firestore.get_habit_logs(user_id, start_date, end_date)
        
        if not habits:
            insights.append(f"No habits set up for {domain.capitalize()} yet.")
            return insights
        
        # Calculate completion rate for this domain
        domain_logs = [
            log for log in habit_logs
            if any(h['id'] == log['habitId'] for h in habits)
        ]
        
        completed = sum(1 for log in domain_logs if log.get('status') == 'completed')
        total = len(domain_logs)
        
        if total > 0:
            rate = completed / total
            if rate >= 0.7:
                insights.append(f"You're doing excellent in {domain.capitalize()}! Keep it up.")
            elif rate >= 0.4:
                insights.append(f"{domain.capitalize()} is progressing well. Stay consistent.")
            else:
                insights.append(f"{domain.capitalize()} needs more focus. Start with one small habit.")
        
        return insights
