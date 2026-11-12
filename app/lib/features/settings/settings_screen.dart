import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/accounts.dart';
import '../../data/app_update.dart';
import '../../data/backup.dart';
import '../../data/home_store.dart';
import '../../data/household.dart';
import '../../data/smart_suggest.dart';
import '../../data/reminders.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings.dart';
import '../../widgets/sheets.dart';
import '../../widgets/fit_text.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final inHome = ref.watch(householdProvider).value != null;

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
            subtitle: FitText(l.featureExpiryBody),
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
            subtitle: FitText(l.featureReturnsBody),
          ),
          SwitchListTile(
            key: const ValueKey('feature-low-stock'),
            value: settings.lowStockOn,
            onChanged: controller.setLowStockOn,
            secondary: const Icon(Icons.shopping_basket_outlined),
            title: Text(l.featureLowStock),
            subtitle: FitText(l.featureLowStockBody),
          ),
          SwitchListTile(
            key: const ValueKey('feature-family-alerts'),
            value: settings.familyAlertsOn && inHome,
            onChanged: inHome ? controller.setFamilyAlertsOn : null,
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(l.featureFamilyAlerts),
            subtitle: FitText(inHome ? l.featureFamilyAlertsBody : l.featureFamilyAlertsNeedsHome),
          ),
          if (inHome && settings.familyAlertsOn)
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 0, AppSpace.lg, AppSpace.sm),
              child: SegmentedButton<bool>(
                key: const ValueKey('family-alerts-when'),
                segments: [
                  ButtonSegment(value: false, label: Text(l.familyAlertsNow)),
                  ButtonSegment(value: true, label: Text(l.familyAlertsDaily)),
                ],
                selected: {settings.familyAlertsDaily},
                onSelectionChanged: (v) => controller.setFamilyAlertsDaily(v.first),
              ),
            ),
          const _CreditsTile(),
          const Divider(),
          _Section(l.dataSection),
          ListTile(
            key: const ValueKey('open-valuables'),
            leading: const Icon(Icons.verified_user_outlined),
            title: Text(l.valuablesTitle),
            onTap: () => context.push('/valuables'),
          ),
          ListTile(
            leading: const Icon(Icons.slideshow_rounded),
            title: Text(l.showIntroAgain),
            onTap: () => controller.replayIntro(signedIn: ref.read(accountProvider).value != null),
          ),
          ListTile(
            key: const ValueKey('backup-save'),
            leading: const Icon(Icons.save_alt_rounded),
            title: Text(l.backupSave),
            subtitle: FitText(l.backupSaveBody),
            onTap: () => saveBackup(context, ref),
          ),
          ListTile(
            key: const ValueKey('backup-restore'),
            leading: const Icon(Icons.restore_rounded),
            title: Text(l.backupRestore),
            onTap: () => restoreBackup(context, ref),
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
          if (ref.watch(accountProvider).value != null)
            ListTile(
              key: const ValueKey('delete-account'),
              leading: Icon(Icons.person_remove_outlined, color: Theme.of(context).colorScheme.error),
              title: Text(l.deleteAccount),
              onTap: () async {
                final ok = await confirm(context, title: l.deleteAccount, body: l.deleteAccountBody, action: l.delete);
                if (!ok || !context.mounted) return;
                try {
                  await ref.read(accountsProvider).deleteAccount();
                  if (context.mounted) showMessage(context, l.accountDeleted);
                } on LoginFailed {
                  if (context.mounted) showMessage(context, l.familyProblemOffline);
                }
              },
            ),
          const Divider(),
          _Section(l.about),
          const _VersionTile(),
          ListTile(
            key: const ValueKey('settings-plus'),
            leading: const Icon(Icons.auto_awesome_outlined),
            title: Text(l.settingsPlus),
            onTap: () => context.push('/plus'),
          ),
          // Straight to the developer's inbox: the app collects no usage numbers.
          ListTile(
            key: const ValueKey('settings-feedback'),
            leading: const Icon(Icons.mail_outline_rounded),
            title: Text(l.settingsFeedback),
            onTap: () => launchUrl(
              Uri(scheme: 'mailto', path: 'ruahn49@gmail.com', queryParameters: {'subject': 'Home Fairy $appVersion'}),
              mode: LaunchMode.externalApplication,
            ),
          ),
          // The studio site (graviton94.github.io/homefairy): the app's page and its privacy policy.
          ListTile(
            key: const ValueKey('settings-app-page'),
            leading: const Icon(Icons.public_rounded),
            title: Text(l.appPage),
            onTap: () => _openSite(context, ''),
          ),
          ListTile(
            key: const ValueKey('settings-privacy'),
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l.privacyPolicy),
            onTap: () => _openSite(context, 'privacy/'),
          ),
        ],
      ),
    );
  }
}

/// Saves the home (shared or this phone's) with its photos as a .homefairy
/// file and hands it to the share sheet (Drive, files, KakaoTalk to oneself).
Future<void> saveBackup(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final d = ref.read(homeProvider).requireValue;
  final dir = await getTemporaryDirectory();
  final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
  final dirPhotos = ref.read(photoDirProvider);
  final file = await Backup.write(
    d,
    File('${dir.path}/homefairy-$stamp.homefairy'),
    photoOf: (p) => PhotoCloud.current?.localFile(p) ?? (File(p).existsSync() ? File(p) : File('${dirPhotos.path}/${p.split('/').last}')),
  );
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/zip')],
      title: l.backupSave,
    ),
  );
}

/// Opens a .homefairy file. In our home it merges in; alone it replaces
/// this phone's things (with undo).
Future<void> restoreBackup(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final picked = await FilePicker.pickFile();
  final path = picked?.path;
  if (path == null || !context.mounted) return;
  final HomeData backup;
  try {
    backup = await Backup.read(File(path), ref.read(photoDirProvider));
  } on FormatException {
    if (context.mounted) showMessage(context, l.backupNotOne);
    return;
  }
  if (!context.mounted) return;
  final inHome = ref.read(householdProvider).value != null;
  final ok = await confirm(
    context,
    title: l.backupRestore,
    body: inHome ? l.backupMergeBody(backup.spaces.length, backup.items.length) : l.backupReplaceBody(backup.spaces.length, backup.items.length),
    action: inHome ? l.familyMergeAction : l.backupReplace,
  );
  if (!ok || !context.mounted) return;
  if (inHome) {
    await ref.read(homeProvider.notifier).apply<int>((d, ctx) => mergeHome(d, backup, ctx));
  } else {
    await ref.read(homeProvider.notifier).replacePhoneData(backup);
  }
  if (context.mounted) showUndo(context, ref, l.backupRestored(backup.items.length));
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
        subtitle: FitText(l.accountGuestBody),
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
      leading: CircleAvatar(foregroundImage: account.photoUrl == null ? null : NetworkImage(account.photoUrl!), child: const Icon(Icons.person_rounded)),
      title: Text(account.name?.isNotEmpty == true ? account.name! : provider),
      subtitle: FitText(l.accountWith(provider)),
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

/// This month's fairy credits (AI search and suggestions), from the server.
class _CreditsTile extends ConsumerWidget {
  const _CreditsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final credits = ref.watch(creditsProvider).value;
    if (credits == null) return const SizedBox.shrink();
    final left = (credits.limit - credits.used).clamp(0, credits.limit);
    return ListTile(
      key: const ValueKey('fairy-credits'),
      leading: const Icon(Icons.auto_awesome_outlined),
      title: Text(l.creditsTitle),
      subtitle: FitText(l.creditsBody(left, credits.limit)),
    );
  }
}

/// Refreshed each time Settings opens.

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

/// A page of the app on the studio site, in the app's language.
Future<void> _openSite(BuildContext context, String path) async {
  final en = Localizations.localeOf(context).languageCode != 'ko';
  await launchUrl(Uri.parse('$siteUrl$path${en ? '#en' : ''}'), mode: LaunchMode.externalApplication);
}

/// The app's page on the studio site.
const siteUrl = 'https://graviton94.github.io/homefairy/';

/// 앱 정보: this version and the store's: up to date, a new one (받기), how
/// much is fetched, or 다시 시작해서 설치. Also there after the toast is closed.
class _VersionTile extends ConsumerWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final s = ref.watch(appUpdateProvider);
    final update = ref.read(appUpdateProvider.notifier);
    final muted = AppType.caption.copyWith(color: c.mutedFg);
    Widget pill(String text, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        text,
        style: AppType.caption.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
    final badge = switch (s.phase) {
      UpdatePhase.latest => pill(l.updateLatest, c.secondarySoft, c.secondaryInk),
      UpdatePhase.available || UpdatePhase.downloading || UpdatePhase.downloaded || UpdatePhase.failed => pill(l.updateNew, c.primarySoft, c.primaryInk),
      _ => null,
    };
    return Padding(
      key: const ValueKey('settings-version'),
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: c.mutedFg),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OneLine([l.appTitle], style: AppType.body),
                    OneLine([l.version(appVersion)], style: muted),
                  ],
                ),
              ),
              ?badge,
            ],
          ),
          if (s.phase == UpdatePhase.notStore) ...[
            const SizedBox(height: AppSpace.xs),
            Padding(
              padding: const EdgeInsets.only(left: 24 + AppSpace.lg),
              child: FitText(l.updateNotStore, style: muted),
            ),
          ],
          if (s.phase == UpdatePhase.downloading || s.phase == UpdatePhase.downloaded) ...[
            const SizedBox(height: AppSpace.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: s.phase == UpdatePhase.downloaded ? 1 : (s.progress > 0 ? s.progress : null),
                minHeight: 8,
                color: c.primary,
                backgroundColor: c.border,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            OneLine([
              s.phase == UpdatePhase.downloaded ? l.updateDownloaded : l.updateDownloading(s.percent),
              if (s.phase == UpdatePhase.downloading) l.updateDownloadingShort(s.percent),
            ], style: muted),
          ],
          if (s.phase == UpdatePhase.available || s.phase == UpdatePhase.failed || s.phase == UpdatePhase.downloaded) ...[
            const SizedBox(height: AppSpace.sm),
            FilledButton(
              key: const ValueKey('settings-update'),
              onPressed: s.phase == UpdatePhase.downloaded ? update.complete : update.start,
              child: OneLine([
                switch (s.phase) {
                  UpdatePhase.downloaded => l.updateRestartInstall,
                  UpdatePhase.failed => l.updateRetry,
                  _ => l.updateGet,
                },
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
