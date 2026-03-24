import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class CrashDetectionService {
  // Spike threshold: how many m/s² above rolling average = crash
  // Default 15 = firm sudden shake triggers it, normal movement won't
  double spikeThreshold;

  static const int _cooldownSeconds = 30;
  static const int _windowSize = 6; // rolling average window

  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;

  bool _isActive = false;
  bool _inCooldown = false;

  double _gyroMagnitude = 0.0;
  double currentAccelMagnitude = 0.0;
  double currentGyroMagnitude = 0.0;

  final List<double> _window = [];

  final VoidCallback onCrashDetected;
  final void Function(double accel, double gyro)? onSensorUpdate;

  CrashDetectionService({
    required this.onCrashDetected,
    this.onSensorUpdate,
    this.spikeThreshold = 15.0,
  });

  void start() {
    _isActive = true;
    _window.clear();

    // Gyroscope — best effort, not required
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 40),
    ).listen((GyroscopeEvent event) {
      _gyroMagnitude = sqrt(
        event.x * event.x +
        event.y * event.y +
        event.z * event.z,
      );
      currentGyroMagnitude = _gyroMagnitude;
    }, onError: (_) {});

    // Accelerometer — primary crash sensor
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 40),
    ).listen((AccelerometerEvent event) {
      final double mag = sqrt(
        event.x * event.x +
        event.y * event.y +
        event.z * event.z,
      );

      currentAccelMagnitude = mag;
      onSensorUpdate?.call(mag, _gyroMagnitude);

      if (!_isActive || _inCooldown) return;

      // Maintain rolling average window
      _window.add(mag);
      if (_window.length > _windowSize) _window.removeAt(0);

      // Need at least a few readings before detection kicks in
      if (_window.length < 3) return;

      final double avg = _window.reduce((a, b) => a + b) / _window.length;
      final double spike = mag - avg;

      // Trigger when there's a sudden spike above baseline
      if (spike > spikeThreshold) {
        debugPrint('CRASH: mag=${mag.toStringAsFixed(1)} avg=${avg.toStringAsFixed(1)} spike=${spike.toStringAsFixed(1)}');
        _triggerCrash();
      }
    }, onError: (_) {});
  }

  void stop() {
    _isActive = false;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _window.clear();
    currentAccelMagnitude = 0.0;
    currentGyroMagnitude = 0.0;
  }

  void _triggerCrash() {
    _inCooldown = true;
    onCrashDetected();
    Future.delayed(const Duration(seconds: _cooldownSeconds), () {
      _inCooldown = false;
    });
  }

  void dispose() => stop();
}
