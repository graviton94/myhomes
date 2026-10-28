import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/data/household.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'helpers.dart';

void main() {
  testWidgets('guests are asked to sign in on the family tab', (tester) async {
    await pumpApp(tester, location: '/family', prefs: {'language': 'en'});
    expect(find.text('Share with your family'), findsOneWidget);
    expect(find.byKey(const ValueKey('family-sign-in')), findsOneWidget);
  });

  testWidgets('make our home with the phone\'s things, invite, and see family changes', (tester) async {
    final homes = FakeHouseholds();
    final container = await pumpApp(
      tester,
      location: '/family',
      prefs: {'language': 'en'},
      home: sampleHome(),
      accounts: const SignedIn(),
      households: homes,
    );
    await tester.tap(find.byKey(const ValueKey('family-create')));
    await tester.pumpAndSettle();
    expect(find.textContaining('items. Your family will see them'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('family-upload-yes')));
    await tester.pumpAndSettle();

    expect(find.text('Our home · 1 of 2'), findsOneWidget);
    expect(find.text('Mina (Me)'), findsOneWidget);
    expect(homes.repo!.data.items.length, sampleHome().items.length);

    await tester.tap(find.byKey(const ValueKey('family-invite')));
    await tester.pumpAndSettle();
    expect(find.text('482 913'), findsOneWidget);

    // Mom joins and adds milk on her phone.
    homes.add(const Member('mom', 'Mom', null));
    await tester.pumpAndSettle();
    expect(find.text('Free homes hold 2 people.'), findsOneWidget);
    final d = homes.repo!.data;
    final fridge = d.containers.firstWhere((c) => c.name == 'Fridge');
    homes.repo!.push(
      addItem(
        d,
        Ctx(newId: () => 'new${d.log.length}', now: DateTime.now, by: 'mom'),
        containerId: fridge.id,
        name: 'Butter',
      ).data,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Mom · '), findsOneWidget);
    expect(container.read(homeProvider).requireValue.items.any((i) => i.name == 'Butter'), isTrue);

    // My own changes carry my uid.
    await container.read(homeProvider.notifier).apply((d, ctx) => adjustQty(d, ctx, d.items.first.id, 1));
    expect(homes.repo!.data.log.first.by, 'me');
  });

  testWidgets('a wrong code says so', (tester) async {
    await pumpApp(tester, location: '/family', prefs: {'language': 'en'}, accounts: const SignedIn(), households: FakeHouseholds());
    await tester.tap(find.byKey(const ValueKey('family-join')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('join-code')), '000000');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('join-go')));
    await tester.pumpAndSettle();
    expect(find.text('That code is wrong or has expired.'), findsOneWidget);
  });
}
