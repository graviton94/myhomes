import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings.dart';
import '../../widgets/fairy.dart';
import '../../widgets/login_buttons.dart';

/// Kakao, Naver or Google, or start as a guest. Either way everything is
/// kept on the phone for now.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final settings = ref.watch(settingsProvider);
    final isKo =
        settings.language == AppLanguage.ko ||
        (settings.language == AppLanguage.system &&
            Localizations.localeOf(context).languageCode == 'ko');
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xl,
            AppSpace.sm,
            AppSpace.xl,
            AppSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => ref
                      .read(settingsProvider.notifier)
                      .setLanguage(isKo ? AppLanguage.en : AppLanguage.ko),
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
                    Text(
                      l.appTitle,
                      style: AppType.display.copyWith(
                        fontSize: 34,
                        color: c.primaryInk,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      l.loginTagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: c.mutedFg),
                    ),
                  ],
                ),
              ),
              LoginButtons(
                onSignedIn: () => ref.read(settingsProvider.notifier).start(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: c.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.md,
                      ),
                      child: Text(
                        l.or,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(child: Divider(color: c.border)),
                  ],
                ),
              ),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: c.primarySoft,
                    foregroundColor: c.primaryInk,
                  ),
                  onPressed: () => ref.read(settingsProvider.notifier).start(),
                  child: Text(l.startWithoutAccount),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                l.guestNote,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
