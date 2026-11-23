import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../settings/settings.dart';
import 'accounts.dart';
import 'backup.dart';
import 'home_store.dart';
import 'household.dart';
import 'problems.dart';

/// What an account's backup holds, without fetching it.
class BackupInfo {
  const BackupInfo({required this.savedAt, required this.rooms, required this.spots, required this.items});

  final DateTime savedAt;
  final int rooms, spots, items;
}

/// The home kept with a signed-in account (user request: a new phone, a
/// reinstall or signing in again brings the home back). Guests keep
/// everything on the phone only; nothing is kept for them on the server.
abstract class AccountBackups {
  Future<BackupInfo?> info(String uid);
  Future<void> save(String uid, HomeData d);

  /// The backed-up home, null when there is none.
  Future<HomeData?> load(String uid);

  /// Brings the backup's photos onto this phone; returns [d] pointing at them.
  Future<HomeData> fetchPhotos(String uid, HomeData d) async => d;
}

class NoAccountBackups extends AccountBackups {
  @override
  Future<BackupInfo?> info(String uid) async => null;
  @override
  Future<void> save(String uid, HomeData d) async {}
  @override
  Future<HomeData?> load(String uid) async => null;
}

/// Firestore backups/{uid}: the home as gzip JSON (the history trimmed to
/// recent entries) and backups/{uid}/photos the small pictures, as in a
/// shared home. Only that account can read or write it (firestore.rules).
class FirebaseAccountBackups extends AccountBackups {
  FirebaseAccountBackups(this._db, this.photoDir);

  final FirebaseFirestore _db;
  final Directory photoDir;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db.collection('backups').doc(uid);
  PhotoCloud _photos(String uid) => PhotoCloud(_doc(uid).collection('photos'), photoDir);

  @override
  Future<BackupInfo?> info(String uid) async {
    final snap = await _doc(uid).get(const GetOptions(source: Source.server));
    final m = snap.data();
    if (m == null) return null;
    return BackupInfo(
      savedAt: (m['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rooms: (m['rooms'] as num?)?.toInt() ?? 0,
      spots: (m['spots'] as num?)?.toInt() ?? 0,
      items: (m['items'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> save(String uid, HomeData d) async {
    var keep = 300;
    var bytes = packBackup(d, keep);
    while (bytes.length > 800 * 1024 && keep > 0) {
      keep ~/= 3;
      bytes = packBackup(d, keep);
    }
    await _doc(uid).set({
      'data': Blob(bytes),
      'savedAt': FieldValue.serverTimestamp(),
      'rooms': d.spaces.length,
      'spots': d.containers.length,
      'items': d.items.length,
    });
    await _photos(uid).uploadAll(d);
  }

  @override
  Future<HomeData?> load(String uid) async {
    final m = (await _doc(uid).get(const GetOptions(source: Source.server))).data();
    final data = m?['data'];
    return data is Blob ? unpackBackup(data.bytes) : null;
  }

  @override
  Future<HomeData> fetchPhotos(String uid, HomeData d) async {
    final cloud = _photos(uid);
    for (final p in photoPathsOf(d)) {
      await cloud.fetch(p);
    }
    return Backup.pointPhotosAt(d, photoDir);
  }
}

/// The home as gzip JSON, with only the newest [keepLog] history entries.
Uint8List packBackup(HomeData d, int keepLog) =>
    Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(d.copyWith(log: d.log.take(keepLog).toList()).toJson()))));

HomeData unpackBackup(List<int> bytes) => HomeData.fromJson(jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, Object?>);

/// Overridden in main() when Firebase is available.
final accountBackupsProvider = Provider<AccountBackups>((ref) => NoAccountBackups());

/// What the person picked when the phone and the account each had a home.
enum BackupChoice { account, phone, both }

abstract final class BackupPrefs {
  /// The account this phone's home is backed up to.
  static const uid = 'backup.uid';
  static const at = 'backup.at';
  static const hash = 'backup.hash';
}

/// A short fingerprint of what the backup holds (not the history).
String homeFingerprint(HomeData home) {
  // Through JSON once, so a home and its saved copy read the same.
  final d = HomeData.fromJson(jsonDecode(jsonEncode(home.toJson())) as Map<String, Object?>);
  final s = jsonEncode([for (final x in d.spaces) x.toJson(), for (final x in d.containers) x.toJson(), for (final x in d.items) x.toJson()]);
  var h = 0xcbf29ce484222325;
  for (final b in utf8.encode(s)) {
    h = ((h ^ b) * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return h.toUnsigned(64).toRadixString(16);
}

bool _emptyHome(HomeData d) => d.spaces.isEmpty && d.containers.isEmpty && d.items.isEmpty;

/// When the backup was last saved (null: never, or not signed in).
class BackupSavedAt extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final uid = ref.watch(accountProvider.select((a) => a.value?.uid)) ?? '';
    final prefs = ref.read(prefsProvider);
    if (uid.isEmpty || prefs.getString(BackupPrefs.uid) != uid) return null;
    final ms = prefs.getInt(BackupPrefs.at);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Saves [d] to the signed-in account now (no-op when already saved).
  Future<bool> save(HomeData d, {bool force = false}) async {
    final uid = ref.read(accountProvider).value?.uid ?? '';
    if (uid.isEmpty) return false;
    final prefs = ref.read(prefsProvider);
    final hash = homeFingerprint(d);
    if (!force && prefs.getString(BackupPrefs.uid) == uid && prefs.getString(BackupPrefs.hash) == hash) return true;
    try {
      await ref.read(accountBackupsProvider).save(uid, d);
      final now = DateTime.now();
      await prefs.setString(BackupPrefs.uid, uid);
      await prefs.setString(BackupPrefs.hash, hash);
      await prefs.setInt(BackupPrefs.at, now.millisecondsSinceEpoch);
      if (ref.mounted) state = now;
      return true;
    } catch (e) {
      reportProblem('account backup', e);
      return false;
    }
  }
}

final backupSavedAtProvider = NotifierProvider<BackupSavedAt, DateTime?>(BackupSavedAt.new);

/// Saves the phone's home to the account a few seconds after it changes,
/// once this phone is linked to the account. A shared home is already on
/// the server, so nothing is saved while in one.
final accountBackupSyncProvider = Provider<void>((ref) {
  final uid = ref.watch(accountProvider.select((a) => a.value?.uid)) ?? '';
  final inFamily = ref.watch(householdProvider.select((h) => h.value != null));
  final home = ref.watch(homeProvider).value;
  if (uid.isEmpty || inFamily || home == null) return;
  if (ref.read(prefsProvider).getString(BackupPrefs.uid) != uid) return;
  final timer = Timer(const Duration(seconds: 5), () => ref.read(backupSavedAtProvider.notifier).save(home));
  ref.onDispose(timer.cancel);
});

/// Links this phone to the signed-in account's backup, once per account:
/// no backup yet → this phone's home becomes it; an empty phone → the
/// backup comes back; both with a home → [ask] which to keep.
/// Returns false when it could not finish (offline), to try again later.
Future<bool> linkAccountBackup(T Function<T>(ProviderListenable<T>) read, Future<BackupChoice?> Function(BackupInfo saved, HomeData phone) ask) =>
    _linking ??= _link(read, ask).whenComplete(() => _linking = null);

// One link at a time: signing in starts it from the login screen and the
// tabs both, and the second waits for the first.
Future<bool>? _linking;

Future<bool> _link(T Function<T>(ProviderListenable<T>) read, Future<BackupChoice?> Function(BackupInfo saved, HomeData phone) ask) async {
  final uid = read(accountProvider).value?.uid ?? '';
  final prefs = read(prefsProvider);
  if (uid.isEmpty || prefs.getString(BackupPrefs.uid) == uid) return true;
  try {
    if (await read(householdProvider.future) != null) return true;
    final backups = read(accountBackupsProvider);
    final home = read(homeProvider.notifier);
    final saver = read(backupSavedAtProvider.notifier);
    final phone = await home.phoneData();
    final info = await backups.info(uid);
    final saved = info == null ? null : await backups.load(uid);
    if (saved == null) return await saver.save(phone, force: true);
    if (homeFingerprint(saved) == homeFingerprint(phone)) return await saver.save(phone);
    BackupChoice? choice = BackupChoice.account;
    if (!_emptyHome(phone)) choice = await ask(info!, phone);
    if (choice == null) return true; // asked again next time
    switch (choice) {
      case BackupChoice.phone:
        return await saver.save(phone, force: true);
      case BackupChoice.account:
        final restored = await backups.fetchPhotos(uid, saved);
        await home.replacePhoneData(restored);
        return await saver.save(restored, force: true);
      case BackupChoice.both:
        final restored = await backups.fetchPhotos(uid, saved);
        final merged = mergeHome(phone, restored, read(ctxProvider)).data;
        await home.replacePhoneData(merged);
        return await saver.save(merged, force: true);
    }
  } catch (e) {
    debugPrint('backup link: ${e.runtimeType}');
    return false;
  }
}
