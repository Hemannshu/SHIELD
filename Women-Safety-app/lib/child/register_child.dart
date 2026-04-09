import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:title_proj/child/LoginScreen.dart';
import 'package:title_proj/utils/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _passwordStrength = '';
  List<String> _usernameSuggestions = [];
  bool _showSuccess = false;
  String _usernameError = '';
  bool _checkingUsername = false;
  Timer? _usernameDebounce;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          // Mesh gradient background
          Container(decoration: BoxDecoration(gradient: isDark ? AppTheme.darkGradient : AppTheme.meshGradient)),
          // Decorative orbs
          Positioned(top: -60, right: -40,
            child: Container(width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.accentViolet.withOpacity(0.25), Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(bottom: 100, left: -60,
            child: Container(width: 180, height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.accentCoral.withOpacity(0.2), Colors.transparent,
                ]),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : AppTheme.neutralGrey900).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 18,
                        color: isDark ? Colors.white : AppTheme.neutralGrey900),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2),
                  const SizedBox(height: 24),
                  // Header
                  Text('Create\nAccount',
                    style: GoogleFonts.inter(
                      fontSize: 36, fontWeight: FontWeight.w800, height: 1.15,
                      color: isDark ? Colors.white : AppTheme.neutralGrey900,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15),
                  const SizedBox(height: 6),
                  Text('Fill in your details to get started',
                    style: GoogleFonts.inter(
                      fontSize: 15, color: AppTheme.neutralGrey500,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                  const SizedBox(height: 28),
                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassCard(isDark: isDark),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildField(_nameController, 'Full Name', Icons.person_rounded,
                              isDark, validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter your name';
                            if (v.length < 3) return 'Name must be at least 3 characters';
                            return null;
                          }),
                          const SizedBox(height: 16),
                          _buildField(_usernameController, 'Username', Icons.alternate_email_rounded,
                              isDark,
                              suffixIcon: _checkingUsername
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2))
                                  : null,
                              errorText: _usernameError.isNotEmpty ? _usernameError : null,
                              onChanged: (value) {
                                _usernameDebounce?.cancel();
                                setState(() => _usernameError = '');
                                if (value.isEmpty) {
                                  setState(() { _usernameSuggestions = []; _checkingUsername = false; });
                                  return;
                                }
                                setState(() => _checkingUsername = true);
                                _usernameDebounce = Timer(Duration(milliseconds: 500), () async {
                                  final exists = await _isUsernameExists(value);
                                  if (exists) {
                                    setState(() { _usernameError = 'Username already taken'; _checkingUsername = false; });
                                  } else {
                                    await _generateUsernameSuggestions(value);
                                    setState(() => _checkingUsername = false);
                                  }
                                });
                              },
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please enter a username';
                                if (v.length < 4) return 'Username too short (min 4 chars)';
                                if (_usernameError.isNotEmpty) return _usernameError;
                                return null;
                              }),
                          // Username suggestions
                          if (_usernameSuggestions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Try these:',
                                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.neutralGrey500)),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8, runSpacing: 6,
                              children: _usernameSuggestions.map((u) => GestureDetector(
                                onTap: () => setState(() {
                                  _usernameController.text = u;
                                  _usernameSuggestions = [];
                                  _usernameError = '';
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryPink.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.primaryPink.withOpacity(0.3)),
                                  ),
                                  child: Text(u, style: GoogleFonts.inter(
                                    fontSize: 12, color: AppTheme.primaryPink, fontWeight: FontWeight.w500)),
                                ),
                              )).toList(),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildField(_emailController, 'Email', Icons.email_rounded,
                              isDark, keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter your email';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          }),
                          const SizedBox(height: 16),
                          _buildField(_passwordController, 'Password', Icons.lock_rounded,
                              isDark, obscure: !_showPassword,
                              onChanged: _checkPasswordStrength,
                              suffixIcon: IconButton(
                                icon: Icon(_showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  color: AppTheme.neutralGrey400, size: 20),
                                onPressed: () => setState(() => _showPassword = !_showPassword),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please enter a password';
                                if (v.length < 8) return 'Password must be at least 8 characters';
                                return null;
                              }),
                          // Password strength
                          if (_passwordStrength.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(children: [
                              Container(width: 8, height: 8,
                                decoration: BoxDecoration(shape: BoxShape.circle,
                                  color: _passwordStrength == 'Weak' ? Colors.red
                                    : _passwordStrength == 'Medium' ? Colors.orange : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$_passwordStrength password',
                                style: GoogleFonts.inter(fontSize: 12,
                                  color: _passwordStrength == 'Weak' ? Colors.red
                                    : _passwordStrength == 'Medium' ? Colors.orange : Colors.green,
                                  fontWeight: FontWeight.w500,
                                )),
                            ]),
                          ],
                          const SizedBox(height: 16),
                          _buildField(_confirmPasswordController, 'Confirm Password',
                              Icons.lock_outline_rounded, isDark,
                              obscure: !_showConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(_showConfirmPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  color: AppTheme.neutralGrey400, size: 20),
                                onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                              ),
                              validator: (v) {
                                if (v != _passwordController.text) return 'Passwords do not match';
                                return null;
                              }),
                          const SizedBox(height: 28),
                          // Register button
                          SizedBox(
                            width: double.infinity, height: 54,
                            child: InkWell(
                              onTap: _isLoading ? null : _register,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: AppTheme.gradientButton(radius: 16),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(width: 24, height: 24,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                      : Text('Create Account',
                                          style: GoogleFonts.inter(
                                            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Login link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Already have an account? ',
                                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.neutralGrey500)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (_) => LoginScreen())),
                                child: Text('Sign In',
                                  style: GoogleFonts.inter(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryPink,
                                  )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Success overlay
          if (_showSuccess)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.black38,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: AppTheme.glassCard(isDark: isDark),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                          ),
                          const SizedBox(height: 20),
                          Text('Account Created!',
                            style: GoogleFonts.inter(
                              fontSize: 20, fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.neutralGrey900,
                            )),
                          const SizedBox(height: 8),
                          Text('Redirecting to sign in...',
                            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.neutralGrey500)),
                        ],
                      ),
                    ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon,
      bool isDark, {
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? errorText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        color: isDark ? Colors.white : AppTheme.neutralGrey900, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.neutralGrey500),
        prefixIcon: Icon(icon, color: AppTheme.neutralGrey400, size: 20),
        suffixIcon: suffixIcon,
        errorText: errorText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white12 : AppTheme.neutralGrey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white12 : AppTheme.neutralGrey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryPink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkElevated.withOpacity(0.5) : AppTheme.neutralGrey100,
      ),
      validator: validator,
    );
  }

  void _checkPasswordStrength(String value) {
    if (value.isEmpty) {
      setState(() => _passwordStrength = '');
      return;
    }

    bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));
    bool hasLowercase = value.contains(RegExp(r'[a-z]'));
    bool hasSpecialChars = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasMinLength = value.length >= 8;

    int strength = 0;
    if (hasUppercase) strength++;
    if (hasDigits) strength++;
    if (hasLowercase) strength++;
    if (hasSpecialChars) strength++;
    if (hasMinLength) strength++;

    setState(() {
      if (strength <= 2) {
        _passwordStrength = 'Weak';
      } else if (strength <= 4) {
        _passwordStrength = 'Medium';
      } else {
        _passwordStrength = 'Strong';
      }
    });
  }

  Future<bool> _isUsernameExists(String username) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  Future<void> _generateUsernameSuggestions(String base) async {
    if (base.isEmpty) {
      setState(() => _usernameSuggestions = []);
      return;
    }

    final suggestions = [
      base,
      '${base}${DateTime.now().year % 100}',
      '${base}_${Random().nextInt(100)}',
      'the_$base',
      '${base}${base.length}',
    ];

    try {
      final available = await Future.wait(
        suggestions.map((username) => _isUsernameAvailable(username)),
      );

      setState(() {
        _usernameSuggestions = [];
        for (int i = 0; i < suggestions.length; i++) {
          if (available[i] && suggestions[i] != base) {
            _usernameSuggestions.add(suggestions[i]);
          }
        }
      });
    } catch (e) {
      print('Error generating username suggestions: $e');
    }
  }

  Future<bool> _isUsernameAvailable(String username) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      return snapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Create Firebase auth user
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // 2. Save additional user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim().toLowerCase(),
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'uid': credential.user!.uid,
      });

      // 3. Show success UI
      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });

      // 4. Wait for user to see the message before navigating
      await Future.delayed(const Duration(seconds: 2));
      
      // 5. Navigate only if widget is still mounted
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameDebounce?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}