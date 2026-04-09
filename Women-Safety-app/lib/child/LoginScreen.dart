import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:title_proj/child/ForgotPasswordScreen.dart';
import 'package:title_proj/child/bottom_page.dart';
import 'package:title_proj/child/register_child.dart';
import 'package:title_proj/child/bottom_screens/child_home_page.dart';
import 'package:title_proj/utils/app_theme.dart';
import 'package:title_proj/utils/constants.dart';
import 'package:title_proj/utils/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : AppTheme.meshGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Back button
                  _buildBackButton(isDark)
                      .animate()
                      .fadeIn(duration: 400.ms),

                  SizedBox(height: size.height * 0.04),

                  // Header
                  Text(
                    'Welcome\nBack',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -1,
                      color: isDark ? Colors.white : AppTheme.neutralGrey900,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.1),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to continue your safety journey',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: isDark ? Colors.white54 : AppTheme.neutralGrey400,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                  const SizedBox(height: 40),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassCard(isDark: isDark),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email field
                          Text('Email or Username',
                            style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : AppTheme.neutralGrey600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _usernameOrEmailController,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppTheme.neutralGrey900,
                            ),
                            decoration: InputDecoration(
                              hintText: 'info@example.com',
                              prefixIcon: Icon(Icons.person_outline_rounded,
                                  color: isDark ? Colors.white38 : AppTheme.neutralGrey400, size: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your username or email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Password field
                          Text('Password',
                            style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : AppTheme.neutralGrey600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppTheme.neutralGrey900,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter password',
                              prefixIcon: Icon(Icons.lock_outline_rounded,
                                  color: isDark ? Colors.white38 : AppTheme.neutralGrey400, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  color: isDark ? Colors.white38 : AppTheme.neutralGrey400,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _showPassword = !_showPassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Remember me & Forgot
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 20, height: 20,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: _rememberMe
                                            ? AppTheme.primaryPink
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: _rememberMe
                                              ? AppTheme.primaryPink
                                              : (isDark ? Colors.white24 : AppTheme.neutralGrey400),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: _rememberMe
                                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Remember me',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: isDark ? Colors.white54 : AppTheme.neutralGrey600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => ForgotPasswordScreen())),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text('Forgot Password?',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryPink,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: InkWell(
                              onTap: _isLoading ? null : _login,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                decoration: AppTheme.gradientButton(radius: 14),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22, height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text('Sign In',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 700.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // Register link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : AppTheme.neutralGrey600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => RegisterScreen())),
                          child: Text('Sign Up',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryPink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 800.ms, duration: 600.ms),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : AppTheme.neutralGrey200,
          ),
        ),
        child: Icon(Icons.arrow_back_rounded,
          color: isDark ? Colors.white70 : AppTheme.neutralGrey800, size: 20),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Determine if input is email or username
        final input = _usernameOrEmailController.text.trim();
        final isEmail = input.contains('@');

        String email;
        if (isEmail) {
          email = input;
        } else {
          // Lookup email from username
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: input.toLowerCase())
              .limit(1)
              .get();

          if (snapshot.docs.isEmpty) {
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: 'No user found with this username',
            );
          }
          email = snapshot.docs.first['email'];
        }

        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text,
        );

        // Save the login state and role to SharedPreferences
        User? user = userCredential.user;
        if (user != null) {
          String role = user.email!.contains("child") ? "child" : "parent";
          await SharedPreferencesUtil.saveLoginState(role);

          // Navigate based on the role
          if (role == "child") {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => BottomPage()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => BottomPage()),
              (route) => false,
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}