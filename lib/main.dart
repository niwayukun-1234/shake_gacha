import 'package:flutter/material.dart';

import 'gacha_logic.dart';
import 'motion_source.dart';
import 'shake_detector.dart';
import 'vibration_service.dart';

const Duration kSpinDuration = Duration(milliseconds: 1500);
const Duration kFlashDuration = Duration(milliseconds: 450);

void main() {
  runApp(const ShakeGachaApp());
}

class ShakeGachaApp extends StatelessWidget {
  const ShakeGachaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '振るガチャ',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'NotoSansJP',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const GachaPage(),
    );
  }
}

class GachaPage extends StatefulWidget {
  const GachaPage({super.key});

  @override
  State<GachaPage> createState() => _GachaPageState();
}

class _GachaPageState extends State<GachaPage> with TickerProviderStateMixin {
  final GachaLogic _gacha = GachaLogic();
  final VibrationService _vibration = VibrationService();

  late final ShakeDetector _shakeDetector;
  late final AnimationController _spinController;
  late final AnimationController _flashController;

  bool _isRolling = false;
  GachaResult? _result;

  /// iPhoneのブラウザでは、タップして許可をもらうまで振りを検知できない。
  bool _motionAllowed = !needsMotionPermission;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: kSpinDuration);
    _flashController = AnimationController(
      vsync: this,
      duration: kFlashDuration,
      value: 1, // 1 = フラッシュ消灯状態
    );
    _shakeDetector = ShakeDetector(onShake: _roll)..start();
  }

  @override
  void dispose() {
    _shakeDetector.dispose();
    _spinController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _enableMotion() async {
    final granted = await requestMotionPermission();
    if (!mounted) return;
    if (granted) {
      // 許可前に張ったリスナーにはイベントが届かないことがあるため張り直す
      _shakeDetector
        ..dispose()
        ..start();
      setState(() => _motionAllowed = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('モーションが許可されませんでした。ブラウザを開き直すともう一度選べます。'),
        ),
      );
    }
  }

  Future<void> _roll() async {
    if (_isRolling) return;
    setState(() {
      _isRolling = true;
      _result = null;
    });

    await _spinController.forward(from: 0);
    if (!mounted) return;

    final result = _gacha.draw();
    setState(() {
      _isRolling = false;
      _result = result;
    });
    if (result.rarity == Rarity.ssr) {
      _flashController.forward(from: 0);
    }
    _vibration.vibrateFor(result.rarity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'スマホを振れ!',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(child: Center(child: _buildStage(theme))),
                  if (!_motionAllowed) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _enableMotion,
                        icon: const Icon(Icons.vibration),
                        label: const Text('振って回すを有効にする'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isRolling ? null : _roll,
                      icon: const Icon(Icons.casino),
                      label: const Text('ボタンで回す'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // SSR時の白フラッシュ
          IgnorePointer(
            child: FadeTransition(
              opacity: ReverseAnimation(
                CurvedAnimation(
                  parent: _flashController,
                  curve: Curves.easeOut,
                ),
              ),
              child: const ColoredBox(
                color: Colors.white,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage(ThemeData theme) {
    final result = _result;
    if (_isRolling) {
      return RotationTransition(
        turns: Tween<double>(begin: 0, end: 4).animate(
          CurvedAnimation(parent: _spinController, curve: Curves.easeInOut),
        ),
        child: const _Capsule(),
      );
    }
    if (result != null) {
      return _ResultCard(result: result);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Capsule(),
        const SizedBox(height: 24),
        Text(
          '振るか、下のボタンを押してね',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Capsule extends StatelessWidget {
  const _Capsule();

  static const double _size = 160;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white70, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16)],
      ),
      child: ClipOval(
        child: Column(
          children: [
            Expanded(child: Container(color: Colors.redAccent)),
            Container(height: 6, color: Colors.black87),
            Expanded(child: Container(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final GachaResult result;

  static const Map<Rarity, Color> _colors = {
    Rarity.n: Color(0xFF9E9E9E),
    Rarity.r: Color(0xFF2979FF),
    Rarity.ssr: Color(0xFFFFC107),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colors[result.rarity]!;
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return TweenAnimationBuilder<double>(
      key: ValueKey(result),
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 32),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.rarity.label,
              style: theme.textTheme.displayMedium?.copyWith(
                color: onColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              result.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: onColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
