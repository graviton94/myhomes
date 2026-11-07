// A new version on the store: found when the app opens, fetched in the
// background while the app is in use, installed by a restart (Google Play's
// flexible in-app update). The toast and Settings › 앱 정보 both read
// [appUpdateProvider].
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings.dart';

enum UpdatePhase {
  /// Not asked yet, or no answer.
  unknown,

  /// Installed from outside the store (the test APK): no way to know.
  notStore,

  /// This is the newest.
  latest,

  /// A new version is on the store, not fetched yet.
  available,

  /// Being fetched; see [UpdateState.progress].
  downloading,

  /// Fetched; a restart installs it.
  downloaded,

  /// The fetch stopped (no network, cancelled on the store's screen).
  failed,
}

class UpdateState {
  const UpdateState(this.phase, {this.progress = 0, this.code});

  final UpdatePhase phase;

  /// 0..1 while downloading.
  final double progress;

  /// The new version's code, to remember a "later" per version.
  final int? code;

  int get percent => (progress * 100).clamp(0, 100).round();

  /// Whether the store has something for this phone to do.
  bool get pending => phase == UpdatePhase.available || phase == UpdatePhase.downloading || phase == UpdatePhase.downloaded || phase == UpdatePhase.failed;
}

/// The store's side. [NoUpdates] off Android and in tests.
abstract class AppUpdater {
  Future<UpdateState> check();

  /// Opens the store's "update?" screen; true when the person said yes.
  Future<bool> start();

  /// Installs what was fetched; the app closes and opens again.
  Future<void> complete();

  /// Progress of a fetch already started.
  Stream<UpdateState> get changes;
}

class NoUpdates implements AppUpdater {
  const NoUpdates();

  @override
  Future<UpdateState> check() async => const UpdateState(UpdatePhase.notStore);

  @override
  Future<bool> start() async => false;

  @override
  Future<void> complete() async {}

  @override
  Stream<UpdateState> get changes => const Stream.empty();
}

/// Google Play through MainActivity's channel (homefairy/update).
class PlayUpdates implements AppUpdater {
  static const _methods = MethodChannel('homefairy/update');
  static const _events = EventChannel('homefairy/update/events');

  static UpdateState _read(Object? raw) {
    final m = (raw as Map?)?.cast<String, Object?>() ?? const {};
    final total = (m['total'] as num?)?.toDouble() ?? 0;
    final done = (m['downloaded'] as num?)?.toDouble() ?? 0;
    final phase = switch (m['phase']) {
      'notStore' => UpdatePhase.notStore,
      'latest' => UpdatePhase.latest,
      'available' => UpdatePhase.available,
      'downloading' => UpdatePhase.downloading,
      'downloaded' => UpdatePhase.downloaded,
      'failed' => UpdatePhase.failed,
      _ => UpdatePhase.unknown,
    };
    return UpdateState(phase, progress: total > 0 ? done / total : 0, code: (m['code'] as num?)?.toInt());
  }

  @override
  Future<UpdateState> check() async {
    try {
      return _read(await _methods.invokeMethod<Object?>('check'));
    } on PlatformException {
      return const UpdateState(UpdatePhase.unknown);
    }
  }

  @override
  Future<bool> start() async {
    try {
      return await _methods.invokeMethod<bool>('start') ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> complete() async {
    try {
      await _methods.invokeMethod<void>('complete');
    } on PlatformException {
      // Nothing to install after all; the next check says so.
    }
  }

  @override
  Stream<UpdateState> get changes => _events.receiveBroadcastStream().map(_read);
}

/// Overridden in main() with [PlayUpdates] on Android.
final appUpdaterProvider = Provider<AppUpdater>((ref) => const NoUpdates());

final appUpdateProvider = NotifierProvider<AppUpdateNotifier, UpdateState>(AppUpdateNotifier.new);

class AppUpdateNotifier extends Notifier<UpdateState> {
  StreamSubscription<UpdateState>? _sub;

  @override
  UpdateState build() {
    final updater = ref.watch(appUpdaterProvider);
    _sub = updater.changes.listen((s) => state = UpdateState(s.phase, progress: s.progress, code: s.code ?? state.code));
    ref.onDispose(() => _sub?.cancel());
    // Asked once when first read (the tabs or Settings), again on resume.
    Future.microtask(check);
    return const UpdateState(UpdatePhase.unknown);
  }

  /// On opening the app and on coming back to it.
  Future<void> check() async {
    final s = await ref.read(appUpdaterProvider).check();
    // A fetch under way reports through [changes]; don't step back to "available".
    if (state.phase == UpdatePhase.downloading && s.phase == UpdatePhase.available) return;
    state = s;
  }

  Future<void> start() async {
    final ok = await ref.read(appUpdaterProvider).start();
    if (ok && state.phase != UpdatePhase.downloaded) state = UpdateState(UpdatePhase.downloading, code: state.code);
  }

  Future<void> complete() => ref.read(appUpdaterProvider).complete();

  /// "나중에": the toast stays away for a day for this version.
  Future<void> later() async {
    final prefs = ref.read(prefsProvider);
    await prefs.setString('update.later', '${state.code ?? 0}:${DateTime.now().millisecondsSinceEpoch}');
    ref.notifyListeners();
  }

  /// Whether the toast should show now. A fetch under way or done always shows.
  bool get toastShown {
    switch (state.phase) {
      case UpdatePhase.downloading || UpdatePhase.downloaded:
        return true;
      case UpdatePhase.available || UpdatePhase.failed:
        final saved = ref.read(prefsProvider).getString('update.later')?.split(':');
        if (saved == null || saved.length != 2) return true;
        final sameVersion = int.tryParse(saved[0]) == (state.code ?? 0);
        final at = DateTime.fromMillisecondsSinceEpoch(int.tryParse(saved[1]) ?? 0);
        return !(sameVersion && DateTime.now().difference(at) < const Duration(days: 1));
      default:
        return false;
    }
  }
}
