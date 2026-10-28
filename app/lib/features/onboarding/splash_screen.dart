import 'package:flutter/material.dart';

import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/fairy_sketch.dart';

/// Shown while the household data loads (at least [splashDelayProvider]).
/// On the same persimmon as the native launch screen: a paper circle opens,
/// the fairy is sketched in line by line, colours in, and the name appears.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Length of the drawing; the loading screen stays at least this long.
  static const duration = Duration(milliseconds: 2200);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: SplashScreen.duration);
  late final _paper = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0, 0.16, curve: Curves.easeOutBack),
  );
  late final _sketch = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.08, 0.92, curve: Curves.easeInOutSine),
  );
  late final _title = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.7, 1, curve: Curves.easeOutCubic),
  );
  // If loading takes longer than the drawing, say so.
  late final _slow = CurvedAnimation(parent: _anim, curve: const Interval(0.98, 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.value = 1;
    } else if (!_anim.isAnimating && _anim.value == 0) {
      _anim.forward();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return Scaffold(
      backgroundColor: c.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 3),
            Center(
              child: ScaleTransition(
                scale: _paper,
                child: Container(
                  width: 196,
                  height: 196,
                  decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: FairySketch(progress: _sketch, height: 176),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            FadeTransition(
              opacity: _title,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(_title),
                child: Text(
                  l.appTitle,
                  textAlign: TextAlign.center,
                  style: AppType.display.copyWith(fontSize: 38, color: c.onPrimary),
                ),
              ),
            ),
            const Spacer(flex: 2),
            FadeTransition(
              opacity: _slow,
              child: Column(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3, color: c.onPrimary.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    l.splashLoading,
                    textAlign: TextAlign.center,
                    style: AppType.body.copyWith(color: c.onPrimary, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xxl + AppSpace.lg),
          ],
        ),
      ),
    );
  }
}
