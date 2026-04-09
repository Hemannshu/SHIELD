import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:title_proj/utils/app_theme.dart';
import 'package:title_proj/widgets/home_widgets/live_safe/BusStationCard.dart';
import 'package:title_proj/widgets/home_widgets/live_safe/HospitalCard.dart';
import 'package:title_proj/widgets/home_widgets/live_safe/PharmacyCard.dart';
import 'package:title_proj/widgets/home_widgets/live_safe/PoliceStationCard.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveSafe extends StatelessWidget {
  const LiveSafe({Key? key}) : super(key: key);

  static Future<void> openMap(String location) async {
    String googleUrl = 'https://www.google.com/maps/search/$location';
    final Uri _url = Uri.parse(googleUrl);
    try {
      await launchUrl(_url);
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Something went wrong! Call emergency number',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 110,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildLocationChip(
            context, 'Police', Icons.local_police_rounded,
            const Color(0xFF1565C0), isDarkMode,
            () => openMap('Police stations near me'),
          ),
          _buildLocationChip(
            context, 'Hospital', Icons.local_hospital_rounded,
            const Color(0xFFE53935), isDarkMode,
            () => openMap('Hospitals near me'),
          ),
          _buildLocationChip(
            context, 'Pharmacy', Icons.local_pharmacy_rounded,
            const Color(0xFF43A047), isDarkMode,
            () => openMap('Pharmacy near me'),
          ),
          _buildLocationChip(
            context, 'Bus Stop', Icons.directions_bus_rounded,
            const Color(0xFFFF8F00), isDarkMode,
            () => openMap('Bus stations near me'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationChip(BuildContext context, String label, IconData icon,
      Color color, bool isDark, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : color.withOpacity(0.1),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppTheme.neutralGrey800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}