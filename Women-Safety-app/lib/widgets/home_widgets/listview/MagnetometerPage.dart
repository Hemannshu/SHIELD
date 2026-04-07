import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class MagnetometerPage extends StatefulWidget {
  @override
  State<MagnetometerPage> createState() => _MagnetometerPageState();
}

class _MagnetometerPageState extends State<MagnetometerPage>
    with SingleTickerProviderStateMixin {
  double _magX = 0, _magY = 0, _magZ = 0, _magnitude = 0;
  double _smoothedMagnitude = 0;
  bool _deviceDetected = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final StreamSubscription _magSubscription;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          ..repeat(reverse: true);
    _showInstructions();
    _listenToMagnetometer();
  }

  void _listenToMagnetometer() {
    _magSubscription = magnetometerEvents.listen((event) {
      if (!mounted) return;

      setState(() {
        _magX = event.x;
        _magY = event.y;
        _magZ = event.z;
        _magnitude =
            double.parse(sqrt(_magX * _magX + _magY * _magY + _magZ * _magZ)
                .toStringAsFixed(1));
        // Smooth sudden fluctuations
        _smoothedMagnitude = (_smoothedMagnitude * 0.9 + _magnitude * 0.1);
      });

      _handleDetection();
    });
  }

  void _handleDetection() {
    if (_smoothedMagnitude >= 80) {
      if (!_deviceDetected) {
        _deviceDetected = true;
        _playBeep('beep_high.mp3');
        _showAlert("🔴 Strong electromagnetic field detected!\nPossible hidden device nearby.");
      }
    } else if (_smoothedMagnitude >= 60) {
      if (!_deviceDetected) {
        _deviceDetected = true;
        _playBeep('beep.mp3');
        _showAlert("🟠 Suspicious magnetic field detected.\nInspect area.");
      }
    } else {
      _deviceDetected = false;
    }
  }

  Future<void> _showInstructions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool firstTime = prefs.getBool('first_time_magnet') ?? true;
    if (firstTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("How to Use"),
            content: Text(
              "📍 Move your phone slowly near mirrors, walls, electrical items, or vents.\n\n"
              "📡 The app will detect magnetic fields that might come from hidden electronics like spy cameras.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  prefs.setBool('first_time_magnet', false);
                  Navigator.pop(context);
                },
                child: Text("Got It"),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> _playBeep(String sound) async {
    await _audioPlayer.play(AssetSource(sound));
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("⚠️ Alert"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _magSubscription.cancel();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    if (_smoothedMagnitude >= 80) return Colors.red;
    if (_smoothedMagnitude >= 60) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (_smoothedMagnitude >= 80) return Icons.warning_amber_rounded;
    if (_smoothedMagnitude >= 60) return Icons.info_outline;
    return Icons.check_circle_outline;
  }

  String _getStatusText() {
    if (_smoothedMagnitude >= 80) return "Device Detected!";
    if (_smoothedMagnitude >= 60) return "Suspicious Field!";
    return "No Device Detected";
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Hidden Camera Detector"),
        backgroundColor: color,
        elevation: 2,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (_, __) {
                return Container(
                  width: 160 +
                      20 * _animationController.value, // pulse effect
                  height: 160 +
                      20 * _animationController.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.3),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: color.withOpacity(0.9),
                      child: Icon(
                        _getStatusIcon(),
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 30),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Magnetic Field: ${_smoothedMagnitude.toStringAsFixed(1)} µT",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 30),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text("Sensor Values (µT)",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Divider(),
                    Text("X: ${_magX.toStringAsFixed(1)}"),
                    Text("Y: ${_magY.toStringAsFixed(1)}"),
                    Text("Z: ${_magZ.toStringAsFixed(1)}"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
