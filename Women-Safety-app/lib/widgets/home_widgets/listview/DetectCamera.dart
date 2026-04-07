import 'package:flutter/material.dart';
import 'MagnetometerPage.dart'; // Import the new page

class DetectCameras extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MagnetometerPage()),
              );
            },
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                height: 50,
                width: 50,
                child: Center(
                  child: Icon(
                    Icons.videocam, // Camera-related icon
                    size: 32,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          Text('Detect Cam'),
        ],
      ),
    );
  }
}