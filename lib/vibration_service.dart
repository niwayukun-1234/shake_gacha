import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

import 'gacha_logic.dart';

class VibrationService {
  /// [待機, 振動, 待機, 振動, ...] のミリ秒パターン。
  static const Map<Rarity, List<int>> patterns = {
    Rarity.n: [0, 80],
    Rarity.r: [0, 120, 100, 120],
    Rarity.ssr: [0, 600, 120, 80, 60, 80, 60, 80, 60, 80, 60, 80],
  };

  Future<void> vibrateFor(Rarity rarity) async {
    final pattern = patterns[rarity]!;
    try {
      // エミュレータは非対応を返すことがあるので、パターンは判定前に出しておく
      debugPrint('[Vibration] ${rarity.label}: pattern=$pattern');
      if (!await Vibration.hasVibrator()) {
        debugPrint('[Vibration] ${rarity.label}: バイブ非対応のためスキップ');
        return;
      }
      await Vibration.vibrate(pattern: pattern);
    } catch (e) {
      debugPrint('[Vibration] ${rarity.label}: 失敗 $e');
    }
  }
}
