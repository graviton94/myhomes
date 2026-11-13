@Tags(['audit'])
library;

import 'dart:io';

import 'package:homefairy/data/app_update.dart';
import 'package:homefairy/data/shop.dart';
import 'package:homefairy/features/spaces/sections_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/accounts.dart';
import 'package:homefairy/data/recipes.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'package:homefairy/features/item/receipt_screen.dart';
import 'package:homefairy/widgets/fit_text.dart';

import 'helpers.dart';

/// Opens every screen at phone width (Korean, some English) and fails on any
/// text the layout wrapped by itself, where no "\n" of ours put the break,
/// and on any row of capsules that broke onto a second line (user request,
/// 2026-11-04: lines break where the sentence does; chips stay on one line).
/// The list also goes to build/line_breaks.txt. Fix by adding "\n" in the ARB
/// and drawing with FitText, or by using ChipLine.
void main() {
  final found = <String>{};
  setUpAll(loadAppFonts);

  void collect(WidgetTester tester, String screen, {Finder? under}) {
    void visit(RenderObject o) {
      if (o is RenderWrap) {
        // A row of capsules on two lines (grids of cards are allowed: their children are wide).
        final kids = <RenderBox>[];
        o.visitChildren((c) => kids.add(c as RenderBox));
        if (kids.length > 1 && kids.every((k) => k.size.width < o.size.width * 0.45)) {
          final tops = kids.map((k) => (k.parentData! as WrapParentData).offset.dy).toSet();
          if (tops.length > 1 && kids.every((k) => k.size.height < 60)) {
            found.add('$screen\tchips on ${tops.length} lines\t${o.size.width.round()}dp\t${kids.length} chips');
          }
        }
      }
      if (o is RenderParagraph) {
        final text = o.text.toPlainText(includeSemanticsLabels: false).replaceAll('⁠', '');
        final painter = TextPainter(
          text: o.text,
          textDirection: o.textDirection,
          textScaler: o.textScaler,
          maxLines: o.maxLines,
          strutStyle: o.strutStyle,
          textWidthBasis: o.textWidthBasis,
        )..layout(maxWidth: o.size.width + 0.5);
        final lines = painter.computeLineMetrics();
        final cut = o.maxLines != null && painter.didExceedMaxLines && o.overflow == TextOverflow.ellipsis;
        painter.dispose();
        if (cut && text.trim().isNotEmpty) found.add('$screen\tcut short\t${o.size.width.round()}dp\t${text.replaceAll('\n', '⏎')}');
        final ours = '\n'.allMatches(text).length + 1;
        // Running text (Prose) may take lines, but each must start after a space.
        final element = (o.debugCreator as DebugCreator?)?.element;
        if (element?.findAncestorWidgetOfExactType<Prose>() != null) {
          final plain = o.text.toPlainText(includeSemanticsLabels: false);
          final p2 = TextPainter(text: o.text, textDirection: o.textDirection, textScaler: o.textScaler)..layout(maxWidth: o.size.width + 0.5);
          for (final line in p2.computeLineMetrics().skip(1)) {
            final start = p2.getPositionForOffset(Offset(0.5, line.baseline - line.ascent / 2)).offset;
            if (start > 0 && start < plain.length && !' \n'.contains(plain[start - 1])) {
              found.add('$screen\tbreaks inside a word\t${o.size.width.round()}dp\t${plain.substring(0, start).replaceAll('⁠', '')}⏎');
            }
          }
          p2.dispose();
          o.visitChildren(visit);
          return;
        }
        if (lines.length > ours && text.trim().isNotEmpty) {
          found.add('$screen\t${lines.length} lines\t${o.size.width.round()}dp\t${text.replaceAll('\n', '⏎')}');
        }
      }
      o.visitChildren(visit);
    }

    if (under != null) {
      for (final e in under.evaluate()) {
        e.renderObject?.visitChildren(visit);
      }
      return;
    }
    tester.binding.rootPipelineOwner.rootNode?.visitChildren(visit);
    for (final view in tester.binding.renderViews) {
      view.visitChildren(visit);
    }
  }

  tearDownAll(() {
    final out = File('build/line_breaks.txt')..createSync(recursive: true);
    out.writeAsStringSync((found.toList()..sort()).join('\n'));
  });

  tearDown(() => expect(found, isEmpty, reason: 'Texts that wrapped by themselves:\n${found.join('\n')}'));

  const on = {'language': 'ko', 'theme': 'light', 'feature.expiry': true, 'feature.returns': true, 'feature.lowStock': true};
  HomeData home() {
    final base = sampleHome(ko: true);
    return base.copyWith(items: [for (final i in base.items) i.name == 'AA 건전지' ? i.copyWith(minQty: 10, updatedAt: i.updatedAt) : i]);
  }

  // A move in progress: two boxes (one going to the kitchen, one unpacked), things packed.
  HomeData moving() {
    var n = 0;
    final ctx = Ctx(newId: () => 'mv${n++}', now: () => DateTime(2026, 11, 5));
    var d = startMoving(home(), ctx, '이사 상자').data;
    final b1 = addMovingBox(d, ctx, '상자 1');
    d = setGoesTo(b1.data, b1.value.id, '주방');
    final b2 = addMovingBox(d, ctx, '상자 2');
    d = b2.data.copyWith(containers: [for (final c in b2.data.containers) c.id == b2.value.id ? c.copyWith(unpacked: true) : c]);
    final cut = d.items.firstWhere((i) => i.name == '가위');
    return moveItems(d, ctx, {cut.id: 1}, b1.value.id);
  }

  // A dish the sample home makes, and the one with the most steps among them.
  final ideas = suggestRecipes(home(), parseRecipes(File('assets/recipes.json').readAsStringSync()), DateTime.now(), limit: 80);
  final dish = ideas.first.recipe.id;
  final longest = (ideas.toList()..sort((a, b) => b.recipe.steps.join().length.compareTo(a.recipe.steps.join().length))).first.recipe.id;

  // Phones differ: a narrow one, the usual one, a wide one, and the usual one
  // with the system font made larger (a common setting).
  const phones = [('360', Size(360, 780), 1.0), ('320', Size(320, 700), 1.0), ('412', Size(412, 900), 1.0), ('360 +30%', Size(360, 780), 1.3)];
  for (final (phone, size, scale) in phones) {
    for (final route in ['/moving', '/moving/box/mv1']) {
      testWidgets('wraps on $route · $phone', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(tester, location: route, prefs: on, home: moving(), size: size);
        collect(tester, '$phone $route');
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 10));
      });
    }
  }

  for (final (phone, size, scale) in phones) {
    for (final (route, signedIn) in [
      ('/', false),
      ('/put', false),
      ('/family', false),
      ('/family', true),
      ('/settings', true),
      ('/spaces', false),
      ('/space/id0', false),
      ('/storage/$sampleTv', false),
      ('/expiry', false),
      ('/shopping', false),
      ('/report', false),
      ('/history', false),
      ('/valuables', false),
      ('/receipt', false),
      ('/house/setup', false),
      ('/house/edit', false),
      ('/item/new', false),
      ('/add', false),
      ('/recipes', false),
      ('/achievements', false),
      ('/recipe/$dish', false),
      ('/recipe/$longest', false),
    ]) {
      testWidgets('wraps on $route${signedIn ? ' (signed in)' : ''} · $phone', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(tester, location: route, prefs: on, home: home(), size: size, accounts: signedIn ? const SignedIn() : const NoAccounts());
        // Long pages: look at every part.
        for (var i = 0; i < 6; i++) {
          collect(tester, '$phone $route');
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isEmpty) break;
          await tester.drag(scrollables.first, const Offset(0, -500), warnIfMissed: false);
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 10));
      });
    }
  }

  // The store's new version: the toast in each step, and Settings › 앱 정보.
  for (final (phone, size, scale) in phones) {
    for (final lang in ['ko', 'en']) {
      testWidgets('wraps in the update toast ($lang · $phone)', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        for (final phase in [
          UpdatePhase.available,
          UpdatePhase.downloading,
          UpdatePhase.downloaded,
          UpdatePhase.failed,
          UpdatePhase.notStore,
          UpdatePhase.latest,
        ]) {
          final store = FakeUpdates(UpdateState(phase, progress: 0.42, code: 1004));
          for (final route in ['/', '/settings']) {
            await pumpApp(tester, location: route, prefs: {'language': lang}, size: size, updater: store);
            if (route == '/settings') {
              await tester.scrollUntilVisible(find.byKey(const ValueKey('settings-version')), 300, scrollable: find.byType(Scrollable).first);
              await tester.pumpAndSettle();
            }
            // Settings is checked elsewhere; here only its 앱 정보 row.
            collect(
              tester,
              '$lang $route update ${phase.name} · $phone',
              under: find.byKey(ValueKey(route == '/settings' ? 'settings-version' : 'update-toast')),
            );
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 10));
      });
    }
  }

  // "요정 가루 더 받기": a guest, and an account with the store's prices.
  for (final (phone, size, scale) in phones) {
    for (final lang in ['ko', 'en']) {
      testWidgets('wraps on /plus ($lang · $phone)', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(tester, location: '/plus', prefs: {'language': lang}, size: size);
        collect(tester, '$lang /plus guest · $phone');
        await pumpApp(tester, location: '/plus', prefs: {'language': lang}, size: size, accounts: const SignedIn(), shop: _PricedShop());
        for (var i = 0; i < 3; i++) {
          collect(tester, '$lang /plus · $phone');
          await tester.drag(find.byType(Scrollable).first, const Offset(0, -400), warnIfMissed: false);
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 10));
      });
    }
  }

  // "칸 · 서랍": the rows, one being renamed, and the note about removed sections.
  for (final (phone, size, scale) in phones) {
    for (final lang in ['ko', 'en']) {
      testWidgets('wraps in the sections screen ($lang · $phone)', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(tester, prefs: {'language': lang}, size: size);
        editSections(
          tester.element(find.byType(Scaffold).first),
          furniture: lang == 'ko' ? '거실 TV장' : 'Living room TV stand',
          rows: const [(id: 'a', name: '윗칸 서랍'), (id: 'b', name: 'Middle shelf'), (id: null, name: '아랫칸')],
          counts: const {'a': 12},
        );
        await tester.pumpAndSettle();
        collect(tester, '$lang sections · $phone', under: find.byType(SectionsScreen));
        await tester.tap(find.byKey(const ValueKey('section-edit-1')));
        await tester.pumpAndSettle();
        collect(tester, '$lang sections renaming · $phone', under: find.byType(SectionsScreen));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 10));
      });
    }
  }

  testWidgets('wraps on an empty home', (tester) async {
    await pumpApp(tester, prefs: const {'language': 'ko'});
    collect(tester, '/ (empty)');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('wraps in our home (family) and a receipt list', (tester) async {
    final homes = FakeHouseholds();
    await homes.create('우리 집', upload: home());
    await pumpApp(tester, location: '/family', prefs: on, accounts: const SignedIn(), households: homes);
    await tester.tap(find.byKey(const ValueKey('family-invite')));
    await tester.pumpAndSettle();
    collect(tester, '/family (home)');
    await pumpApp(tester, location: '/receipt?storage=$sampleTv', prefs: on, home: home());
    (tester.state(find.byType(ReceiptScreen)) as dynamic).showRows(const ['001 CJ햇반210g*3 3,980 1 3,980', '002 키친타월 4,900 2 9,800']);
    await tester.pumpAndSettle();
    collect(tester, '/receipt (list)');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });

  for (final route in ['/', '/settings', '/storage/$sampleTv', '/house/setup', '/put']) {
    testWidgets('wraps in English on $route', (tester) async {
      await pumpApp(tester, location: route, prefs: {...on, 'language': 'en'}, home: sampleHome(), accounts: const SignedIn());
      for (var i = 0; i < 6; i++) {
        collect(tester, 'en $route');
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isEmpty) break;
        await tester.drag(scrollables.first, const Offset(0, -500), warnIfMissed: false);
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
    });
  }

  for (final (prefs, name) in [
    (const {'language': 'ko', 'introSeen': false}, 'intro'),
    (const {'language': 'ko', 'introSeen': true, 'started': false}, 'login'),
  ]) {
    testWidgets('wraps on $name', (tester) async {
      await pumpApp(tester, prefs: prefs, onboarded: false);
      collect(tester, name);
      // Every intro page, not just the first.
      for (var i = 2; i <= 4 && name == 'intro'; i++) {
        await tester.tap(find.byType(FilledButton).last);
        await tester.pumpAndSettle();
        collect(tester, '$name $i');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
    });
  }

  // Sheets, toasts and windows over the screens: opened one by one.
  for (final lang in ['ko', 'en']) {
    testWidgets('wraps in sheets, toasts and windows ($lang)', (tester) async {
      final prefs = {...on, 'language': lang};
      final base = lang == 'ko' ? home() : sampleHome();
      Future<void> close() async {
        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();
      }

      Future<void> look(String what, Future<void> Function() open) async {
        await open();
        await tester.pumpAndSettle();
        collect(tester, '$lang $what');
      }

      // Item sheet, the use toast, the in-use sheet.
      await pumpApp(tester, location: '/storage/$sampleTv', prefs: prefs, home: base);
      await look('item sheet', () => tester.tap(find.byKey(const ValueKey('slot-$sampleTv-2'))));
      await look('use toast', () => tester.tap(find.byKey(const ValueKey('item-use'))));
      await look('in-use sheet', () => tester.tap(find.byKey(const ValueKey('slot-$sampleTv-2'))));
      await close();

      // Item add: the square's menu, kinds, use-by, place window, amount toast.
      await pumpApp(tester, location: '/item/new?storage=$sampleTv', prefs: prefs, home: base);
      await look('square menu', () => tester.tap(find.byKey(const ValueKey('item-square'))));
      await close();
      await look('kinds sheet', () => tester.tap(find.byKey(const ValueKey('more-category'))));
      await close();
      await look('use-by sheet', () => tester.tap(find.byKey(const ValueKey('more-due'))));
      await close();
      await look('place window', () => tester.tap(find.byKey(const ValueKey('item-place'))));
      await close();
      await look('amount toast', () => tester.tap(find.byKey(const ValueKey('item-qty'))));

      // "무엇을 더할까요?" on the map.
      await pumpApp(tester, prefs: prefs, home: base);
      await tester.ensureVisible(find.byKey(const ValueKey('map-add-room')));
      await look('add place', () => tester.tap(find.byKey(const ValueKey('map-add-room'))));
      await close();

      // The cook sheet on a dish.
      if (lang == 'ko') {
        await pumpApp(tester, location: '/recipe/$dish', prefs: prefs, home: base);
        await look('cook sheet', () => tester.tap(find.byKey(const ValueKey('recipe-cooked'))));
        await close();
      }

      // The question on opening the app.
      final cut = base.items.firstWhere((i) => i.category == ItemCategory.tools);
      final out = base.copyWith(
        items: [
          for (final i in base.items) i.id == cut.id ? i.copyWith(inUseSince: DateTime.now().subtract(const Duration(hours: 3)), updatedAt: i.updatedAt) : i,
        ],
      );
      await pumpApp(tester, prefs: prefs, home: out, asks: true);
      await tester.pumpAndSettle();
      collect(tester, '$lang question sheet');

      // Shopping: the toast after ticking, and its − +.
      final aa = base.items.firstWhere((i) => i.category == ItemCategory.household);
      final low = base.copyWith(
        items: [for (final i in base.items) i.id == aa.id ? i.copyWith(minQty: i.qty + 3, updatedAt: i.updatedAt) : i],
      );
      await pumpApp(tester, location: '/shopping', prefs: prefs, home: low);
      await look('shopping toast', () => tester.tap(find.byKey(ValueKey('buy-low:${aa.id}'))));
      await look('shopping amount', () => tester.tap(find.byKey(const ValueKey('toast-amount'))));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
    });
  }
}

class _PricedShop extends NoShop {
  @override
  Future<List<ShopProduct>> products() async => const [ShopProduct(ShopIds.plus, '₩3,300'), ShopProduct(ShopIds.dust, '₩2,200')];
}
