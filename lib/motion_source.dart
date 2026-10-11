// 重力を除いた加速度の大きさ(m/s²)を、プラットフォームごとの方法で取得する。
export 'motion_source_native.dart'
    if (dart.library.js_interop) 'motion_source_web.dart';
