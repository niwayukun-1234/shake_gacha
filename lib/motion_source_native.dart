import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

/// ネイティブではモーションの利用許可は不要。
bool get needsMotionPermission => false;

Future<bool> requestMotionPermission() async => true;

Stream<double> userAccelerationMagnitudes() {
  return userAccelerometerEventStream().map(
    (e) => sqrt(e.x * e.x + e.y * e.y + e.z * e.z),
  );
}
