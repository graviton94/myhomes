import 'package:flutter/material.dart';

import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';

/// Shown while the household data loads. Same persimmon as the native launch
/// screen so the hand-off is seamless.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return Scaffold(
      backgroundColor: c.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            Container(
              width: 196,
              height: 196,
              decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Image.asset('assets/fairy/hello.webp', height: 176, excludeFromSemantics: true),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(l.appTitle, style: AppType.display.copyWith(fontSize: 38, color: c.onPrimary)),
            const Spacer(flex: 2),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: c.onPrimary.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: AppSpace.md),
            Text(l.splashLoading, style: AppType.body.copyWith(color: c.onPrimary, fontSize: 15)),
            const SizedBox(height: AppSpace.xxl + AppSpace.lg),
          ],
        ),
      ),
    );
  }
}
