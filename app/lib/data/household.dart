import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../settings/settings.dart';
import 'accounts.dart';
import 'home_store.dart';

/// Someone in a shared home.
class Member {
  const Member(this.uid, this.name, this.photoUrl);

  final String uid;
  final String? name;
  final String? photoUrl;
}

/// A shared home ("우리 집"): who is in it and how many may be.
class Household {
  const Household({required this.id, required this.name, required this.owner, required this.members, required this.limit});

  final String id;
  final String name;
  final String? owner;
  final List<Member> members;

  /// Free homes hold 2 people.
  final int limit;

  bool get full => members.length >= limit;

  Member? member(String? uid) => members.where((m) => m.uid == uid).firstOrNull;
}

/// Why a shared-home action failed, for the message on screen.
enum HouseholdProblem { full, notFound, alreadyInHome, offline, other }

class HouseholdFailed implements Exception {
  const HouseholdFailed(this.problem);

  final HouseholdProblem problem;

  @override
  String toString() => 'HouseholdFailed($problem)';
}

/// Saved / sending / no connection, shown in the header in a shared home.
enum SyncState { saved, saving, offline }

abstract class Households {
  /// The home [uid] is in, or null.
  Stream<Household?> watch(String uid);

  /// Makes a home with the caller in it and puts [upload] into it.
  Future<void> create(String name, {HomeData? upload});

  /// A 6-digit code someone can join with for the next 24 hours.
  Future<({String code, DateTime expires})> invite();

  Future<void> join(String code, {bool leaveCurrent = false});

  Future<void> leave();

  /// Family alerts: other members' changes arrive as phone notifications.
  Future<void> setAlerts({required bool on, required String lang});

  /// The home's documents as the app's data.
  HomeRepository repository(String homeId);
}

/// Builds without Firebase (tests, local runs): nobody shares a home.
class NoHouseholds implements Households {
  const NoHouseholds();

  @override
  Stream<Household?> watch(String uid) => Stream.value(null);

  @override
  Future<void> create(String name, {HomeData? upload}) async => throw const HouseholdFailed(HouseholdProblem.offline);

  @override
  Future<({String code, DateTime expires})> invite() async => throw const HouseholdFailed(HouseholdProblem.offline);

  @override
  Future<void> join(String code, {bool leaveCurrent = false}) async => throw const HouseholdFailed(HouseholdProblem.offline);

  @override
  Future<void> leave() async {}

  @override
  Future<void> setAlerts({required bool on, required String lang}) async {}

  @override
  HomeRepository repository(String homeId) => MemoryHomeRepository();
}

/// Membership through the `household` Cloud Function; contents straight
/// from Firestore (rules let members read and write their home).
class FirebaseHouseholds implements Households {
  FirebaseHouseholds({required this.photoDir});

  final Directory photoDir;
  final _db = FirebaseFirestore.instance;
  final _fn = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('household');

  @override
  Stream<Household?> watch(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .asyncExpand((u) {
          final homeId = u.data()?['homeId'] as String?;
          if (homeId == null) return Stream<Household?>.value(null);
          return _db.collection('homes').doc(homeId).snapshots().map((h) {
            final d = h.data();
            if (d == null) return null;
            final people = (d['people'] as Map?) ?? const {};
            return Household(
              id: h.id,
              name: (d['name'] as String?) ?? '',
              owner: d['owner'] as String?,
              limit: (d['limit'] as num?)?.toInt() ?? 2,
              members: [
                for (final m in (d['members'] as List? ?? const []).cast<String>())
                  Member(m, (people[m] as Map?)?['name'] as String?, (people[m] as Map?)?['photo'] as String?),
              ],
            );
          });
        })
        .handleError((Object e) => debugPrint('household watch: ${e.runtimeType}'));
  }

  Future<Map> _call(Map<String, Object?> data) async {
    try {
      final r = await _fn.call<Object?>(data).timeout(const Duration(seconds: 30));
      return (r.data as Map?) ?? const {};
    } on FirebaseFunctionsException catch (e) {
      throw HouseholdFailed(switch (e.code) {
        'resource-exhausted' => HouseholdProblem.full,
        'not-found' => HouseholdProblem.notFound,
        'already-exists' => HouseholdProblem.alreadyInHome,
        'unavailable' || 'deadline-exceeded' => HouseholdProblem.offline,
        _ => HouseholdProblem.other,
      });
    } on TimeoutException {
      throw const HouseholdFailed(HouseholdProblem.offline);
    }
  }

  @override
  Future<void> create(String name, {HomeData? upload}) async {
    final r = await _call({'action': 'create', 'name': name});
    final homeId = r['homeId'] as String;
    if (upload != null) await CloudHomeRepository(_db, homeId, photoDir).upload(upload);
  }

  @override
  Future<({String code, DateTime expires})> invite() async {
    final r = await _call({'action': 'invite'});
    return (code: r['code'] as String, expires: DateTime.parse(r['expires'] as String).toLocal());
  }

  @override
  Future<void> join(String code, {bool leaveCurrent = false}) => _call({'action': 'join', 'code': code, 'leaveCurrent': leaveCurrent});

  @override
  Future<void> leave() => _call({'action': 'leave'});

  @override
  Future<void> setAlerts({required bool on, required String lang}) async {
    String? token;
    if (on) {
      final m = FirebaseMessaging.instance;
      await m.requestPermission();
      // Registration tokens still work with the Admin SDK's send(); the newer
      // installation-id flow (register/onRegistered) needs a server change first.
      // ignore: deprecated_member_use
      token = await m.getToken();
      // ignore: deprecated_member_use
      _tokenSub ??= m.onTokenRefresh.listen((t) => _call({'action': 'alerts', 'on': true, 'token': t, 'lang': lang}));
    }
    await _call({'action': 'alerts', 'on': on, 'token': token, 'lang': lang});
  }

  StreamSubscription<String>? _tokenSub;

  /// Tells the family what just changed (the server skips members with alerts off).
  Future<void> _notify(Map<String, Object?> change) async {
    try {
      await _call({'action': 'notify', ...change});
    } catch (e) {
      debugPrint('notify: $e');
    }
  }

  @override
  HomeRepository repository(String homeId) => CloudHomeRepository(_db, homeId, photoDir, onLogged: _notify);
}

/// A shared home's documents (core sync.dart) kept live. Firestore keeps a
/// copy on the phone, so it works offline and sends changes when it can.
class CloudHomeRepository extends HomeRepository {
  CloudHomeRepository(this._db, this.homeId, this.photoDir, {this.onLogged}) {
    PhotoCloud.current = PhotoCloud(_home.collection('photos'), photoDir);
  }

  final FirebaseFirestore _db;
  final String homeId;
  final Directory photoDir;

  /// Called a moment after changes settle with what changed (for family alerts).
  final Future<void> Function(Map<String, Object?> change)? onLogged;
  Timer? _settle;

  DocumentReference<Map<String, dynamic>> get _home => _db.collection('homes').doc(homeId);

  final _docs = {for (final s in Shelf.values) s: <String, Map<String, Object?>>{}};
  final _pending = <Shelf>{};
  final _cached = <Shelf>{};
  final _seen = <Shelf>{};
  final _subs = <StreamSubscription<Object?>>[];
  final _first = Completer<void>();
  final _out = StreamController<HomeData>.broadcast();
  HomeData _last = const HomeData();
  int _orderSeq = 0;

  /// Saved / sending / offline, for the header.
  final sync = ValueNotifier(SyncState.saved);

  static const _logShown = 60;

  Query<Map<String, dynamic>> _query(Shelf s) {
    final c = _home.collection(s.name);
    return s == Shelf.log ? c.orderBy('at', descending: true).limit(_logShown) : c;
  }

  void _start() {
    if (_subs.isNotEmpty) return;
    for (final s in Shelf.values) {
      _subs.add(
        _query(s)
            .snapshots(includeMetadataChanges: true)
            .listen(
              (q) {
                _docs[s] = {
                  for (final d in q.docs) d.id: {...d.data(), 'id': d.id},
                };
                q.metadata.hasPendingWrites ? _pending.add(s) : _pending.remove(s);
                q.metadata.isFromCache ? _cached.add(s) : _cached.remove(s);
                _seen.add(s);
                sync.value = _pending.isNotEmpty
                    ? SyncState.saving
                    : _cached.length == Shelf.values.length
                    ? SyncState.offline
                    : SyncState.saved;
                if (_seen.length < Shelf.values.length) return;
                _last = _compose();
                if (!_first.isCompleted) {
                  _first.complete();
                } else {
                  _out.add(_last);
                }
              },
              onError: (Object e) {
                debugPrint('home sync ${s.name}: ${e.runtimeType}');
                if (!_first.isCompleted) _first.completeError(e);
              },
            ),
      );
    }
  }

  HomeData _compose() => homeFromDocs(
    spaces: _docs[Shelf.spaces]!.values,
    containers: _docs[Shelf.containers]!.values,
    items: _docs[Shelf.items]!.values,
    log: _docs[Shelf.log]!.values,
  );

  @override
  Stream<HomeData> get remote => _out.stream;

  @override
  Future<HomeData> load() async {
    _start();
    await _first.future;
    return _last;
  }

  @override
  Future<void> save(HomeData data) async {
    final writes = diffHome(_last, data);
    _last = data;
    _write(writes);
    final logged = writes.where((w) => w.shelf == Shelf.log).toList();
    if (onLogged != null && logged.isNotEmpty) {
      final by = logged.last.data?['by'];
      _settle?.cancel();
      _settle = Timer(const Duration(seconds: 3), () {
        final c = lastChange(_last);
        if (c == null || c.by != by) return; // a family change arrived meanwhile
        final where = c.containerId == null ? const <String>[] : _last.pathOf(c.containerId!);
        onLogged!({'type': c.type.name, 'names': c.names, 'place': where.join(' › ')});
      });
    }
  }

  /// Puts a whole home (the phone's data) in, waiting until the server has it.
  Future<void> upload(HomeData data) async {
    await Future.wait(_write(uploadHome(data)));
    await PhotoCloud(_home.collection('photos'), photoDir).uploadAll(data);
  }

  /// Writes in batches. Offline, Firestore keeps them and sends them later,
  /// so callers that only change data do not wait.
  List<Future<void>> _write(List<DocWrite> writes) {
    final out = <Future<void>>[];
    final base = DateTime.now().microsecondsSinceEpoch;
    for (var i = 0; i < writes.length; i += 400) {
      final batch = _db.batch();
      for (final w in writes.skip(i).take(400)) {
        final ref = _home.collection(w.shelf.name).doc(w.id);
        final data = w.data;
        if (data == null) {
          batch.delete(ref);
        } else {
          final order = _docs[w.shelf]![w.id]?[orderField] ?? base + _orderSeq++;
          batch.set(ref, {...data, orderField: order});
        }
      }
      out.add(batch.commit().catchError((Object e) => debugPrint('home write: ${e.runtimeType}')));
    }
    final photos = PhotoCloud.current;
    for (final w in writes) {
      final p = w.data?['photoPath'];
      if (p is String) photos?.upload(p);
    }
    return out;
  }

  @override
  void dispose() {
    _settle?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _out.close();
    if (PhotoCloud.current?.owner == _home.path) PhotoCloud.current = null;
  }
}

/// Photos in a shared home: each one a Firestore document
/// (photos/{file name}) holding the small WebP and its thumbnail, about
/// 30 KB together. Phones keep their copies in the photo folder.
class PhotoCloud {
  PhotoCloud(this._col, this.dir);

  final CollectionReference<Map<String, dynamic>> _col;
  final Directory dir;
  final _busy = <String, Future<File?>>{};
  final _sent = <String>{};

  /// The shared home's photos while the person is in one.
  static PhotoCloud? current;

  String get owner => _col.parent!.path;

  static String nameOf(String path) => path.split('/').last;

  /// Our copy of a photo, wherever it was taken.
  File localFile(String path) {
    final f = File(path);
    return f.existsSync() ? f : File('${dir.path}/${nameOf(path)}');
  }

  /// Sends a photo taken on this phone, once.
  Future<void> upload(String path) async {
    final name = nameOf(path);
    if (!_sent.add(name)) return;
    try {
      final f = File(path);
      if (!f.existsSync()) return;
      final existing = await _col.doc(name).get(const GetOptions(source: Source.serverAndCache));
      if (existing.exists) return;
      final thumb = File(path.replaceFirst(RegExp(r'\.webp$'), '_t.webp'));
      final bytes = await f.readAsBytes();
      if (bytes.length > 900 * 1024) return; // older large photos stay on the phone
      await _col.doc(name).set({
        'data': Blob(bytes),
        if (path.endsWith('.webp') && thumb.existsSync()) 'thumb': Blob(await thumb.readAsBytes()),
      });
    } catch (e) {
      _sent.remove(name);
      debugPrint('photo upload: ${e.runtimeType}');
    }
  }

  Future<void> uploadAll(HomeData d) async {
    final paths = [
      for (final s in d.spaces) ?s.photoPath,
      for (final c in d.containers) ?c.photoPath,
      for (final i in d.items) ?i.photoPath,
    ];
    for (final p in paths) {
      await upload(p);
    }
  }

  /// Fetches a photo someone else took; null when there is none.
  Future<File?> fetch(String path) => _busy[nameOf(path)] ??= () async {
    final name = nameOf(path);
    final target = File('${dir.path}/$name');
    if (target.existsSync()) return target;
    try {
      final snap = await _col.doc(name).get();
      final data = snap.data();
      if (data == null) return null;
      await dir.create(recursive: true);
      await target.writeAsBytes((data['data'] as Blob).bytes, flush: true);
      final thumb = data['thumb'];
      if (thumb is Blob) await File(target.path.replaceFirst(RegExp(r'\.webp$'), '_t.webp')).writeAsBytes(thumb.bytes);
      return target;
    } catch (e) {
      _busy.remove(name);
      debugPrint('photo fetch: ${e.runtimeType}');
      return null;
    }
  }();
}

/// Overridden in main() when Firebase is available.
final householdsProvider = Provider<Households>((ref) => const NoHouseholds());

/// The shared home the signed-in person is in, or null (guests, alone).
final householdProvider = StreamProvider<Household?>((ref) {
  final uid = ref.watch(accountProvider.select((a) => a.value?.uid));
  if (uid == null || uid.isEmpty) return Stream.value(null);
  return ref.watch(householdsProvider).watch(uid);
});

/// The shared home's data while in one; the phone's otherwise.
final householdRepositoryProvider = Provider<HomeRepository>((ref) {
  final homeId = ref.watch(householdProvider.select((h) => h.value?.id));
  if (homeId == null) return ref.watch(homeRepositoryProvider);
  final repo = ref.watch(householdsProvider).repository(homeId);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Saved / sending / offline while in a shared home; null otherwise.
final syncStateProvider = StreamProvider<SyncState?>((ref) {
  final repo = ref.watch(activeRepositoryProvider);
  if (repo is! CloudHomeRepository) return Stream.value(null);
  final out = StreamController<SyncState?>();
  void push() => out.add(repo.sync.value);
  repo.sync.addListener(push);
  push();
  ref.onDispose(() {
    repo.sync.removeListener(push);
    out.close();
  });
  return out.stream;
});

/// Keeps the server's family-alert setting in step with Settings, the home
/// and the language. Watched once by the app.
final familyAlertSyncProvider = Provider<void>((ref) {
  final on = ref.watch(settingsProvider.select((s) => s.familyAlertsOn));
  final homeId = ref.watch(householdProvider.select((h) => h.value?.id));
  final lang =
      ref.watch(settingsProvider.select((s) => s.language.locale?.languageCode)) ?? PlatformDispatcher.instance.locale.languageCode;
  if (homeId == null) return;
  ref.read(householdsProvider).setAlerts(on: on, lang: lang).catchError((Object e) => debugPrint('alerts: $e'));
});

/// Overrides that switch the app to the shared home while signed in to one.
final householdOverrides = [
  activeRepositoryProvider.overrideWith((ref) => ref.watch(householdRepositoryProvider)),
  changeByProvider.overrideWith(
    (ref) => ref.watch(householdProvider.select((h) => h.value?.id)) == null ? null : ref.watch(accountProvider).value?.uid,
  ),
];
