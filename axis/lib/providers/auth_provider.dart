import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  UserModel? _user;
  bool _isLoading = true;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initialize();
  }

  void _initialize() {
    // Listen to auth state changes
    _firebaseAuth.authStateChanges().listen((auth.User? firebaseUser) {
      if (firebaseUser != null) {
        _user = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'User',
          photoURL: firebaseUser.photoURL,
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          timezone: DateTime.now().timeZoneName,
          preferences: UserPreferences(),
        );
      } else {
        _user = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on auth.FirebaseAuthException catch (e) {
      _error = e.message ?? 'Authentication failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      _isLoading = false;
      notifyListeners();
      return true;
    } on auth.FirebaseAuthException catch (e) {
      _error = e.message ?? 'Registration failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign up with detailed information (including onboarding answers)
  Future<bool> signUpWithDetails({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String coreValues,
    required String worldview,
    required String ambition,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create Firebase Auth account
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fullName = '$firstName $lastName';
      await credential.user?.updateDisplayName(fullName);

      // Create user document with all details
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid);

      final userData = {
        'email': email,
        'displayName': fullName,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'answer1': coreValues,
        'answer2': worldview,
        'answer3': ambition,
        'createdAt': Timestamp.now(),
        'timezone': DateTime.now().timeZoneName,
        'preferences': {
          'theme': 'system',
          'firstDayOfWeek': 1,
          'notificationsEnabled': true,
        },
      };

      await userDoc.set(userData);

      _isLoading = false;
      notifyListeners();
      return true;
    } on auth.FirebaseAuthException catch (e) {
      _error = e.message ?? 'Registration failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _user = null;
    notifyListeners();
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      _error = 'Failed to send reset email';
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
