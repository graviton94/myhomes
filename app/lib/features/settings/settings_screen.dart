import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/home_store.dart';
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
          _Section(l.dataSection),
          ListTile(
            leading: const Icon(Icons.slideshow_rounded),
            title: Text(l.showIntroAgain),
            onTap: () => controller.setIntroSeen(false),
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
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.designSample),
            subtitle: Text(l.designSampleBody),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/settings/design'),
          ),
          ListTile(leading: const Icon(Icons.info_outline_rounded), title: Text(l.appTitle), subtitle: Text(l.version(appVersion))),
        ],
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
