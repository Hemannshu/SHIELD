import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:title_proj/child/LoginScreen.dart';
import 'package:title_proj/child/register_child.dart';
import 'package:title_proj/utils/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : AppTheme.meshGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Floating orbs
              _buildOrb(size.height * 0.1, null, null, -30, 120,
                  AppTheme.primaryPink.withOpacity(0.08)),
              _buildOrb(null, null, -40, null, 160,
                  AppTheme.accentViolet.withOpacity(0.06), bottom: size.height * 0.2),
              _buildOrb(size.height * 0.5, null, null, -20, 80,
                  AppTheme.accentCoral.withOpacity(0.08)),

              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.04),

                      // Logo
                      Container(
                        width: size.height < 700 ? 140 : 200,
                        height: size.height < 700 ? 140 : 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryPink.withOpacity(0.1),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/SHEildlogo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: const BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.security, color: Colors.white, size: 80),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .scale(begin: const Offset(0.8, 0.8), duration: 800.ms, curve: Curves.easeOutBack),

                      const SizedBox(height: 40),

                      // Pulse shield icon
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = 1.0 + (_pulseController.value * 0.05);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryPink
                                        .withOpacity(0.3 + _pulseController.value * 0.2),
                                    blurRadius: 20 + _pulseController.value * 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.shield, color: Colors.white, size: 40),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

                      SizedBox(height: size.height < 700 ? 16 : 32),

                      // Title
                      Text(
                        'SHEild',
                        style: GoogleFonts.inter(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          foreground: Paint()
                            ..shader = AppTheme.primaryGradient
                                .createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                        ),
                      ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideY(begin: 0.3),

                      const SizedBox(height: 8),

                      Text(
                        'Your Safety, Your Power',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : AppTheme.neutralGrey600,
                        ),
                      ).animate().fadeIn(delay: 700.ms, duration: 600.ms),

                      const SizedBox(height: 12),

                      Text(
                        'Blockchain-secured emergency response\nwith real-time protection',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : AppTheme.neutralGrey400,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 900.ms, duration: 600.ms),

                      SizedBox(height: size.height < 700 ? 20 : size.height * 0.06),

                      // Feature pills
                      _buildFeaturePills(isDark)
                          .animate()
                          .fadeIn(delay: 1000.ms, duration: 600.ms),

                      const SizedBox(height: 40),

                      // Get Started button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: InkWell(
                          onTap: () => Navigator.push(context,
                              _createRoute(RegisterScreen())),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: AppTheme.gradientButton(radius: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 1200.ms, duration: 600.ms).slideY(begin: 0.2),

                      const SizedBox(height: 16),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: TextButton(
                          onPressed: () => Navigator.push(context,
                              _createRoute(LoginScreen())),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withOpacity(0.15)
                                    : AppTheme.neutralGrey200,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Text(
                            'I already have an account',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : AppTheme.neutralGrey600,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 1400.ms, duration: 600.ms),

                      SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePills(bool isDark) {
    final features = [
      ('SOS Alert', Icons.emergency),
      ('Blockchain', Icons.link),
      ('Crime Map', Icons.map),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: features.map((f) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : AppTheme.primaryPink.withOpacity(0.08),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : AppTheme.primaryPink.withOpacity(0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(f.$2, size: 14,
                  color: isDark ? AppTheme.primaryPinkLight : AppTheme.primaryPink),
              const SizedBox(width: 6),
              Text(f.$1, style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppTheme.neutralGrey800,
              )),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrb(double? top, double? bottom2, double? left, double? right,
      double size, Color color, {double? bottom}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom ?? bottom2,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _pulseController.value * 20 - 10),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          );
        },
      ),
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}