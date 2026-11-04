@Tags(['audit'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/accounts.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'package:homefairy/features/item/receipt_screen.dart';

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

  void collect(WidgetTester tester, String screen) {
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
        painter.dispose();
        final ours = '\n'.allMatches(text).length + 1;
        if (lines.length > ours && text.trim().isNotEmpty) {
          found.add('$screen\t${lines.length} lines\t${o.size.width.round()}dp\t${text.replaceAll('\n', '⏎')}');
        }
      }
      o.visitChildren(visit);
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
    ('/receipt', false),
    ('/house/setup', false),
    ('/house/edit', false),
    ('/item/new', false),
    ('/add', false),
  ]) {
    testWidgets('wraps on $route${signedIn ? ' (signed in)' : ''}', (tester) async {
      await pumpApp(tester, location: route, prefs: on, home: home(), accounts: signedIn ? const SignedIn() : const NoAccounts());
      // Long pages: look at every part.
      for (var i = 0; i < 6; i++) {
        collect(tester, route);
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isEmpty) break;
        await tester.drag(scrollables.first, const Offset(0, -500), warnIfMissed: false);
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
    });
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
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
    });
  }
}
