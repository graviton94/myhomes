import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/account_backup.dart';
import 'package:homefairy/data/accounts.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/data/household.dart';
import 'package:homefairy/settings/settings.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

class FakeBackups extends AccountBackups {
  final kept = <String, HomeData>{};
  int saves = 0;

  @override
  Future<BackupInfo?> info(String uid) async {
    final d = kept[uid];
    return d == null ? null : BackupInfo(savedAt: DateTime(2026, 11, 20), rooms: d.spaces.length, spots: d.containers.length, items: d.items.length);
  }

  @override
  Future<HomeData?> load(String uid) async => kept[uid];

  @override
  Future<void> save(String uid, HomeData d) async {
    saves++;
    kept[uid] = d;
  }
}

void main() {
  late FakeBackups backups;
  late MemoryHomeRepository phone;

  Future<ProviderContainer> start(HomeData onPhone, {HomeData? onAccount}) async {
    SharedPreferences.setMockInitialValues({});
    backups = FakeBackups();
    if (onAccount != null) backups.kept['me'] = onAccount;
    phone = MemoryHomeRepository(onPhone);
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(await SharedPreferences.getInstance()),
        homeRepositoryProvider.overrideWithValue(phone),
        splashDelayProvider.overrideWithValue(Duration.zero),
        accountsProvider.overrideWithValue(const SignedIn()),
        accountBackupsProvider.overrideWithValue(backups),
      ],
    );
    addTearDown(c.dispose);
    c.listen(homeProvider, (_, _) {});
    c.listen(accountProvider, (_, _) {});
    c.listen(householdProvider, (_, _) {});
    await c.read(homeProvider.future);
    await c.read(accountProvider.future);
    return c;
  }

  final home = sampleHome();
  final small = const HomeData().copyWith(spaces: [home.spaces.first]);

  test('no backup yet: the phone home becomes it, without asking', () async {
    final c = await start(home);
    var asked = false;
    expect(await linkAccountBackup(c.read, (_, _) async => (asked = true) ? null : null), isTrue);
    expect(asked, isFalse);
    expect(backups.kept['me']!.items.length, home.items.length);
    expect(c.read(backupSavedAtProvider), isNotNull);
    // Linked once: a second sign-in check does nothing.
    await linkAccountBackup(c.read, (_, _) async => null);
    expect(backups.saves, 1);
  });

  test('empty phone: the account home comes back', () async {
    final c = await start(const HomeData(), onAccount: home);
    expect(await linkAccountBackup(c.read, (_, _) async => throw StateError('asked')), isTrue);
    expect(phone.data.items.length, home.items.length);
  });

  test('both have a home: asks, and each answer does what it says', () async {
    for (final choice in BackupChoice.values) {
      final c = await start(small, onAccount: home);
      await linkAccountBackup(c.read, (info, d) async {
        expect(info.items, home.items.length);
        expect(d.spaces.length, 1);
        return choice;
      });
      switch (choice) {
        case BackupChoice.account:
          expect(phone.data.items.length, home.items.length);
        case BackupChoice.phone:
          expect(phone.data.spaces.length, 1);
          expect(backups.kept['me']!.spaces.length, 1);
        case BackupChoice.both:
          expect(phone.data.items.length, home.items.length);
          expect(backups.kept['me']!.items.length, home.items.length);
      }
    }
  });

  test('dismissing the question changes nothing and asks again later', () async {
    final c = await start(small, onAccount: home);
    await linkAccountBackup(c.read, (_, _) async => null);
    expect(phone.data.spaces.length, 1);
    expect(backups.saves, 0);
    var asked = 0;
    await linkAccountBackup(c.read, (_, _) async {
      asked++;
      return null;
    });
    expect(asked, 1);
  });

  test('packed backup round-trips and keeps recent history only', () {
    final d = unpackBackup(packBackup(home, 1));
    expect(d.items.length, home.items.length);
    expect(d.log.length, home.log.isEmpty ? 0 : 1);
    expect(homeFingerprint(d), homeFingerprint(home));
  });
}
