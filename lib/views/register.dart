import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:news_app/services/auth.dart';
import 'package:news_app/theme/energy_theme.dart';
import 'package:news_app/views/login.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await AuthServices().registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (user != null) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verify Email'),
            content: const Text(
              'A verification email has been sent to your email address. Please check your inbox (and spam folder) and verify your email before logging in.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered. Please use a different email or try logging in.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak. Please use a stronger password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid. Please check and try again.';
      } else {
        errorMessage = 'Registration failed: ${e.message ?? e.code}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
            'Sign Up',
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
                      child: const Icon(Icons.person_add,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Sign Up!',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Create a new account',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_nameController, 'Enter your name',
                        Icons.person_outline,
                        validator: _validateName),
                    const SizedBox(height: 12),
                    _buildTextField(_emailController, 'Enter your email',
                        Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail),
                    const SizedBox(height: 12),
                    _buildPasswordField(),
                    const SizedBox(height: 12),
                    _buildConfirmPasswordField(),
                    const SizedBox(height: 12),
                    _buildTextField(_phoneController, 'Enter your phone',
                        Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone),
                    const SizedBox(height: 12),
                    _buildTextField(_addressController, 'Enter your address',
                        Icons.location_on_outlined,
                        validator: _validateAddress),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                            color: Colors.white)
                            : const Text('Sign Up',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          },
                          child: Text(
                            'Sign In',
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

  Widget _buildTextField(
      TextEditingController controller,
      String hintText,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ?? _requiredField,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      enableInteractiveSelection: false, // disables copy/paste/select
      style: const TextStyle(color: Colors.black),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter a password';
        final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$');
        return passwordRegex.hasMatch(value)
            ? null
            : 'Password must be at least 8 characters long,\ninclude uppercase, lowercase, number and special character.';
      },
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
    );
  }


  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.black),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: 'Confirm your password',
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  String? _requiredField(String? value) {
    return (value == null || value.trim().isEmpty)
        ? 'This field is required'
        : null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your name';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Only characters allowed';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(value) ? null : 'Please enter a valid email';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    final passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');
    return passwordRegex.hasMatch(value)
        ? null
        : 'Password must be at least 8 characters,\ninclude upper & lower case, number, special character';
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your phone number';
    final phoneRegex = RegExp(r'^03\d{9}$'); // starts with 03 + 9 digits = 11 digits total
    if (!phoneRegex.hasMatch(value)) {
      return 'Phone number must start with 03 and be 11 digits long';
    }
    return null;
  }


  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter address';
    if (value.trim().length < 10) return 'Address must be at least 10 characters';
    return null;
  }
}