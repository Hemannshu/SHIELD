import 'package:flutter/material.dart';

class PoliceStationCard extends StatelessWidget {
  final Function(String) onMapFunction;
  final bool isDarkMode;
  
  const PoliceStationCard({
    Key? key,
    required this.onMapFunction,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: () => onMapFunction('Police stations near me'),
            child: Card(
              elevation: 3,
              shape: const CircleBorder(),
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/policenearme.png'), // Your police image
                    fit: BoxFit.cover,
                    colorFilter: isDarkMode 
                      ? ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.dstATop)
                      : null,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Police',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 13, // Increased from 12 to match others
              fontWeight: FontWeight.w500, // Added for consistency
            ),
          ),
        ],
      ),
    );
  }
}