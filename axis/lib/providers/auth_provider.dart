import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;
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
    _configureMacOSAuth();
  }

  void _configureMacOSAuth() async {
    // Configure Firebase Auth for macOS to handle keychain issues
    if (!kIsWeb && Platform.isMacOS) {
      try {
        // Use in-memory persistence to bypass keychain issues in development
        await _firebaseAuth.setPersistence(auth.Persistence.NONE);
        debugPrint(
            'Firebase Auth configured for macOS with in-memory persistence (development mode)');
        debugPrint('Note: Sessions will not persist after app restart');
      } catch (e) {
        debugPrint('Failed to configure macOS auth persistence: $e');
      }
    }
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

      debugPrint('Attempting to sign in with email: $email');

      // For macOS, try to handle keychain errors with retry logic
      if (!kIsWeb && Platform.isMacOS) {
        return await _signInWithEmailMacOS(email, password);
      }

      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('Sign in successful');
      _isLoading = false;
      notifyListeners();
      return true;
    } on auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception: ${e.code} - ${e.message}');
      _error = e.message ?? 'Authentication failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('General Exception: $e');
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// macOS-specific sign-in method to handle keychain issues
  Future<bool> _signInWithEmailMacOS(String email, String password) async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        debugPrint('macOS sign-in attempt ${retryCount + 1} of $maxRetries');

        await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        debugPrint('macOS sign in successful');
        _isLoading = false;
        notifyListeners();
        return true;
      } on auth.FirebaseAuthException catch (e) {
        debugPrint(
            'macOS Auth attempt ${retryCount + 1} failed: ${e.code} - ${e.message}');

        if (e.code == 'keychain-error') {
          debugPrint('Keychain error detected on macOS - attempting workaround');
          retryCount++;

          if (retryCount < maxRetries) {
            // Wait briefly before retry
            await Future.delayed(const Duration(milliseconds: 500));

            try {
              // Try clearing any cached auth state
              await _firebaseAuth.signOut();
              await Future.delayed(const Duration(milliseconds: 200));
            } catch (clearError) {
              debugPrint('Failed to clear auth state: $clearError');
            }

            continue;
          } else {
            // If all retries failed, show a development workaround message
            _error = 'macOS Keychain Issue (Development Mode): '
                'This is a known issue in macOS development. '
                'For production, proper code signing will resolve this. '
                'Try restarting the app or using a different macOS user account.';
          }
        } else {
          // For non-keychain errors, fail immediately
          _error = e.message ?? 'Authentication failed';
          break;
        }
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
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

  /// Update user profile
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(updatedUser.id);

      await userDoc.set(updatedUser.toFirestore(), SetOptions(merge: true));

      // Update local user state
      _user = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      _error = 'Failed to update profile';
      _isLoading = false;
      notifyListeners();
      return false;
    }
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
