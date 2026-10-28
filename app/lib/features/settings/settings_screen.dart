import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/accounts.dart';
import '../../data/home_store.dart';
import '../../data/reminders.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings.dart';
import '../../widgets/sheets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        children: [
          _Section(l.accountSection),
          const _AccountTile(),
          const Divider(),
          _Section(l.language),
          RadioGroup<AppLanguage>(
            groupValue: settings.language,
            onChanged: (v) => v == null ? null : controller.setLanguage(v),
            child: Column(
              children: [
                RadioListTile(value: AppLanguage.system, title: Text(l.languageSystem)),
                // Language names stay in their own language so anyone can find theirs.
                const RadioListTile(value: AppLanguage.en, title: Text('English')),
                const RadioListTile(value: AppLanguage.ko, title: Text('한국어')),
              ],
            ),
          ),
          const Divider(),
          _Section(l.theme),
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (v) => v == null ? null : controller.setThemeMode(v),
            child: Column(
              children: [
                RadioListTile(value: ThemeMode.system, title: Text(l.themeSystem)),
                RadioListTile(value: ThemeMode.light, title: Text(l.themeLight)),
                RadioListTile(value: ThemeMode.dark, title: Text(l.themeDark)),
              ],
            ),
          ),
          const Divider(),
          _Section(l.featuresSection),
          SwitchListTile(
            key: const ValueKey('feature-expiry'),
            value: settings.expiryOn,
            onChanged: (on) async {
              await controller.setExpiryOn(on);
              if (on && context.mounted) await _askToNotify(context, ref);
            },
            secondary: const Icon(Icons.event_available_rounded),
            title: Text(l.featureExpiry),
            subtitle: Text(l.featureExpiryBody),
          ),
          SwitchListTile(
            key: const ValueKey('feature-returns'),
            value: settings.returnsOn,
            onChanged: (on) async {
              await controller.setReturnsOn(on);
              if (on && context.mounted) await _askToNotify(context, ref);
            },
            secondary: const Icon(Icons.assignment_return_outlined),
            title: Text(l.featureReturns),
            subtitle: Text(l.featureReturnsBody),
          ),
          SwitchListTile(
            key: const ValueKey('feature-low-stock'),
            value: settings.lowStockOn,
            onChanged: controller.setLowStockOn,
            secondary: const Icon(Icons.shopping_basket_outlined),
            title: Text(l.featureLowStock),
            subtitle: Text(l.featureLowStockBody),
          ),
          const Divider(),
          _Section(l.dataSection),
          ListTile(
            leading: const Icon(Icons.slideshow_rounded),
            title: Text(l.showIntroAgain),
            onTap: () => controller.replayIntro(signedIn: ref.read(accountProvider).value != null),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
            title: Text(l.deleteAllData),
            onTap: () async {
              final ok = await confirm(context, title: l.deleteAllData, body: l.deleteAllBody, action: l.delete);
              if (!ok || !context.mounted) return;
              await ref.read(homeProvider.notifier).resetAll();
              if (context.mounted) showMessage(context, l.allDeleted);
            },
          ),
          const Divider(),
          _Section(l.about),
          ListTile(leading: const Icon(Icons.info_outline_rounded), title: Text(l.appTitle), subtitle: Text(l.version(appVersion))),
        ],
      ),
    );
  }
}

/// Switching on a dated feature asks the phone for notifications once.
Future<void> _askToNotify(BuildContext context, WidgetRef ref) async {
  final ok = await ref.read(remindersBackendProvider).allow();
  if (!ok && context.mounted) showMessage(context, AppLocalizations.of(context).notifyOff);
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final account = ref.watch(accountProvider).value;
    if (account == null) {
      return ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
        title: Text(l.accountGuest),
        subtitle: Text(l.accountGuestBody),
        trailing: FilledButton.tonal(
          onPressed: () async {
            final ok = await confirm(context, title: l.leaveGuest, body: l.leaveGuestBody, action: l.signIn);
            if (ok) await ref.read(settingsProvider.notifier).leaveGuest();
          },
          child: Text(l.signIn),
        ),
      );
    }
    final provider = switch (account.provider) {
      LoginProvider.kakao => l.providerKakao,
      LoginProvider.naver => l.providerNaver,
      LoginProvider.google => l.providerGoogle,
    };
    return ListTile(
      leading: CircleAvatar(
        foregroundImage: account.photoUrl == null ? null : NetworkImage(account.photoUrl!),
        child: const Icon(Icons.person_rounded),
      ),
      title: Text(account.name?.isNotEmpty == true ? account.name! : provider),
      subtitle: Text(l.accountWith(provider)),
      trailing: TextButton(
        onPressed: () async {
          final ok = await confirm(context, title: l.signOut, body: l.signOutBody, action: l.signOut);
          if (!ok) return;
          await ref.read(accountsProvider).signOut();
          if (context.mounted) showMessage(context, l.signedOut);
        },
        child: Text(l.signOut),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xs),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}
