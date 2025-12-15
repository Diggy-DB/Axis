import os
from typing import Optional
import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1 import Client


class FirestoreClient:
    """Singleton Firestore client for AI backend"""
    
    _instance: Optional['FirestoreClient'] = None
    _db: Optional[Client] = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def __init__(self):
        if self._db is None:
            self._initialize_firebase()
    
    def _initialize_firebase(self):
        """Initialize Firebase Admin SDK"""
        try:
            # Check if already initialized
            firebase_admin.get_app()
        except ValueError:
            # Initialize with service account
            cred_path = os.getenv('FIREBASE_SERVICE_ACCOUNT_PATH')
            if cred_path and os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
            else:
                # Initialize with default credentials (for Cloud Run)
                firebase_admin.initialize_app()
        
        self._db = firestore.client()
    
    @property
    def db(self) -> Client:
        """Get Firestore database instance"""
        if self._db is None:
            self._initialize_firebase()
        return self._db


def get_firestore_client() -> FirestoreClient:
    """Get or create Firestore client instance"""
    return FirestoreClient()
