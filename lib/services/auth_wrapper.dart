import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:news_app/views/Home.dart';
import 'package:news_app/views/login.dart';
import 'package:news_app/views/onboarding_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      _showOnboarding = !seenOnboarding;
      _isLoading = false;
    });

    // Optional: you can navigate here instead of returning widget in build
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showOnboarding) {
      return const OnboardingScreen();
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    } else {
      return const HomeScreen();
    }
  }
}
