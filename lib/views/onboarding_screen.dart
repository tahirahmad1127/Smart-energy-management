import 'package:flutter/material.dart';
import 'package:news_app/views/onboarding-screens/page1.dart';
import 'package:news_app/views/onboarding-screens/page2.dart';
import 'package:news_app/views/onboarding-screens/page3.dart';
import 'package:news_app/views/onboarding-screens/page4.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'avain he.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  PageController _controller = PageController();

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              children: const [
                Onboarding1(),
                Onboarding2(),
                Onboarding3(),
                Onboarding4(), // last page with buttons
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: SmoothPageIndicator(
                controller: _controller,
                count: 4,
                effect: const ScrollingDotsEffect()),
          ),
        ],
      ),
    );
  }
}
