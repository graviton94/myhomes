import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/l10n/app_localizations.dart';
import 'package:homefairy/widgets/icon_chooser.dart';
import 'package:homefairy/widgets/photo_picker.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  // User request: renaming a room, its icon follows the new name's first
  // suggestion, not the old icon; typed back, the old icon comes back.
  testWidgets('a renamed room takes the new name\'s first icon', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'});
    final context = tester.element(find.byType(Scaffold).first);
    final l = AppLocalizations.of(context);
    final bath = iconsFromName('Bathroom').first;
    final kitchen = iconsFromName('Kitchen').first;
    expect(bath, isNot(kitchen));
    NamePhotoIcon? got;
    askNameAndPhoto(context, title: 'Edit', label: l.spaceNameHint, kind: IconKind.space, name: 'Kitchen', icon: kitchen).then((r) => got = r);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Bathroom');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.save));
    await tester.pumpAndSettle();
    expect(got!.icon, bath);

    // Typed back to the old name: the old icon again.
    askNameAndPhoto(context, title: 'Edit', label: l.spaceNameHint, kind: IconKind.space, name: 'Kitchen', icon: 'sofa').then((r) => got = r);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Bathroom');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Kitchen');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.save));
    await tester.pumpAndSettle();
    expect(got!.icon, 'sofa');
  });

  testWidgets('a renamed item takes the new name\'s icon and kind', (tester) async {
    var d = sampleHome();
    final first = d.items.first;
    final container = await pumpApp(tester, location: '/item/${first.id}/edit', prefs: {'language': 'en'}, home: d);
    await tester.enterText(find.byType(TextField).first, 'Milk');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    d = container.read(homeProvider).requireValue;
    final milk = d.item(first.id)!;
    expect(milk.name, 'Milk');
    expect(milk.category, guessCategory('Milk'));
    expect(effectiveIcon(milk.icon, 'Milk'), iconsFromName('Milk').first);
  });

  testWidgets('a room is not added under a name already used', (tester) async {
    final d = sampleHome();
    final taken = d.spaces.firstWhere((s) => !s.outside).name;
    final container = await pumpApp(tester, location: '/house/edit', prefs: {'language': 'en'}, home: d);
    await tester.ensureVisible(find.byKey(const ValueKey('house-add-room')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('house-add-room')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, taken);
    await tester.pumpAndSettle();
    expect(find.text('There is already a $taken. Try another name.'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(container.read(homeProvider).requireValue.spaces.length, d.spaces.length);
    await tester.enterText(find.byType(TextField).first, '$taken 2');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(container.read(homeProvider).requireValue.spaces.length, d.spaces.length + 1);
  });
}
