import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

const double _gravity = 9.81;

JSObject? get _deviceMotionEvent =>
    globalContext.getProperty<JSObject?>('DeviceMotionEvent'.toJS);

/// iPhoneのSafariは、ユーザー操作をきっかけに許可を求める必要がある。
bool get needsMotionPermission =>
    _deviceMotionEvent?.has('requestPermission') ?? false;

/// ボタンのタップなど、ユーザー操作の中から呼ぶこと。
Future<bool> requestMotionPermission() async {
  final ctor = _deviceMotionEvent;
  if (ctor == null) return false;
  if (!ctor.has('requestPermission')) return true;
  try {
    final result = await ctor
        .callMethod<JSPromise<JSString>>('requestPermission'.toJS)
        .toDart;
    return result.toDart == 'granted';
  } catch (e) {
    debugPrint('[Shake] モーションの許可を取得できません: $e');
    return false;
  }
}

Stream<double> userAccelerationMagnitudes() {
  late final StreamController<double> controller;
  final listener = ((web.Event event) {
    final magnitude = _magnitudeOf(event as JSObject);
    if (magnitude != null) controller.add(magnitude);
  }).toJS;

  controller = StreamController<double>(
    onListen: () => web.window.addEventListener('devicemotion', listener),
    onCancel: () => web.window.removeEventListener('devicemotion', listener),
  );
  return controller.stream;
}

double? _magnitudeOf(JSObject event) {
  final linear = _vectorLength(event.getProperty<JSObject?>('acceleration'.toJS));
  if (linear != null) return linear;

  // 重力込みの値しか取れない端末では、重力分を差し引いて近似する
  final withGravity = _vectorLength(
    event.getProperty<JSObject?>('accelerationIncludingGravity'.toJS),
  );
  return withGravity == null ? null : (withGravity - _gravity).abs();
}

double? _vectorLength(JSObject? vector) {
  if (vector == null) return null;
  final x = vector.getProperty<JSNumber?>('x'.toJS)?.toDartDouble;
  final y = vector.getProperty<JSNumber?>('y'.toJS)?.toDartDouble;
  final z = vector.getProperty<JSNumber?>('z'.toJS)?.toDartDouble;
  if (x == null || y == null || z == null) return null;
  return sqrt(x * x + y * y + z * z);
}
