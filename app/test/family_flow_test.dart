import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/data/household.dart';
import 'package:homefairy/data/invite_link.dart';

import 'helpers.dart';

void main() {
  const en = {'language': 'en'};

  test('an invite link carries the code to the new phone', () {
    final link = InviteLink.of('482913');
    expect(link, startsWith(InviteLink.store));
    expect(link, contains('referrer=invite%3D482913'));
    expect(InviteLink.codeIn(Uri.parse(link).queryParameters['referrer']), '482913');
    expect(InviteLink.codeIn('utm_source=google-play'), isNull);
    expect(InviteLink.codeIn('invite=12345'), isNull);
  });

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('a member leaves after two confirmations; the map stays on the phone', (tester) async {
    final homes = FakeHouseholds()
      ..joinCode = '482913'
      ..joinHome = sampleHome();
    final c = await pumpApp(tester, location: '/invited?code=482913', prefs: en, accounts: const SignedIn(), households: homes);
    await tester.tap(find.byKey(const ValueKey('invited-join')));
    await tester.pumpAndSettle();
    expect(c.read(householdProvider).value?.id, 'h2');

    await tester.tap(find.text('Family').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const ValueKey('family-leave')), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('family-leave')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your map stays on this phone, and syncing stops!'), findsOneWidget);
    await tapText(tester, 'Next');
    expect(find.text('Leave for sure?'), findsOneWidget);
    await tapText(tester, 'Leave');
    expect(c.read(householdProvider).value, isNull);
    // The family home's things are now this phone's own.
    expect(c.read(homeProvider).requireValue.items.length, sampleHome().items.length);
  });

  testWidgets('cancelling either confirmation keeps you in the home', (tester) async {
    final homes = FakeHouseholds()..joinCode = '482913';
    final c = await pumpApp(tester, location: '/invited?code=482913', prefs: en, accounts: const SignedIn(), households: homes);
    await tester.tap(find.byKey(const ValueKey('invited-join')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Family').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const ValueKey('family-leave')), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('family-leave')));
    await tester.pumpAndSettle();
    await tapText(tester, 'Next');
    await tapText(tester, 'Cancel');
    expect(c.read(householdProvider).value?.id, 'h2');
  });

  testWidgets('the owner hands the home to someone before leaving', (tester) async {
    final homes = FakeHouseholds();
    final c = await pumpApp(tester, location: '/family', prefs: en, home: sampleHome(), accounts: const SignedIn(), households: homes);
    await tester.tap(find.byKey(const ValueKey('family-create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-upload-yes')));
    await tester.pumpAndSettle();
    homes.add(const Member('mom', 'Mom', null));
    await tester.pumpAndSettle();
    expect(find.textContaining('Plus allows 6'), findsOneWidget);

    await tester.scrollUntilVisible(find.byKey(const ValueKey('family-leave')), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('family-leave')));
    await tester.pumpAndSettle();
    expect(find.text('Who takes over the home?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('answer-0')));
    await tester.pumpAndSettle();
    expect(find.text('Hand the home to Mom and leave?'), findsOneWidget);
    await tester.tap(find.text('Hand over and leave'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(homes.transferredTo, 'mom');
    expect(c.read(householdProvider).value, isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('joining from an invite with a home on the phone asks whether to merge it', (tester) async {
    final homes = FakeHouseholds()..joinCode = '482913';
    final c = await pumpApp(tester, location: '/invited?code=482913', prefs: en, home: sampleHome(), accounts: const SignedIn(), households: homes);
    expect(find.text("You're invited to a family home"), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('invited-join')));
    await tester.pumpAndSettle();
    expect(find.text('What about the home on this phone?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('answer-0')));
    await tester.pumpAndSettle();
    expect(homes.repo!.data.items.length, sampleHome().items.length);
    expect(c.read(householdProvider).value?.id, 'h2');
    expect(find.byKey(const ValueKey('home-ask')), findsOneWidget);
  });
}
