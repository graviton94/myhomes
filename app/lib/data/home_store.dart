import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

/// Where the household data lives. Guest mode keeps one JSON file on the
/// phone; the cloud repository (Firestore) replaces it in Phase 3.
abstract class HomeRepository {
  Future<HomeData> load();
  Future<void> save(HomeData data);
}

/// One JSON file, written atomically (temp file + rename).
class FileHomeRepository implements HomeRepository {
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

class MemoryHomeRepository implements HomeRepository {
  MemoryHomeRepository([this.data = const HomeData()]);

  HomeData data;

  @override
  Future<HomeData> load() async => data;

  @override
  Future<void> save(HomeData data) async => this.data = data;
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) => throw UnimplementedError('homeRepositoryProvider not overridden'));

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

final ctxProvider = Provider<Ctx>((ref) => Ctx(newId: _newId, now: DateTime.now));

/// The household data plus one level of undo for the last change.
class HomeController extends AsyncNotifier<HomeData> {
  HomeData? _before;

  HomeRepository get _repo => ref.read(homeRepositoryProvider);
  Ctx get ctx => ref.read(ctxProvider);

  @override
  Future<HomeData> build() async {
    final results = await Future.wait([_repo.load(), Future<void>.delayed(ref.read(splashDelayProvider))]);
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

  Future<void> resetAll() async {
    _before = null;
    state = const AsyncData(HomeData());
    await _repo.save(const HomeData());
  }
}

final homeProvider = AsyncNotifierProvider<HomeController, HomeData>(HomeController.new);
