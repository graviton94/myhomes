import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

/// Where the household data lives: one JSON file on the phone, or a shared
/// home in Firestore (data/household.dart) while the person is in one.
abstract class HomeRepository {
  Future<HomeData> load();
  Future<void> save(HomeData data);

  /// Changes made elsewhere (family phones), after [load].
  Stream<HomeData> get remote => const Stream.empty();

  /// The log entries of one month; null when [HomeData.log] holds them all.
  Future<List<LogEntry>?> monthLog(int year, int month) async => null;

  /// Stops listening; called when another repository takes over.
  void dispose() {}
}

/// One JSON file, written atomically (temp file + rename).
class FileHomeRepository extends HomeRepository {
  FileHomeRepository(this.dir);

  final Directory dir;
  File get _file => File('${dir.path}/home.json');

  @override
  Future<HomeData> load() async {
    if (!await _file.exists()) return const HomeData();
    try {
      return HomeData.fromJson(jsonDecode(await _file.readAsString()) as Map<String, Object?>);
    } on FormatException {
      // Keep the unreadable file for recovery and start fresh.
      await _file.rename('${_file.path}.broken-${DateTime.now().millisecondsSinceEpoch}');
      return const HomeData();
    }
  }

  @override
  Future<void> save(HomeData data) async {
    await dir.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(data.toJson()), flush: true);
    await tmp.rename(_file.path);
  }
}

class MemoryHomeRepository extends HomeRepository {
  MemoryHomeRepository([this.data = const HomeData()]);

  HomeData data;

  @override
  Future<HomeData> load() async => data;

  @override
  Future<void> save(HomeData data) async => this.data = data;
}

/// The phone's own data. Overridden in main().
final homeRepositoryProvider = Provider<HomeRepository>((ref) => throw UnimplementedError('homeRepositoryProvider not overridden'));

/// Where the data lives right now: the shared home when the person is in
/// one, otherwise the phone. Overridden by data/household.dart's provider.
final activeRepositoryProvider = Provider<HomeRepository>((ref) => ref.watch(homeRepositoryProvider));

/// Member uid recorded on changes in a shared home.
final changeByProvider = Provider<String?>((ref) => null);

/// Folder for item and space photos. Overridden in main().
final photoDirProvider = Provider<Directory>((ref) => Directory.systemTemp);

/// Minimum time before the data counts as loaded (tests set zero).
final splashDelayProvider = Provider<Duration>((ref) => const Duration(milliseconds: 300));

/// The start screen was tapped through. Starts true when [splashDelayProvider]
/// is zero, so tests go straight in.
class SplashDone extends Notifier<bool> {
  @override
  bool build() => ref.read(splashDelayProvider) == Duration.zero;

  void done() => state = true;
}

final splashDoneProvider = NotifierProvider<SplashDone, bool>(SplashDone.new);

final _random = Random.secure();
String _newId() => List.generate(8, (_) => _random.nextInt(1 << 16).toRadixString(16).padLeft(4, '0')).join();

final ctxProvider = Provider<Ctx>((ref) => Ctx(newId: _newId, now: DateTime.now, by: ref.watch(changeByProvider)));

/// The household data plus one level of undo for the last change.
class HomeController extends AsyncNotifier<HomeData> {
  HomeData? _before;

  HomeRepository get _repo => ref.read(activeRepositoryProvider);
  Ctx get ctx => ref.read(ctxProvider);

  @override
  Future<HomeData> build() async {
    final repo = ref.watch(activeRepositoryProvider);
    _before = null;
    final results = await Future.wait([repo.load(), Future<void>.delayed(ref.read(splashDelayProvider))]);
    final sub = repo.remote.listen((d) => state = AsyncData(d));
    ref.onDispose(sub.cancel);
    return results.first as HomeData;
  }

  HomeData get data => state.requireValue;

  bool get canUndo => _before != null;

  /// Applies [change], saves, and remembers the old value for [undo].
  Future<T?> apply<T>(Object? Function(HomeData d, Ctx ctx) change) async {
    final before = data;
    final out = change(before, ctx);
    final (HomeData next, T? value) = switch (out) {
      Result(:final data, :final value) => (data, value as T?),
      HomeData d => (d, null),
      _ => throw ArgumentError('change must return HomeData or Result'),
    };
    _before = before;
    state = AsyncData(next);
    await _repo.save(next);
    return value;
  }

  Future<void> undo() async {
    final before = _before;
    if (before == null) return;
    _before = null;
    state = AsyncData(before);
    await _repo.save(before);
  }

  /// Clears what is saved on this phone. A shared home is left as it is.
  Future<void> resetAll() async {
    final local = ref.read(homeRepositoryProvider);
    await local.save(const HomeData());
    if (identical(_repo, local)) {
      _before = null;
      state = const AsyncData(HomeData());
    }
  }

  /// Everything logged in [year]-[month] (a shared home keeps only recent
  /// entries in memory, so it asks the server).
  Future<List<LogEntry>> monthLog(int year, int month) async => await _repo.monthLog(year, month) ?? data.log;

  /// The phone's own data, for putting into a new shared home.
  Future<HomeData> phoneData() => ref.read(homeRepositoryProvider).load();
}

final homeProvider = AsyncNotifierProvider<HomeController, HomeData>(HomeController.new);
