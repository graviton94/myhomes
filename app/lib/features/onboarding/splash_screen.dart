import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/accounts.dart';
import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings.dart';
import '../../widgets/doodle.dart';
import '../../widgets/fairy_sketch.dart';

/// The start screen. On the native launch screen's persimmon: a paper circle
/// opens, a pencil sketches the fairy line by line (with its scratching
/// sound), the fairy colours in, stars and curly pig-tail marks pop out
/// ("뿅"), the name springs up, and "Touch to start" waits for a tap. A tap
/// while it is drawing jumps to the end. Guests go on to the login screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 5600);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: SplashScreen.duration);
  late final _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final _paper = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0, 0.07, curve: Curves.easeOutBack),
  );
  // 0-0.75 of the sketch is the pencil, the rest colours it in.
  late final _sketch = CurvedAnimation(parent: _anim, curve: const Interval(0.05, 0.8));
  late final _pop = CurvedAnimation(parent: _anim, curve: const Interval(0.78, 0.94));
  late final _title = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.84, 1, curve: Curves.elasticOut),
  );

  AudioPlayer? _pencil;
  AudioPlayer? _popSound;
  bool _popped = false;
  bool _still = false;

  @override
  void initState() {
    super.initState();
    _anim.addListener(_onTick);
    _anim.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _stopPencil();
        if (!_still) _blink.repeat(reverse: true);
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    if (_still) {
      _anim.value = 1;
    } else if (!_anim.isAnimating && _anim.value == 0) {
      _anim.forward();
      _play('sounds/pencil.wav', (p) => _pencil = p);
    }
  }

  void _onTick() {
    if (!_popped && _anim.value >= 0.78) {
      _popped = true;
      _stopPencil();
      _play('sounds/pop.wav', (p) => _popSound = p);
    }
  }

  /// Sounds are a nicety: a missing audio plugin (tests) or a muted phone never stops the screen.
  void _play(String asset, void Function(AudioPlayer) keep) {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final p = AudioPlayer();
      keep(p);
      p.play(AssetSource(asset)).catchError((_) {});
    } catch (_) {}
  }

  void _stopPencil() {
    try {
      _pencil?.stop().catchError((_) {});
    } catch (_) {}
  }

  void _tap() {
    if (_anim.value < 1) {
      _popped = true;
      _stopPencil();
      _anim.value = 1;
      return;
    }
    // Guests see the login screen on every start; signed-in people go straight in.
    final settings = ref.read(settingsProvider);
    if (settings.introSeen && ref.read(accountProvider).value == null) {
      ref.read(settingsProvider.notifier).leaveGuest();
    }
    ref.read(splashDoneProvider.notifier).done();
  }

  @override
  void dispose() {
    _stopPencil();
    _pencil?.dispose();
    _popSound?.dispose();
    _anim.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final ready = _anim.value >= 1 && ref.watch(homeProvider).hasValue;
    return Scaffold(
      backgroundColor: c.primary,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              Center(
                child: SizedBox(
                  width: 300,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      ScaleTransition(
                        scale: _paper,
                        child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
                        ),
                      ),
                      FairySketch(progress: _sketch, height: 186),
                      Positioned.fill(
                        child: IgnorePointer(child: _Burst(progress: _pop)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              AnimatedBuilder(
                animation: _title,
                builder: (context, child) => Opacity(
                  opacity: _title.value.clamp(0, 1),
                  child: Transform.scale(scale: 0.6 + 0.4 * _title.value, child: child),
                ),
                child: Text(
                  l.appTitle,
                  textAlign: TextAlign.center,
                  style: AppType.display.copyWith(fontSize: 42, color: c.onPrimary),
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                height: 48,
                child: ready
                    ? FadeTransition(
                        opacity: _still ? const AlwaysStoppedAnimation(1) : Tween(begin: 0.35, end: 1.0).animate(_blink),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app_rounded, color: c.onPrimary),
                            const SizedBox(width: AppSpace.sm),
                            Text(l.touchToStart, style: AppType.heading.copyWith(color: c.onPrimary)),
                          ],
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: AppSpace.xxl + AppSpace.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stars flying out and curly pig-tail marks, the comic "pop!" when the
/// drawing is done.
class _Burst extends StatelessWidget {
  const _Burst({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    builder: (context, _) => CustomPaint(painter: _BurstPainter(progress.value)),
  );
}

/// Drawn like the fairy herself: brown crayon outlines that wobble a little,
/// honey-yellow stars (the fairy's star), brown pig-tail curls and short
/// sparkle ticks, as in design/fairy/parts.svg.
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t);

  final double t;

  static const _ink = Color(0xFF3F2E22);
  static const _gold = Color(0xFFF2B33D);
  static const _cream = Color(0xFFFFFDF8);

  /// Same star as parts.svg (#star), with crayon wobble on each point.
  Path _star(double r, int seed) {
    final rnd = math.Random(seed);
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = (i.isEven ? r : r * 0.43) * (0.92 + rnd.nextDouble() * 0.16);
      final o = Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  /// A pig's tail: a short line that curls into a loop and out again.
  Path _curl(double s) => Path()
    ..moveTo(0, 0)
    ..cubicTo(6 * s, -2 * s, 12 * s, -10 * s, 7 * s, -14 * s)
    ..cubicTo(2 * s, -18 * s, -2 * s, -10 * s, 5 * s, -8 * s)
    ..cubicTo(11 * s, -6 * s, 16 * s, -12 * s, 20 * s, -18 * s);

  void _crayon(Canvas canvas, Path path, double upTo, Paint paint, int seed) => Doodle.crayon(canvas, path, paint, upTo: upTo, seed: seed);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final center = Offset(size.width / 2, size.height / 2 - 6);
    final out = Curves.easeOutBack.transform(t.clamp(0, 1));
    final ink = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Stars burst out around the head and settle, tilted like hand-drawn ones.
    const stars = [
      (-2.5, 112.0, 13.0),
      (-1.9, 126.0, 9.0),
      (-0.75, 118.0, 12.0),
      (-0.2, 130.0, 8.0),
      (0.5, 120.0, 10.0),
      (2.75, 120.0, 9.0),
    ];
    for (final (i, (angle, dist, r)) in stars.indexed) {
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * dist * out;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle * 0.3 + (1 - out) * 1.2);
      final star = _star(r * (0.4 + 0.6 * out), i);
      canvas.drawPath(star, Paint()..color = _gold);
      _crayon(canvas, star, 1, ink, 40 + i);
      canvas.restore();
    }

    // Brown pig-tail curls drawn in, the comic "뿅!".
    const curls = [(Offset(-104, -64), -0.5, 1.6), (Offset(86, -78), 0.3, 1.4), (Offset(96, 30), 0.9, 1.3), (Offset(-112, 18), 3.6, 1.2)];
    final draw = (t / 0.7).clamp(0.0, 1.0);
    for (final (i, (at, rot, s)) in curls.indexed) {
      canvas.save();
      canvas.translate(center.dx + at.dx, center.dy + at.dy);
      canvas.rotate(rot);
      // A cream halo under the brown line keeps it readable on persimmon.
      _crayon(
        canvas,
        _curl(s),
        draw,
        Paint()
          ..color = _cream
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5
          ..strokeCap = StrokeCap.round,
        70 + i,
      );
      _crayon(canvas, _curl(s), draw, ink..strokeWidth = 2.6, 70 + i);
      canvas.restore();
    }

    // Short sparkle ticks, like the fairy's own (fy-spark).
    final spark = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.3;
      final r0 = 70 + 22 * out;
      final from = center + Offset(math.cos(a), math.sin(a)) * r0;
      final to = center + Offset(math.cos(a), math.sin(a)) * (r0 + 9 * draw);
      canvas.drawLine(from, to, spark);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
