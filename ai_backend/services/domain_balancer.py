from typing import Dict, List
from models.recommendation import LifeDomain


class DomainBalancer:
    """Balances recommendations across life domains"""
    
    def calculate_domain_balance(
        self,
        habits: List[Dict],
        recommended_habit_ids: List[str]
    ) -> Dict[LifeDomain, float]:
        """
        Calculate balance across life domains for recommended habits
        Returns normalized scores (0-1) for each domain
        """
        # Count habits per domain in recommendations
        domain_counts = {domain: 0 for domain in LifeDomain}
        
        recommended_habits = [h for h in habits if h.get('id') in recommended_habit_ids]
        
        for habit in recommended_habits:
            domain = habit.get('lifeDomain')
            if domain:
                try:
                    domain_enum = LifeDomain(domain)
                    domain_counts[domain_enum] += 1
                except ValueError:
                    pass
        
        # Normalize to 0-1 scale
        max_count = max(domain_counts.values()) if domain_counts.values() else 1
        if max_count == 0:
            max_count = 1
        
        balance = {
            domain: count / max_count 
            for domain, count in domain_counts.items()
        }
        
        return balance
    
    def suggest_focus_area(
        self,
        struggling_domains: List[LifeDomain],
        current_balance: Dict[LifeDomain, float]
    ) -> LifeDomain:
        """Suggest a focus area based on struggles and current balance"""
        # Prioritize struggling domains
        if struggling_domains:
            return struggling_domains[0]
        
        # Otherwise, suggest least represented domain
        if current_balance:
            min_domain = min(current_balance.items(), key=lambda x: x[1])
            return min_domain[0]
        
        # Default
        return LifeDomain.HEALTH_AND_ENERGY
