import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _currentUser;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last login
      if (_currentUser != null) {
        await _firestore.collection('users').doc(_currentUser!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Register with email and password
  Future<String?> register(String email, String password, String displayName) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user!.updateDisplayName(displayName);

      // Create comprehensive user document
      await _createUserProfile(
        credential.user!.uid,
        email,
        displayName,
        null,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Sign in with Google
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return 'Sign in cancelled';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Check if user exists, create profile if not
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _createUserProfile(
          userCredential.user!.uid,
          userCredential.user!.email!,
          userCredential.user!.displayName ?? 'User',
          userCredential.user!.photoURL,
        );
      } else {
        // Update last login
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        });
      }

      return null;
    } catch (e) {
      return 'Google sign in failed: ${e.toString()}';
    }
  }

  // Create user profile matching web structure
  Future<void> _createUserProfile(
    String uid,
    String email,
    String displayName,
    String? photoURL,
  ) async {
    final now = DateTime.now();

    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': 'New member of EcoLens AI community',
      'points': 0,
      'rank': null,
      'totalReports': 0,
      'verifiedReports': 0,
      'rejectedReports': 0,
      'pendingReports': 0,
      'badges': [],
      'badgesEarned': 0,
      'totalBadges': 12,
      'recentActivity': [
        {
          'type': 'join',
          'message': 'Joined EcoLens AI',
          'timestamp': Timestamp.fromDate(now),
          'points': 0,
          'icon': 'user-plus',
        }
      ],
      'settings': {
        'emailNotifications': true,
        'publicProfile': true,
        'showOnLeaderboard': true,
        'language': 'en',
        'theme': 'dark',
      },
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'memberSince': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'country': null,
      'city': null,
      'currentStreak': 0,
      'longestStreak': 0,
      'lastReportDate': null,
      'achievementProgress': {
        'report-10': 0,
        'report-50': 0,
        'report-100': 0,
        'points-500': 0,
        'points-1000': 0,
        'points-5000': 0,
        'streak-7': 0,
        'streak-30': 0,
        'violations-5': 0,
        'violations-20': 0,
      },
      'profileComplete': false,
      'completionPercentage': photoURL != null ? 50 : 30,
    });

    // Create leaderboard entry
    await _firestore.collection('leaderboard').doc(uid).set({
      'userId': uid,
      'displayName': displayName,
      'photoURL': photoURL,
      'points': 0,
      'rank': null,
      'totalReports': 0,
      'badgesEarned': 0,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Handle auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists for this email';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}
