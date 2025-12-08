import os
from google.cloud import firestore
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)


class FirestoreClient:
    """Client for interacting with Google Cloud Firestore."""
    
    def __init__(self):
        # Initialize Firestore client
        # In production, use service account credentials
        self.db = firestore.Client()
        
    def get_user_habits(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all active habits for a user."""
        try:
            habits_ref = (
                self.db.collection('users')
                .document(user_id)
                .collection('habits')
            )
            
            query = habits_ref.where('archived', '==', False)
            habits = []
            
            for doc in query.stream():
                habit_data = doc.to_dict()
                habit_data['id'] = doc.id
                habits.append(habit_data)
                
            return habits
            
        except Exception as e:
            logger.error(f"Error fetching habits: {str(e)}")
            return []
    
    def get_habit_logs(
        self,
        user_id: str,
        start_date: datetime,
        end_date: Optional[datetime] = None
    ) -> List[Dict[str, Any]]:
        """Get habit logs for a user within a date range."""
        try:
            logs_ref = (
                self.db.collection('users')
                .document(user_id)
                .collection('habit_logs')
            )
            
            query = logs_ref.where('date', '>=', start_date)
            if end_date:
                query = query.where('date', '<=', end_date)
            
            logs = []
            for doc in query.stream():
                log_data = doc.to_dict()
                log_data['id'] = doc.id
                logs.append(log_data)
                
            return logs
            
        except Exception as e:
            logger.error(f"Error fetching habit logs: {str(e)}")
            return []
    
    def get_user_tasks(
        self,
        user_id: str,
        start_date: datetime,
        end_date: Optional[datetime] = None
    ) -> List[Dict[str, Any]]:
        """Get tasks for a user within a date range."""
        try:
            tasks_ref = (
                self.db.collection('users')
                .document(user_id)
                .collection('tasks')
            )
            
            query = tasks_ref.where('createdAt', '>=', start_date)
            if end_date:
                query = query.where('createdAt', '<=', end_date)
            
            tasks = []
            for doc in query.stream():
                task_data = doc.to_dict()
                task_data['id'] = doc.id
                tasks.append(task_data)
                
            return tasks
            
        except Exception as e:
            logger.error(f"Error fetching tasks: {str(e)}")
            return []
    
    def get_user_reflections(
        self,
        user_id: str,
        start_date: datetime,
        end_date: Optional[datetime] = None
    ) -> List[Dict[str, Any]]:
        """Get reflections for a user within a date range."""
        try:
            reflections_ref = (
                self.db.collection('users')
                .document(user_id)
                .collection('reflections')
            )
            
            query = reflections_ref.where('date', '>=', start_date)
            if end_date:
                query = query.where('date', '<=', end_date)
            
            reflections = []
            for doc in query.stream():
                reflection_data = doc.to_dict()
                reflection_data['id'] = doc.id
                reflections.append(reflection_data)
                
            return reflections
            
        except Exception as e:
            logger.error(f"Error fetching reflections: {str(e)}")
            return []
    
    def save_recommendation(
        self,
        user_id: str,
        recommendation: Dict[str, Any]
    ) -> str:
        """Save a recommendation to Firestore."""
        try:
            rec_ref = (
                self.db.collection('users')
                .document(user_id)
                .collection('ai_recommendations')
            )
            
            doc_ref = rec_ref.add(recommendation)
            return doc_ref[1].id
            
        except Exception as e:
            logger.error(f"Error saving recommendation: {str(e)}")
            raise
