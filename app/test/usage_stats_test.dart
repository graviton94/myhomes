import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/data/usage_stats.dart';
import 'package:homefairy/settings/settings.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

class _Sender implements UsageSender {
  final sent = <Map<String, Object>>[];
  bool online = true;

  @override
  Future<bool> send(Map<String, Object> report) async {
    if (!online) return false;
    sent.add(report);
    return true;
  }
}

void main() {
  test('once a day: plain numbers and a snapshot, never names', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sender = _Sender();
    final d = sampleHome();
    await countUsage(prefs, UsageCount.added, 3);
    await countUsage(prefs, UsageCount.empty);
    final day1 = DateTime(2026, 11, 20, 9);
    await reportUsage(prefs, sender, d, account: false, family: false, now: day1);
    final r = sender.sent.single;
    expect([r['added'], r['found'], r['empty'], r['template']], [3, 0, 1, 0]);
    expect(r['items'], d.items.length);
    expect(r['rooms'], d.spaces.where((s) => !s.outside && !s.moving).length);
    expect([r['map'], r['age'], r['account'], r['family']], [d.spaces.any((s) => s.plan != null), 0, false, false]);
    expect(r.values.every((v) => v is int || v is bool), isTrue); // numbers and yes/no only
    // Not again the same day; the counters started over.
    await countUsage(prefs, UsageCount.found);
    await reportUsage(prefs, sender, d, account: false, family: false, now: day1.add(const Duration(hours: 3)));
    expect(sender.sent.length, 1);
    // Offline the next day: kept, and sent when it can be.
    sender.online = false;
    await reportUsage(prefs, sender, d, account: true, family: false, now: DateTime(2026, 11, 22, 8));
    sender.online = true;
    await reportUsage(prefs, sender, d, account: true, family: false, now: DateTime(2026, 11, 22, 9));
    expect(sender.sent.last['found'], 1);
    expect(sender.sent.last['age'], 2);
    expect(sender.sent.last.keys.any((k) => k.contains('name') || k.contains('query')), isFalse);
  });

  testWidgets('putting things away counts them; a search that finds nothing counts once', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    final prefs = container.read(prefsProvider);
    final tv = sampleHome().containers.first.id;
    await container.read(homeProvider.notifier).apply((d, ctx) => addItem(d, ctx, containerId: tv, name: 'Glue').data);
    expect(prefs.getInt('stat.added'), 1);
    await tester.enterText(find.byType(TextField).first, 'zzqx unicorn');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(prefs.getInt('stat.empty'), 1);
    // The same words again do not count twice.
    await tester.pump(const Duration(seconds: 3));
    expect(prefs.getInt('stat.empty'), 1);
  });
}
