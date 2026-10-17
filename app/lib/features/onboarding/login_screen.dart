import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings.dart';
import '../../widgets/fairy.dart';
import '../../widgets/sheets.dart';

/// Kakao, Naver and Google sign-in arrive in Phase 3. Until then only
/// "Start without an account" works; the others explain that.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final settings = ref.watch(settingsProvider);
    final isKo =
        settings.language == AppLanguage.ko ||
        (settings.language == AppLanguage.system && Localizations.localeOf(context).languageCode == 'ko');
    void soon() => showMessage(context, l.loginSoon);

    Widget provider({required String label, required Widget logo, required Color bg, required Color fg, Color? border}) => SizedBox(
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: border == null ? null : BorderSide(color: border),
        ),
        onPressed: soon,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            logo,
            const SizedBox(width: 10),
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );

    Widget mark(String letter, Color bg, Color fg, {bool round = true, Color? border}) => Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: round ? null : BorderRadius.circular(5),
        border: border == null ? null : Border.all(color: border, width: 1.5),
      ),
      child: Text(
        letter,
        style: AppType.label.copyWith(fontSize: 12, fontWeight: FontWeight.w800, color: fg),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.sm, AppSpace.xl, AppSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(settingsProvider.notifier).setLanguage(isKo ? AppLanguage.en : AppLanguage.ko),
                  icon: const Icon(Icons.language_rounded, size: 18),
                  label: Text(isKo ? 'English' : '한국어'),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Fairy(FairyPose.hello, height: 170),
                    const SizedBox(height: AppSpace.sm),
                    Text(l.appTitle, style: AppType.display.copyWith(fontSize: 34, color: c.primaryInk)),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      l.loginTagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c.mutedFg),
                    ),
                  ],
                ),
              ),
              provider(
                label: l.loginKakao,
                logo: mark('K', const Color(0xD9000000), const Color(0xFFFEE500)),
                bg: const Color(0xFFFEE500),
                fg: const Color(0xD9000000),
              ),
              const SizedBox(height: AppSpace.sm + 2),
              provider(
                label: l.loginNaver,
                logo: mark('N', Colors.white, const Color(0xFF03C75A), round: false),
                bg: const Color(0xFF03C75A),
                fg: Colors.white,
              ),
              const SizedBox(height: AppSpace.sm + 2),
              provider(
                label: l.loginGoogle,
                logo: mark('G', Colors.transparent, const Color(0xFF4285F4), border: c.border),
                bg: c.card,
                fg: c.fg,
                border: c.border,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: c.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                      child: Text(l.or, style: Theme.of(context).textTheme.bodySmall),
                    ),
                    Expanded(child: Divider(color: c.border)),
                  ],
                ),
              ),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: c.primarySoft, foregroundColor: c.primaryInk),
                  onPressed: () => ref.read(settingsProvider.notifier).startAsGuest(),
                  child: Text(l.startWithoutAccount),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(l.guestNote, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
