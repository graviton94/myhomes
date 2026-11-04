import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/design/theme.dart';
import 'package:homefairy/l10n/app_localizations.dart';
import 'package:homefairy/widgets/layers.dart';

import 'helpers.dart';

/// A bare screen with a button that runs [onTap].
Future<void> host(WidgetTester tester, Future<void> Function(BuildContext) onTap) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        body: Builder(builder: (context) => Center(child: TextButton(onPressed: () => onTap(context), child: const Text('go')))),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a question sheet returns the answer tapped', (tester) async {
    String? got;
    await host(tester, (context) async {
      got = await askQuestion<String>(
        context,
        title: 'Done with the scissors?',
        detail: 'Taken out at 11:40',
        answers: const [Answer('back', 'Yes, put back'), Answer('using', 'Still using'), Answer('moved', 'Put somewhere else')],
      );
    });
    expect(find.text('Done with the scissors?'), findsOneWidget);
    await tester.tap(find.text('Still using'));
    await tester.pumpAndSettle();
    expect(got, 'using');
  });

  testWidgets('a toast opens a − + in place and runs its actions', (tester) async {
    int? bought;
    var undone = false;
    await host(tester, (context) async {
      showActionToast(
        context,
        message: 'Put 2 tofu in the fridge',
        qty: ToastQty(
          label: 'Amount',
          question: 'How many did you buy?',
          value: 2,
          max: 2,
          note: (v) => v < 2 ? '${2 - v} stays on the list' : null,
          onDone: (v) => bought = v,
        ),
        actions: [ToastAction('Undo', () => undone = true)],
      );
    });
    expect(find.text('Put 2 tofu in the fridge'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('toast-Amount')));
    await tester.pumpAndSettle();
    expect(find.text('How many did you buy?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('toast-minus')));
    await tester.pump();
    expect(find.text('1 stays on the list'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('toast-done')));
    await tester.pumpAndSettle();
    expect(bought, 1);
    expect(undone, isFalse);

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toast-Undo')));
    await tester.pumpAndSettle();
    expect(undone, isTrue);
  });

  testWidgets('a tip shows until closed, then never again', (tester) async {
    await pumpApp(tester, location: '/storage/$sampleTv', prefs: {'language': 'en'}, home: sampleHome());
    expect(find.byKey(const ValueKey('tip-storage')), findsOneWidget);
    await tester.tap(find.descendant(of: find.byKey(const ValueKey('tip-storage')), matching: find.byTooltip('Close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tip-storage')), findsNothing);
  });
}
