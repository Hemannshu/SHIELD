import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:title_proj/services/native_sms_service.dart';
import 'package:title_proj/utils/app_theme.dart';

class SafeHome extends StatefulWidget {
  @override
  State<SafeHome> createState() => _SafeHomeState();
}

class _SafeHomeState extends State<SafeHome> {
  Position? _currentPosition;
  LocationPermission? permission;

  @override
  void initState() {
    super.initState();
    _getPermission();
  }

  _getPermission() async {
    await [Permission.sms, Permission.location].request();
  }

  Future<bool> _sendSms(String phoneNumber, String message) async {
    try {
      await NativeSmsService.sendSms(phone: phoneNumber, message: message);
      Fluttertoast.showToast(msg: "Message sent!");
      return true;
    } catch (error) {
      Fluttertoast.showToast(msg: "Failed to send message: $error");
      return false;
    }
  }

  _getCurrentLocation() async {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location permission denied");
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(msg: "Location permission denied permanently");
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error getting location: $e");
    }
  }

  void showModelSafeHome(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppTheme.neutralGrey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Share Your Location",
                style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.neutralGrey900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Send your real-time location to emergency contacts",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : AppTheme.neutralGrey400,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _getCurrentLocation();
                    Fluttertoast.showToast(
                      msg: _currentPosition != null ? "Location fetched" : "Failed to fetch location",
                    );
                  },
                  icon: const Icon(Icons.my_location_rounded, size: 20),
                  label: Text("Get Location", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.darkElevated : AppTheme.neutralGrey100,
                    foregroundColor: isDark ? Colors.white : AppTheme.neutralGrey900,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 52,
                child: Container(
                  decoration: AppTheme.gradientButton(radius: 14),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_currentPosition != null) {
                        String message =
                            "Emergency! My location is: Lat: ${_currentPosition?.latitude}, "
                            "Long: ${_currentPosition?.longitude}";
                        await _sendSms("+918448018504", message);
                      } else {
                        Fluttertoast.showToast(msg: "Location not available yet");
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: Text("Send Alert", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => showModelSafeHome(context),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppTheme.darkCard, AppTheme.darkElevated]
                  : [Colors.white, const Color(0xFFFFF0F3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : AppTheme.primaryPink.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : AppTheme.primaryPink.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Share Location",
                      style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.neutralGrey900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Instantly share your real-time GPS with trusted contacts",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : AppTheme.neutralGrey400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Tap to share',
                        style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPink.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.share_location_rounded, color: Colors.white, size: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}