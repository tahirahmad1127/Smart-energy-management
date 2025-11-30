import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:news_app/theme/energy_theme.dart';
import 'package:news_app/views/onboarding_screen.dart';
import 'package:news_app/views/Home.dart';
import 'package:news_app/views/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _slideController;

  late Animation<Color?> _gradientColor;
  late Animation<Offset> _logoOffset;
  late Animation<Offset> _textOffset;

  @override
  void initState() {
    super.initState();

    _startAnimations();
    _navigateUser();
  }

  void _startAnimations() {
    _gradientController =
    AnimationController(duration: const Duration(seconds: 7), vsync: this)
      ..repeat(reverse: true);

    _gradientColor = TweenSequence<Color?>([
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xff000000), end: EnergyTheme.primaryCyan),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: EnergyTheme.primaryCyan, end: const Color(0xffFFFFFF)),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xffFFFFFF), end: const Color(0xff000000)),
          weight: 1),
    ]).animate(CurvedAnimation(
        parent: _gradientController, curve: Curves.easeInOut));

    _slideController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _logoOffset = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _slideController, curve: Curves.easeOut));

    _textOffset = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _slideController, curve: Curves.easeOut));

    _slideController.forward();
  }

  Future<void> _navigateUser() async {
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();

    bool hasSeenOnboarding = prefs.getBool("seenOnboarding") ?? false;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User already logged in → Go to Home
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      // User not logged in
      if (hasSeenOnboarding) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        prefs.setBool("seenOnboarding", true);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      }
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _gradientColor,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _gradientColor.value ?? const Color(0xff000000),
                      EnergyTheme.primaryCyan,
                      const Color(0xffFFFFFF),
                    ],
                  ),
                ),
              );
            },
          ),
          Center(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                "assets/animations/3.gif",
                width: 350,
                height: 350,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SlideTransition(
                  position: _logoOffset,
                  child: Image.asset(
                    "assets/images/logo.png",
                    width: 250,
                    height: 167,
                  ),
                ),
                const SizedBox(height: 10),
                SlideTransition(
                  position: _textOffset,
                  child: Text(
                    "Voltify",
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 30,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
