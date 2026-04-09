import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:title_proj/utils/app_theme.dart';
import 'package:title_proj/widgets/home_widgets/listview/SelfDefence.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:title_proj/widgets/home_widgets/CustomCarouel.dart';
import 'package:title_proj/widgets/home_widgets/listview/DetectCamera.dart';
import 'package:title_proj/widgets/home_widgets/listview/MagnetometerPage.dart';
import 'package:title_proj/widgets/home_widgets/listview/RiskAnalysis.dart';
import 'package:title_proj/widgets/home_widgets/listview/SelfDefencePage.dart';
import 'package:title_proj/widgets/home_widgets/listview/community_forum.dart';
import 'package:title_proj/widgets/home_widgets/listview/crime_map_page.dart';
import 'package:title_proj/widgets/home_widgets/listview/mental_health_chat.dart';
import 'package:title_proj/widgets/home_widgets/listview/period_tracker.dart';

class ExploreMorePage extends StatefulWidget {
  @override
  _ExploreMorePageState createState() => _ExploreMorePageState();
}

class _ExploreMorePageState extends State<ExploreMorePage> {
  String _locationMessage = "Getting your location...";
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationMessage = "Enable location services to see nearby services";
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationMessage = "Location permissions denied";
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationMessage = "Location permissions permanently denied";
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _locationMessage = "Location services active";
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationMessage = "Error getting location";
        _isLoadingLocation = false;
      });
    }
  }

  static Future<void> openMap(String location) async {
    String googleUrl = 'https://www.google.com/maps/search/$location';
    final Uri _url = Uri.parse(googleUrl);
    try {
      if (!await launchUrl(_url)) {
        throw 'Could not launch $_url';
      }
    } catch (e) {
      print('Error launching map: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore',
                      style: GoogleFonts.inter(
                        fontSize: 32, fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: isDark ? Colors.white : AppTheme.neutralGrey900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your comprehensive safety toolkit',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isDark ? Colors.white54 : AppTheme.neutralGrey400,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms),
            ),

            // Carousel
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                child: CustomCarouel(),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
            ),

            // Safety Tools
            SliverToBoxAdapter(
              child: _buildSectionTitle('Safety Tools', Icons.shield_rounded, isDark)
                  .animate().fadeIn(delay: 300.ms, duration: 500.ms),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildToolCard(context, Icons.camera_alt_rounded, 'Detect Camera',
                        const Color(0xFFE91E63), isDark, MagnetometerPage()),
                    _buildToolCard(context, Icons.analytics_rounded, 'Crime Map',
                        const Color(0xFF7C4DFF), isDark, CrimeMapPage()),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
            ),

            // Health & Wellbeing
            SliverToBoxAdapter(
              child: _buildSectionTitle('Health & Wellbeing', Icons.favorite_rounded, isDark)
                  .animate().fadeIn(delay: 500.ms, duration: 500.ms),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                childAspectRatio: 1.15,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildFeatureCard(context, Icons.calendar_month_rounded, 'Period Tracker',
                      const Color(0xFFF06292), isDark, PeriodTrackerPage()),
                  _buildFeatureCard(context, Icons.psychology_rounded, 'Mental Health',
                      const Color(0xFF26C6DA), isDark, MentalHealthChat()),
                  _buildFeatureCard(context, Icons.forum_rounded, 'Community',
                      const Color(0xFF66BB6A), isDark, CommunityForum()),
                  _buildFeatureCard(context, Icons.sports_martial_arts_rounded, 'Self Defence',
                      const Color(0xFF7C4DFF), isDark, SelfDefencePage()),
                ],
              ),
            ),

            // Nearby Services
            SliverToBoxAdapter(
              child: _buildSectionTitle('Nearby Services', Icons.location_on_rounded, isDark)
                  .animate().fadeIn(delay: 600.ms, duration: 500.ms),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildServiceTile('Police Stations', Icons.local_police_rounded,
                      const Color(0xFF1565C0), isDark),
                  const SizedBox(height: 8),
                  _buildServiceTile('Hospitals', Icons.local_hospital_rounded,
                      const Color(0xFFE53935), isDark),
                  const SizedBox(height: 8),
                  _buildServiceTile("Women's Shelters", Icons.shield_rounded,
                      const Color(0xFF7C4DFF), isDark),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryPink.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryPink, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.neutralGrey900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, IconData icon, String title,
      Color color, bool isDark, Widget page) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : color.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 13,
                  color: isDark ? Colors.white : AppTheme.neutralGrey800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, IconData icon, String title,
      Color color, bool isDark, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : color.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : color.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, fontSize: 13,
                color: isDark ? Colors.white : AppTheme.neutralGrey800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTile(String title, IconData icon, Color color, bool isDark) {
    return GestureDetector(
      onTap: () => openMap('$title near me'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : AppTheme.neutralGrey200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 14,
                    color: isDark ? Colors.white : AppTheme.neutralGrey900,
                  )),
                  Text('Find nearby', style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : AppTheme.neutralGrey400,
                  )),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : AppTheme.neutralGrey400, size: 22),
          ],
        ),
      ),
    );
  }
}