import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  // Google sign-in
  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential? userCredential;

      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        
        googleProvider.setCustomParameters({
          'prompt': 'select_account'
        });
        
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();

        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null; 

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      if (userCredential.user != null) {
        await _updateUserInDatabase(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      print("Google Sign-In Error: $e");
      rethrow;
    }
  }

  Future<UserCredential> login(String email, String password) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await _updateUserInDatabase(credential.user!);
    return credential;
  }

  Future<void> _updateUserInDatabase(User user) async {
    final userRef = _db.collection('users').doc(user.uid);
    await userRef.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      print("Error signing out from Google: $e");
    }
    await _auth.signOut();
  }
}