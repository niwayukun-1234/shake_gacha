import 'dart:async';

import 'package:flutter/foundation.dart';

import 'motion_source.dart';

class ShakeDetector {
  ShakeDetector({
    required this.onShake,
    this.threshold = defaultThreshold,
    this.cooldown = defaultCooldown,
  });

  /// 「振った」と判定する加速度の大きさ(m/s²、重力を除く)。
  static const double defaultThreshold = 15.0;

  /// 一度反応してから次に反応するまでの待ち時間。
  static const Duration defaultCooldown = Duration(milliseconds: 1500);

  final VoidCallback onShake;
  final double threshold;
  final Duration cooldown;

  StreamSubscription<double>? _subscription;
  DateTime? _lastShakeAt;

  void start() {
    try {
      _subscription ??= userAccelerationMagnitudes().listen(
        _onMagnitude,
        onError: (Object e) => debugPrint('[Shake] センサーを利用できません: $e'),
        cancelOnError: true,
      );
    } catch (e) {
      // PCブラウザなどセンサーのない環境ではボタン操作のみになる
      debugPrint('[Shake] センサーを利用できません: $e');
    }
  }

  void _onMagnitude(double magnitude) {
    if (magnitude <= threshold) return;

    final now = DateTime.now();
    final last = _lastShakeAt;
    if (last != null && now.difference(last) < cooldown) return;

    _lastShakeAt = now;
    debugPrint('[Shake] 検知 magnitude=${magnitude.toStringAsFixed(1)}');
    onShake();
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
