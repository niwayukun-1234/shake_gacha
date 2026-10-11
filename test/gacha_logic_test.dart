import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shake_gacha/gacha_logic.dart';

void main() {
  test('排出率の合計は100%', () {
    final total = Rarity.values.fold<int>(0, (sum, r) => sum + r.weight);
    expect(total, 100);
  });

  test('各レア度にキャラが3種類ずつある', () {
    for (final rarity in Rarity.values) {
      expect(GachaLogic.characters[rarity], hasLength(3));
    }
  });

  test('抽選結果がおおよそ N70% / R25% / SSR5% になる', () {
    final gacha = GachaLogic(random: Random(42));
    const trials = 100000;
    final counts = {for (final r in Rarity.values) r: 0};
    for (var i = 0; i < trials; i++) {
      final result = gacha.draw();
      expect(GachaLogic.characters[result.rarity], contains(result.name));
      counts[result.rarity] = counts[result.rarity]! + 1;
    }
    expect(counts[Rarity.n]! / trials, closeTo(0.70, 0.01));
    expect(counts[Rarity.r]! / trials, closeTo(0.25, 0.01));
    expect(counts[Rarity.ssr]! / trials, closeTo(0.05, 0.01));
  });
}
