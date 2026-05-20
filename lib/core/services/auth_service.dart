import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'settings_service.dart';

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final User? user;
  final bool isNewUser;
  final bool needsRoleSelection; // true if user hasn't selected student/teacher yet

  AuthResult({
    required this.isSuccess,
    this.errorMessage,
    this.user,
    this.isNewUser = false,
    this.needsRoleSelection = false,
  });
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user exists in Firestore and has selected a role
      final userDoc = await _firestore.collection('users').doc(credential.user!.uid).get();
      final bool docExists = userDoc.exists;
      final bool hasSelectedRole = docExists &&
          (userDoc.data() as Map<String, dynamic>?)?['hasSelectedRole'] == true;

      return AuthResult(
        isSuccess: true,
        user: credential.user,
        isNewUser: !docExists,
        needsRoleSelection: !hasSelectedRole,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is badly formatted.';
      } else if (e.code == 'user-disabled') {
        message = 'This user has been disabled.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      }
      return AuthResult(isSuccess: false, errorMessage: message);
    } catch (e) {
      return AuthResult(isSuccess: false, errorMessage: e.toString());
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      UserCredential userCredential;
      
      if (kIsWeb) {
        // Use Firebase's built-in popup for web, which doesn't require extra google_sign_in setup
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(authProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
        if (googleUser == null) {
          return AuthResult(isSuccess: false, errorMessage: 'Sign-in cancelled.');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: null, // accessToken is moved to authorizationClient in v7.x
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final User? user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        bool isNew = !userDoc.exists;
        bool hasSelectedRole = !isNew &&
            (userDoc.data() as Map<String, dynamic>?)?['hasSelectedRole'] == true;

        if (isNew) {
          // Initialize basic user data for a new user
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'name': user.displayName,
            'photoUrl': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'role': null,
            'hasSelectedRole': false,
          });
        }

        return AuthResult(
          isSuccess: true,
          user: user,
          isNewUser: isNew,
          needsRoleSelection: !hasSelectedRole,
        );
      }
      return AuthResult(isSuccess: false, errorMessage: 'Failed to get user info.');
    } catch (e) {
      return AuthResult(isSuccess: false, errorMessage: 'Google Sign-In Error: ${e.toString()}');
    }
  }

  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(displayName);
        
        // Save to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'name': displayName,
          'photoUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
          'role': null, // Role will be selected later
          'hasSelectedRole': false,
        });

        return AuthResult(isSuccess: true, user: user, isNewUser: true);
      }
      return AuthResult(isSuccess: false, errorMessage: 'Registration failed.');
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred during sign-up.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is badly formatted.';
      }
      return AuthResult(isSuccess: false, errorMessage: message);
    } catch (e) {
      return AuthResult(isSuccess: false, errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
    SettingsService().clearUserData();
  }
}
