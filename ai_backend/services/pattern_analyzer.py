from typing import List, Dict, Any
from datetime import datetime, timedelta
from collections import defaultdict


class PatternAnalyzer:
    """Analyzes user behavior patterns for habits and tasks."""
    
    def analyze_habit_patterns(
        self,
        habits: List[Dict],
        habit_logs: List[Dict],
        lookback_days: int
    ) -> Dict[str, Any]:
        """
        Analyze habit completion patterns.
        
        Returns:
            Dict with habit_id as key and pattern data as value:
            {
                'habit_id': {
                    'completion_rate': 0.75,
                    'current_streak': 5,
                    'longest_streak': 10,
                    'last_completed': datetime,
                    'frequency': 'daily',
                }
            }
        """
        patterns = {}
        
        for habit in habits:
            habit_id = habit['id']
            
            # Get logs for this habit
            habit_specific_logs = [
                log for log in habit_logs
                if log.get('habitId') == habit_id
            ]
            
            # Sort by date
            habit_specific_logs.sort(key=lambda x: x['date'])
            
            # Calculate completion rate
            completed_count = sum(
                1 for log in habit_specific_logs
                if log.get('status') == 'completed'
            )
            total_days = lookback_days
            completion_rate = completed_count / total_days if total_days > 0 else 0.0
            
            # Calculate streaks
            current_streak = 0
            longest_streak = 0
            temp_streak = 0
            last_date = None
            last_completed = None
            
            for log in habit_specific_logs:
                if log.get('status') == 'completed':
                    log_date = log['date']
                    
                    if last_date is None:
                        temp_streak = 1
                    else:
                        # Check if consecutive day
                        days_diff = (log_date - last_date).days
                        if days_diff == 1:
                            temp_streak += 1
                        else:
                            temp_streak = 1
                    
                    last_date = log_date
                    last_completed = log_date
                    longest_streak = max(longest_streak, temp_streak)
                elif log.get('status') == 'skipped':
                    temp_streak = 0
                    last_date = log['date']
            
            # Check if current streak is still valid
            if last_completed:
                today = datetime.now().date()
                last_completed_date = last_completed.date() if isinstance(last_completed, datetime) else last_completed
                days_since = (today - last_completed_date).days
                
                if days_since <= 1:  # Today or yesterday
                    current_streak = temp_streak
                else:
                    current_streak = 0
            
            patterns[habit_id] = {
                'completion_rate': completion_rate,
                'current_streak': current_streak,
                'longest_streak': longest_streak,
                'last_completed': last_completed,
                'total_completions': completed_count,
            }
        
        return patterns
    
    def analyze_task_patterns(
        self,
        tasks: List[Dict],
        lookback_days: int
    ) -> Dict[str, Any]:
        """
        Analyze task completion patterns.
        
        Returns:
            Dict with overall task statistics:
            {
                'total_tasks': 50,
                'completed_tasks': 35,
                'completion_rate': 0.7,
                'avg_completed_per_day': 2.5,
                'completion_by_day': {...},
            }
        """
        total_tasks = len(tasks)
        completed_tasks = sum(
            1 for task in tasks
            if task.get('status') == 'completed'
        )
        
        completion_rate = completed_tasks / total_tasks if total_tasks > 0 else 0.0
        
        # Calculate tasks completed per day
        completion_by_day = defaultdict(int)
        
        for task in tasks:
            if task.get('status') == 'completed' and task.get('completedAt'):
                completed_date = task['completedAt']
                if isinstance(completed_date, datetime):
                    date_key = completed_date.date()
                else:
                    date_key = completed_date
                
                completion_by_day[date_key] += 1
        
        # Calculate average
        days_with_completions = len(completion_by_day)
        avg_completed_per_day = (
            sum(completion_by_day.values()) / days_with_completions
            if days_with_completions > 0
            else 0.0
        )
        
        return {
            'total_tasks': total_tasks,
            'completed_tasks': completed_tasks,
            'completion_rate': completion_rate,
            'avg_completed_per_day': avg_completed_per_day,
            'completion_by_day': dict(completion_by_day),
        }
