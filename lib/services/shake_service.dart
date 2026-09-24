import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class ShakeService {
  StreamSubscription<UserAccelerometerEvent>? _subscription;

  DateTime? _lastShake;

  final double threshold;

  ShakeService({
    this.threshold = 7.0,
  });

  void start({
    required void Function() onShake,
  }) {
    _subscription?.cancel();

    _subscription =
        userAccelerometerEventStream().listen((event) {
      final acceleration = sqrt(
        event.x * event.x +
            event.y * event.y +
            event.z * event.z,
      );

      if (acceleration < threshold) {
        return;
      }

      final now = DateTime.now();

      if (_lastShake != null &&
          now.difference(_lastShake!) <
              const Duration(seconds: 1)) {
        return;
      }

      _lastShake = now;

      onShake();
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stop();
  }
}