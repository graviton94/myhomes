import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/account_backup.dart';
import '../../data/accounts.dart';
import '../../data/home_store.dart';

import 'package:go_router/go_router.dart';

import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings.dart';
import '../../widgets/fairy.dart';
import '../../widgets/backup_choice.dart';
import '../../widgets/login_buttons.dart';
import '../../widgets/fit_text.dart';
import '../../data/usage_stats.dart';

/// Kakao, Naver or Google, or start as a guest. Either way everything is
/// kept on the phone for now.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final settings = ref.watch(settingsProvider);
    final isKo = settings.language == AppLanguage.ko || (settings.language == AppLanguage.system && Localizations.localeOf(context).languageCode == 'ko');
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
                    FitText(
                      l.loginTagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c.mutedFg),
                    ),
                  ],
                ),
              ),
              LoginButtons(onSignedIn: () => _begin(context, ref)),
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
                  onPressed: () => _begin(context, ref),
                  child: Text(l.startWithoutAccount),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              FitText(l.guestNote, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Into the app; an empty home goes straight to "what is your home like?",
/// so the first map starts from a floor plan. Signed in, the account's home
/// is looked for first (its backup, or a shared home): a reinstall must not
/// start a new home over the one the account already has.
Future<void> _begin(BuildContext context, WidgetRef ref) async {
  final router = GoRouter.of(context);
  final signedIn = ref.read(accountProvider).value != null;
  noteUsage(ref, signedIn ? UsageCount.login : UsageCount.guest);
  var empty = ref.read(homeProvider).value?.spaces.isEmpty ?? false;
  if (signedIn) empty = await _accountHasNoHome(context, ref);
  ref.read(settingsProvider.notifier).start();
  if (empty) WidgetsBinding.instance.addPostFrameCallback((_) => router.push('/house/setup'));
}

/// True only when the check finished and found no home anywhere; offline or
/// unsure, the new-home setup is not offered (the map's own button stays).
Future<bool> _accountHasNoHome(BuildContext context, WidgetRef ref) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var open = true;
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
    ).whenComplete(() => open = false),
  );
  try {
    final linked = await linkAccountBackup(ref.read, (info, phone) => askWhichHome(context, info, phone)).timeout(
      const Duration(seconds: 20),
      onTimeout: () => false,
    );
    final d = await ref.read(homeProvider.future);
    return linked && d.spaces.isEmpty;
  } catch (_) {
    return false;
  } finally {
    if (open) navigator.pop();
  }
}
