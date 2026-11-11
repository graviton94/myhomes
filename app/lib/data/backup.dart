import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:homefairy_core/homefairy_core.dart';

/// A backup file (.homefairy): a zip with the home as JSON and its photos.
/// Made on the phone and shared wherever the person keeps files.
abstract final class Backup {
  static const _home = 'home.json';
  static const _photos = 'photos/';
  static const format = 1;

  /// Writes [d] and the photos it uses into [file].
  static Future<File> write(HomeData d, File file, {required File Function(String path) photoOf}) async {
    final archive = Archive()..addFile(ArchiveFile.string(_home, jsonEncode({'format': format, 'savedAt': DateTime.now().toIso8601String(), ...d.toJson()})));
    final seen = <String>{};
    for (final path in _photoPaths(d)) {
      final name = path.split('/').last;
      if (!seen.add(name)) continue;
      final photo = photoOf(path);
      if (!photo.existsSync()) continue;
      archive.addFile(ArchiveFile.bytes('$_photos$name', await photo.readAsBytes()));
      final thumb = File(photo.path.replaceFirst(RegExp(r'\.webp$'), '_t.webp'));
      if (thumb.path != photo.path && thumb.existsSync()) {
        archive.addFile(ArchiveFile.bytes('$_photos${thumb.path.split('/').last}', await thumb.readAsBytes()));
      }
    }
    await file.writeAsBytes(ZipEncoder().encodeBytes(archive), flush: true);
    return file;
  }

  /// Reads a backup: the home, with its photos put in [photoDir] and the
  /// home pointing at them. Throws [FormatException] for anything else.
  static Future<HomeData> read(File file, Directory photoDir) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    } catch (_) {
      throw const FormatException('not a backup file');
    }
    final json = archive.find(_home);
    if (json == null) throw const FormatException('no home in the backup');
    final map = jsonDecode(utf8.decode(json.content)) as Map<String, Object?>;
    final home = HomeData.fromJson(map);
    await photoDir.create(recursive: true);
    for (final f in archive.files) {
      if (!f.isFile || !f.name.startsWith(_photos)) continue;
      final name = f.name.substring(_photos.length);
      if (name.isEmpty || name.contains('/') || name.contains('..')) continue;
      await File('${photoDir.path}/$name').writeAsBytes(f.content, flush: true);
    }
    String? moved(String? path) => path == null ? null : '${photoDir.path}/${path.split('/').last}';
    return HomeData(
      spaces: [for (final s in home.spaces) s.photoPath == null ? s : s.copyWith(photoPath: moved(s.photoPath))],
      containers: [for (final c in home.containers) c.photoPath == null ? c : c.copyWith(photoPath: moved(c.photoPath))],
      items: [
        for (final i in home.items)
          i.photoPath == null && i.proofPath == null ? i : i.copyWith(photoPath: moved(i.photoPath), proofPath: moved(i.proofPath), updatedAt: i.updatedAt),
      ],
      log: home.log,
      toBuy: home.toBuy,
    );
  }

  static Iterable<String> _photoPaths(HomeData d) => photoPathsOf(d);
}

/// Every picture the home points at: rooms, spots, things, and the receipts
/// or warranty cards kept with a thing.
List<String> photoPathsOf(HomeData d) => [
  for (final s in d.spaces) ?s.photoPath,
  for (final c in d.containers) ?c.photoPath,
  for (final i in d.items) ...[?i.photoPath, ?i.proofPath],
];
