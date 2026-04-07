import 'package:flutter/material.dart';
import 'package:flutter_direct_caller_plugin/flutter_direct_caller_plugin.dart';

class AmbulanceEmergency extends StatelessWidget {
  const AmbulanceEmergency({Key? key}) : super(key: key);

  // Colors as constants
  static const _tealColor = Color.fromRGBO(0, 150, 136, 1);
  static const _darkTealColor = Color.fromRGBO(0, 121, 107, 1);
  static const _badgeTextColor = Color.fromRGBO(0, 77, 64, 1);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = screenSize.width * 0.75; // Matched width
    final cardHeight = screenSize.height * 0.18; // Matched height

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: GestureDetector(
        onTap: () => FlutterDirectCallerPlugin.callNumber("108"),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _tealColor,
                  _darkTealColor,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  // Icon and Text - Column layout
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: cardHeight * 0.3,
                          height: cardHeight * 0.3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/ambulance.png',
                              width: cardHeight * 0.25,
                              height: cardHeight * 0.25,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Medical Emergency',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: cardHeight * 0.16, // Matched size
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Call 108 for Ambulance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: cardHeight * 0.10, // Matched size
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Number Badge
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: cardWidth * 0.18,
                      height: cardHeight * 0.25,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '108',
                          style: TextStyle(
                            color: _badgeTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: cardHeight * 0.2, // Matched size
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}