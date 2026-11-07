import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/app_update.dart';

import 'helpers.dart';

void main() {
  // Real fonts, so the toast's sentence fits as it does on a phone.
  setUpAll(loadAppFonts);

  testWidgets('a new version on the store: get it, watch it come, restart', (tester) async {
    final store = FakeUpdates(const UpdateState(UpdatePhase.available, code: 1004));
    await pumpApp(tester, prefs: const {'language': 'en'}, updater: store);
    expect(find.byKey(const ValueKey('update-toast')), findsOneWidget);
    expect(find.textContaining('A new version is out', findRichText: true), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('update-get')));
    // Fetching with no size yet: the bar moves on its own, so no settling.
    await tester.pump();
    await tester.pump();
    expect(store.started, isTrue);

    store.push(const UpdateState(UpdatePhase.downloading, progress: 0.42));
    await tester.pump();
    expect(find.textContaining('42%', findRichText: true), findsOneWidget);
    expect(find.byKey(const ValueKey('update-progress')), findsOneWidget);

    store.push(const UpdateState(UpdatePhase.downloaded));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('update-restart')));
    await tester.pump();
    expect(store.completed, isTrue);
  });

  testWidgets('"later" keeps the toast away; Settings still offers it', (tester) async {
    final store = FakeUpdates(const UpdateState(UpdatePhase.available, code: 1004));
    await pumpApp(tester, prefs: const {'language': 'en'}, updater: store);
    await tester.tap(find.byKey(const ValueKey('update-later')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('update-toast')), findsNothing);

    await pumpApp(tester, location: '/settings', prefs: const {'language': 'en'}, updater: store);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('settings-update')), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('New version', findRichText: true), findsOneWidget);
  });

  testWidgets('a test install says only store installs check', (tester) async {
    await pumpApp(tester, location: '/settings', prefs: const {'language': 'en'});
    expect(find.byKey(const ValueKey('update-toast')), findsNothing);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('settings-version')), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Only apps installed from', findRichText: true), findsOneWidget);
  });
}
