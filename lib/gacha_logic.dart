import 'dart:math';

enum Rarity {
  n('N', 70),
  r('R', 25),
  ssr('SSR', 5);

  const Rarity(this.label, this.weight);

  final String label;

  /// 排出率(%)。合計が100になるようにする。
  final int weight;
}

class GachaResult {
  const GachaResult(this.rarity, this.name);

  final Rarity rarity;
  final String name;
}

class GachaLogic {
  GachaLogic({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const Map<Rarity, List<String>> characters = {
    Rarity.n: ['はらぺこスライム', '見習い剣士ポコ', 'のんびりキノコ'],
    Rarity.r: ['蒼炎の魔導士リゼ', '疾風の狩人カイ', '鋼鉄の騎士ガルド'],
    Rarity.ssr: ['星詠みの女神アストレア', '終焉の竜王ヴァルザーク', '暁の勇者レオンハルト'],
  };

  GachaResult draw() {
    final rarity = _drawRarity();
    final names = characters[rarity]!;
    return GachaResult(rarity, names[_random.nextInt(names.length)]);
  }

  Rarity _drawRarity() {
    final total = Rarity.values.fold<int>(0, (sum, r) => sum + r.weight);
    var roll = _random.nextInt(total);
    for (final rarity in Rarity.values) {
      if (roll < rarity.weight) return rarity;
      roll -= rarity.weight;
    }
    return Rarity.values.last;
  }
}
