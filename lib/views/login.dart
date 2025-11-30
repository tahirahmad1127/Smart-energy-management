import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:news_app/services/auth.dart';
import 'package:news_app/theme/energy_theme.dart';
import 'package:news_app/views/Home.dart';
import 'package:news_app/views/register.dart';
import 'package:news_app/views/reset_pwd.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final pwdController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(value) ? null : 'Please enter a valid email';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    final upper = RegExp(r'[A-Z]');
    final lower = RegExp(r'[a-z]');
    final digit = RegExp(r'\d');
    final special = RegExp(r'[!@#$%^&*]');
    if (!upper.hasMatch(value)) return 'Include at least one uppercase letter';
    if (!lower.hasMatch(value)) return 'Include at least one lowercase letter';
    if (!digit.hasMatch(value)) return 'Include at least one number';
    if (!special.hasMatch(value)) return 'Include at least one special character (!@#\$%^&*)';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? EnergyTheme.darkGradient.colors
        : [
      EnergyTheme.primaryCyan,
      EnergyTheme.primaryCyan,
      const Color(0xffFFFFFF),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Login',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: EnergyTheme.primaryCyan,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Log in!',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Take charge.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 48),

                    TextFormField(
                      controller: emailController,
                      validator: _validateEmail,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: pwdController,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                          if (!_formKey.currentState!.validate()) {
                            // If form is invalid, do not proceed
                            return;
                          }
                          try {
                            setState(() => _isLoading = true);

                            final user = await AuthServices()
                                .loginUser(
                                email: emailController.text.trim(),
                                password: pwdController.text.trim());

                            setState(() => _isLoading = false);

                            if (user != null) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => HomeScreen()));
                            }
                          } on FirebaseAuthException catch (e) {
                            setState(() => _isLoading = false);
                            String errorMessage = 'Login failed';
                            if (e.code == 'email-not-verified') {
                              errorMessage = e.message ?? 'Please verify your email before logging in. A new verification email has been sent.';
                            } else if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
                              errorMessage = 'Invalid email or password. Please check your credentials.';
                            } else if (e.code == 'user-disabled') {
                              errorMessage = 'This account has been disabled. Please contact support.';
                            } else {
                              errorMessage = e.message ?? 'Login failed: ${e.code}';
                            }
                            showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Login Error"),
                                  content: Text(errorMessage),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ));
                          } catch (e) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Login failed: ${e.toString()}')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Sign In',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ResetPasswordView()));
                      },
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => SignupScreen()));
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: isDark ? Colors.white : EnergyTheme.primaryCyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}