import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../views/avain he.dart';
import 'auth_wrapper.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ///signUP
  Future<User?> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? address,
    String? image,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification with better error handling
      try {
        await userCredential.user!.sendEmailVerification();
        print("Email verification sent successfully to: $email");
      } catch (emailError) {
        print("Error sending email verification: $emailError");
        // Don't fail registration if email sending fails, but log it
        // The user can request a new verification email later
      }

      await _firestore.collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'phone': phone,
        'address': address,
        'image': image,
        'docId': userCredential.user!.uid,
      });

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Registration Error: ${e.code} - ${e.message}");
      rethrow; // Re-throw to let the UI handle it properly
    } catch (e) {
      print("Registration Error: $e");
      rethrow; // Re-throw to let the UI handle it properly
    }
  }

  ///login
  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        // Send a new verification email before signing out
        try {
          await userCredential.user!.sendEmailVerification();
          print("New verification email sent to: $email");
        } catch (emailError) {
          print("Error sending verification email: $emailError");
        }
        
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before logging in. A new verification email has been sent.',
        );
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Login Error: ${e.code} - ${e.message}");
      rethrow; // Re-throw to let the UI handle it properly
    } catch (e) {
      print("Login Error: $e");
      rethrow; // Re-throw to let the UI handle it properly
    }
  }





  ///reset password
  Future resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print("Password reset email sent successfully to: $email");
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Password Reset Error: ${e.code} - ${e.message}");
      rethrow; // Re-throw to let the UI handle it properly
    } catch (e) {
      print("Password reset error: $e");
      rethrow; // Re-throw to let the UI handle it properly
    }
  }

  ///sign out
  Future<void> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      print('User signed out successfully');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false, // removes all previous routes
      );
    } catch (e) {
      print('Sign out error: $e');
      throw Exception('Failed to sign out: $e');
    }
  }
}