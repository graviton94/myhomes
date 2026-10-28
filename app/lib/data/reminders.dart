import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import '../widgets/keep_words.dart';
import 'home_store.dart';

/// Phone notifications for the add-on features (use-by and return dates).
abstract interface class Reminders {
  /// Asks the phone for permission to notify. False when refused.
  Future<bool> allow();

  /// Replaces every scheduled notification with [list].
  Future<void> replace(List<Reminder> list, AppLocalizations l);
}

/// Tests and builds without the plugin: nothing is scheduled.
class NoReminders implements Reminders {
  const NoReminders();

  @override
  Future<bool> allow() async => true;

  @override
  Future<void> replace(List<Reminder> list, AppLocalizations l) async {}
}

/// Android notifications at 9 in the morning, scheduled ahead (they survive
/// a restart). Inexact alarms: the phone may deliver a few minutes late,
/// which needs no special alarm permission.
class PhoneReminders implements Reminders {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  Future<void> _init() => _ready ??= () async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_fairy')));
  }();

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> allow() async {
    await _init();
    return await _android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<void> replace(List<Reminder> list, AppLocalizations l) async {
    await _init();
    await _plugin.cancelAllPendingNotifications();
    // The channel family alerts (sent by the server) arrive on.
    await _android?.createNotificationChannel(
      AndroidNotificationChannel(
        'family',
        l.notifyFamilyChannel,
        description: l.notifyFamilyChannelBody,
        importance: Importance.defaultImportance,
      ),
    );
    final details = NotificationDetails(
      android: AndroidNotificationDetails('dates', l.notifyChannel, channelDescription: l.notifyChannelBody),
    );
    for (final r in list) {
      final (title, body) = switch (r.kind) {
        ReminderKind.expiry => (r.name, l.notifyExpiry(r.daysLeft)),
        ReminderKind.returnBy => (r.name, l.notifyReturn(r.daysLeft)),
      };
      await _plugin.zonedSchedule(
        id: r.id,
        // The instant is what counts; UTC needs no zone lookup on the phone.
        scheduledDate: tz.TZDateTime.from(r.at, tz.UTC),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
    }
  }
}

/// Overridden in main() with [PhoneReminders] on Android.
final remindersBackendProvider = Provider<Reminders>((ref) => const NoReminders());

/// Keeps the scheduled notifications in step with the home data and the
/// feature switches. Watched once by the app.
final reminderSyncProvider = Provider<void>((ref) {
  final settings = ref.watch(settingsProvider);
  final home = ref.watch(homeProvider).value;
  if (home == null) return;
  final backend = ref.read(remindersBackendProvider);
  if (backend is NoReminders) return;
  final locale = settings.language.locale ?? PlatformDispatcher.instance.locale;
  final l = localizationsFor(
    AppLocalizations.supportedLocales.contains(Locale(locale.languageCode)) ? Locale(locale.languageCode) : const Locale('en'),
  );
  // Saves come in bursts; schedule once they settle.
  final timer = Timer(const Duration(seconds: 2), () {
    final list = remindersFrom(home, DateTime.now(), expiry: settings.expiryOn, returns: settings.returnsOn);
    backend.replace(list, l).catchError((Object e) => debugPrint('reminders: ${e.runtimeType}'));
  });
  ref.onDispose(timer.cancel);
});
