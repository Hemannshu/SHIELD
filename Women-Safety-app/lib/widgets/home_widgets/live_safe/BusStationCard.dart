import 'package:flutter/material.dart';

class BusStationCard extends StatelessWidget {
  final Function(String) onMapFunction;
  final bool isDarkMode;
  
  const BusStationCard({
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
            borderRadius: BorderRadius.circular(40), // Circular shape
            onTap: () => onMapFunction('Bus Stations near me'),
            child: Card(
              elevation: 3,
              shape: const CircleBorder(), // Makes the card circular
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, // Circular container
                  image: DecorationImage(
                    image: AssetImage('assets/busstop.png'), // Your image
                    
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
            'Bus Stops',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 13, // Increased from 10 to 13
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}