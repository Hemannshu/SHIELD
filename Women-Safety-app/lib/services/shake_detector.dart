import 'dart:ui';

import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  final VoidCallback onShake;
  final double shakeThreshold;
  final int minIntervalMs;

  DateTime _lastShake = DateTime.now();
  double _lastX = 0, _lastY = 0, _lastZ = 0;

  ShakeDetector({
    required this.onShake,
    this.shakeThreshold = 2.5,
    this.minIntervalMs = 2000,
  });

  void startListening() {
    userAccelerometerEvents.listen((event) {
      final now = DateTime.now();
      if (now.difference(_lastShake).inMilliseconds < minIntervalMs) return;

      final deltaX = (event.x - _lastX).abs();
      final deltaY = (event.y - _lastY).abs();
      final deltaZ = (event.z - _lastZ).abs();

      if ((deltaX + deltaY + deltaZ) > shakeThreshold) {
        _lastShake = now;
        onShake();
      }

      _lastX = event.x;
      _lastY = event.y;
      _lastZ = event.z;
    });
  }

  void stopListening() {
    userAccelerometerEvents.drain();
  }
}