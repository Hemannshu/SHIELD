import 'package:flutter/material.dart';
import 'package:flutter_direct_caller_plugin/flutter_direct_caller_plugin.dart';

class PoliceEmergency extends StatelessWidget {
  const PoliceEmergency({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = screenSize.width * 0.75; // Reduced width
    final cardHeight = screenSize.height * 0.18; // Slightly taller

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: GestureDetector(
        onTap: () => FlutterDirectCallerPlugin.callNumber("181"),
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
                  Color.fromARGB(255, 228, 75, 184), // RGB(216, 68, 173)
                  Color(0xFFEC407A), // RGB(248, 7, 89)
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  // Icon and Text - Now in column layout
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
                              'assets/alert.png',
                              width: cardHeight * 0.3,
                              height: cardHeight * 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Women Helpline',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: cardHeight * 0.16, // Adjusted size
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Call 181 for Women\'s Helpline',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: cardHeight * 0.10, // Adjusted size
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
                          '181',
                          style: TextStyle(
                            color: Color(0xFFF80759),
                            fontWeight: FontWeight.bold,
                            fontSize: cardHeight * 0.2, // Adjusted size
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