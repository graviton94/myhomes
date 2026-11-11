import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/backup.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'helpers.dart';

void main() {
  test('a backup file brings the home and its photos back on another phone', () async {
    final tmp = await Directory.systemTemp.createTemp('hf-backup');
    addTearDown(() => tmp.delete(recursive: true));
    final oldPhotos = await Directory('${tmp.path}/old').create();
    final photo = await File('${oldPhotos.path}/abc.webp').writeAsBytes([1, 2, 3]);
    await File('${oldPhotos.path}/abc_t.webp').writeAsBytes([4]);
    final proof = await File('${oldPhotos.path}/receipt.webp').writeAsBytes([7, 8]);
    var d = sampleHome();
    final item = d.items.first;
    d = d.copyWith(
      items: [for (final i in d.items) i.id == item.id ? i.copyWith(photoPath: photo.path, proofPath: proof.path, updatedAt: i.updatedAt) : i],
    );
    // A line written on the shopping list by hand.
    d = addToBuy(d, Ctx(newId: () => 'buy1', now: () => DateTime(2026, 11, 11)), 'Tofu');

    final file = await Backup.write(d, File('${tmp.path}/home.homefairy'), photoOf: File.new);
    final newPhotos = Directory('${tmp.path}/new');
    final back = await Backup.read(file, newPhotos);

    expect(back.items.length, d.items.length);
    expect(back.item(item.id)!.photoPath, '${newPhotos.path}/abc.webp');
    expect(File('${newPhotos.path}/abc.webp').readAsBytesSync(), [1, 2, 3]);
    expect(File('${newPhotos.path}/abc_t.webp').existsSync(), isTrue);
    expect(back.log.length, d.log.length);
    // The receipt kept with a thing, and the shopping list, come back too.
    expect(back.item(item.id)!.proofPath, '${newPhotos.path}/receipt.webp');
    expect(File('${newPhotos.path}/receipt.webp').readAsBytesSync(), [7, 8]);
    expect(back.toBuy.map((b) => b.name), ['Tofu']);
  });

  test('anything else is refused', () async {
    final tmp = await Directory.systemTemp.createTemp('hf-backup');
    addTearDown(() => tmp.delete(recursive: true));
    final junk = await File('${tmp.path}/x.homefairy').writeAsString('hello');
    expect(() => Backup.read(junk, tmp), throwsFormatException);
  });
}
