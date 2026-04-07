import 'package:flutter/material.dart';

class SOSButton extends StatefulWidget {
  final Future<void> Function() onPressed;

  const SOSButton({super.key, required this.onPressed});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> {
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = screenSize.width * 0.75; // Matched width
    final cardHeight = screenSize.height * 0.18; // Matched height

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: GestureDetector(
        onTap: _isSending
            ? null
            : () async {
                setState(() => _isSending = true);
                try {
                  await widget.onPressed();
                } finally {
                  setState(() => _isSending = false);
                }
              },
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
                  Color.fromRGBO(255, 0, 0, 1), // Bright red
                  Color.fromRGBO(200, 0, 0, 1), // Darker red
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
                        // Siren Icon
                        Container(
                          width: cardHeight * 0.3,
                          height: cardHeight * 0.3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '🚨',
                              style: TextStyle(
                                fontSize: cardHeight * 0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Text Content
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SOS EMERGENCY',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: cardHeight * 0.16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Press for immediate help',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: cardHeight * 0.10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Loading Indicator
                  if (_isSending)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
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