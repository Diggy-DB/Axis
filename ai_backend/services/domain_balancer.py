from typing import List, Dict, Any
from collections import defaultdict


class DomainBalancer:
    """Calculates and balances life domain scores."""
    
    DOMAINS = ['health', 'wealth', 'relationships', 'career', 'growth', 'spirituality']
    
    def calculate_domain_scores(
        self,
        habits: List[Dict],
        habit_logs: List[Dict],
        lookback_days: int
    ) -> Dict[str, float]:
        """
        Calculate balance scores for each life domain.
        
        Score is based on:
        - Number of habits in the domain
        - Completion rate of habits in that domain
        - Recent activity
        
        Returns:
            Dict mapping domain name to score (0.0 to 1.0)
            where 1.0 is excellent and 0.0 is neglected
        """
        
        # Group habits by domain
        habits_by_domain = defaultdict(list)
        for habit in habits:
            domain = habit.get('domain', 'health')
            habits_by_domain[domain].append(habit['id'])
        
        # Calculate scores for each domain
        domain_scores = {}
        
        for domain in self.DOMAINS:
            habit_ids = habits_by_domain.get(domain, [])
            
            if not habit_ids:
                # No habits for this domain = lowest score
                domain_scores[domain] = 0.0
                continue
            
            # Get logs for this domain's habits
            domain_logs = [
                log for log in habit_logs
                if log.get('habitId') in habit_ids
            ]
            
            if not domain_logs:
                # Habits exist but no activity
                domain_scores[domain] = 0.2
                continue
            
            # Calculate completion rate
            completed = sum(
                1 for log in domain_logs
                if log.get('status') == 'completed'
            )
            total = len(domain_logs)
            
            completion_rate = completed / total if total > 0 else 0.0
            
            # Calculate diversity score (how many different habits are being done)
            unique_habits_logged = len(set(log.get('habitId') for log in domain_logs))
            diversity_score = unique_habits_logged / len(habit_ids)
            
            # Combined score (70% completion, 30% diversity)
            combined_score = (completion_rate * 0.7) + (diversity_score * 0.3)
            
            # Apply recent activity boost
            # More recent logs = slightly higher score
            recent_logs = [
                log for log in domain_logs
                if log.get('status') == 'completed'
            ]
            
            if recent_logs:
                # Sort by date and check if there's recent activity
                recent_logs.sort(key=lambda x: x.get('date', ''), reverse=True)
                # If most recent activity is within last 3 days, small boost
                # This encourages maintaining recent good behavior
                recency_boost = 0.05 if len(recent_logs) > 0 else 0.0
                combined_score = min(combined_score + recency_boost, 1.0)
            
            domain_scores[domain] = round(combined_score, 2)
        
        return domain_scores
    
    def get_neglected_domains(
        self,
        domain_scores: Dict[str, float],
        threshold: float = 0.4
    ) -> List[str]:
        """
        Identify domains that are being neglected.
        
        Args:
            domain_scores: Dict of domain scores
            threshold: Score below which a domain is considered neglected
            
        Returns:
            List of neglected domain names, sorted by score (lowest first)
        """
        neglected = [
            (domain, score) for domain, score in domain_scores.items()
            if score < threshold
        ]
        
        # Sort by score (lowest first)
        neglected.sort(key=lambda x: x[1])
        
        return [domain for domain, _ in neglected]
    
    def get_thriving_domains(
        self,
        domain_scores: Dict[str, float],
        threshold: float = 0.7
    ) -> List[str]:
        """
        Identify domains where the user is doing well.
        
        Args:
            domain_scores: Dict of domain scores
            threshold: Score above which a domain is considered thriving
            
        Returns:
            List of thriving domain names, sorted by score (highest first)
        """
        thriving = [
            (domain, score) for domain, score in domain_scores.items()
            if score >= threshold
        ]
        
        # Sort by score (highest first)
        thriving.sort(key=lambda x: x[1], reverse=True)
        
        return [domain for domain, _ in thriving]
    
    def suggest_domain_focus(
        self,
        domain_scores: Dict[str, float]
    ) -> str:
        """
        Suggest which domain the user should focus on next.
        
        Returns the most neglected domain that has at least one habit.
        If all domains are equally neglected, returns the first one.
        """
        # Filter out domains with 0.0 score (no habits set up)
        domains_with_habits = {
            domain: score for domain, score in domain_scores.items()
            if score > 0.0
        }
        
        if not domains_with_habits:
            # No habits in any domain, suggest health as default
            return 'health'
        
        # Return domain with lowest score (most neglected)
        return min(domains_with_habits.items(), key=lambda x: x[1])[0]
