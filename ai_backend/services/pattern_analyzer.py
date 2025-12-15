from datetime import datetime, timedelta
from typing import Dict, List
from models.recommendation import LifeDomain


class PatternAnalyzer:
    """Analyzes user patterns from historical data"""
    
    def analyze_habit_completion_patterns(
        self, 
        habit_logs: List[Dict],
        habits: List[Dict],
        lookback_days: int = 7
    ) -> Dict[str, float]:
        """
        Analyze habit completion patterns
        Returns dict of habit_id -> completion_rate
        """
        if not habit_logs or not habits:
            return {}
        
        cutoff_date = datetime.now() - timedelta(days=lookback_days)
        
        # Count completions per habit
        habit_counts = {}
        for log in habit_logs:
            if log.get('date') and log['date'] >= cutoff_date:
                habit_id = log.get('habitId')
                if habit_id:
                    habit_counts[habit_id] = habit_counts.get(habit_id, 0) + 1
        
        # Calculate completion rates
        completion_rates = {}
        for habit in habits:
            habit_id = habit.get('id')
            if habit_id:
                completions = habit_counts.get(habit_id, 0)
                completion_rates[habit_id] = completions / lookback_days
        
        return completion_rates
    
    def identify_struggling_domains(
        self,
        habits: List[Dict],
        completion_rates: Dict[str, float]
    ) -> List[LifeDomain]:
        """Identify life domains where user is struggling"""
        domain_performance = {}
        
        for habit in habits:
            habit_id = habit.get('id')
            domain = habit.get('lifeDomain')
            
            if habit_id and domain and habit_id in completion_rates:
                if domain not in domain_performance:
                    domain_performance[domain] = []
                domain_performance[domain].append(completion_rates[habit_id])
        
        # Find domains with low average completion
        struggling = []
        for domain, rates in domain_performance.items():
            avg_rate = sum(rates) / len(rates) if rates else 0
            if avg_rate < 0.5:  # Less than 50% completion
                try:
                    struggling.append(LifeDomain(domain))
                except ValueError:
                    pass
        
        return struggling
