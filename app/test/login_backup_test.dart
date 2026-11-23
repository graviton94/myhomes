import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/accounts.dart';
import 'package:homefairy/features/house/house_setup_screen.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'account_backup_test.dart' show FakeBackups;
import 'helpers.dart';

/// Signs in with Google as "Mina" (uid me) when the button is pressed.
class SignsIn implements Accounts {
  final _changes = StreamController<Account?>.broadcast();
  static const me = Account(LoginProvider.google, 'Mina', null, 'me');

  @override
  Set<LoginProvider> get providers => const {LoginProvider.google};

  @override
  Stream<Account?> get changes async* {
    yield null;
    yield* _changes.stream;
  }

  @override
  Future<Account?> signIn(LoginProvider provider) async {
    _changes.add(me);
    await Future<void>.delayed(Duration.zero);
    return me;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

void main() {
  setUpAll(loadAppFonts);

  Future<void> signIn(WidgetTester tester, FakeBackups backups) async {
    await pumpApp(tester, prefs: {'language': 'en', 'introSeen': true}, onboarded: false, accounts: SignsIn(), backups: backups);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
  }

  testWidgets('reinstalled: signing in brings the account home back instead of a new one', (tester) async {
    final backups = FakeBackups()..kept['me'] = sampleHome();
    await signIn(tester, backups);
    expect(find.byType(HouseSetupScreen), findsNothing);
    expect(find.text('Living room'), findsWidgets);
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('a new account with nothing saved starts from the floor plan', (tester) async {
    final backups = FakeBackups();
    await signIn(tester, backups);
    expect(find.byType(HouseSetupScreen), findsOneWidget);
    expect(backups.kept['me'], isNotNull);
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('a home in both asks which one, and offers no new home', (tester) async {
    final backups = FakeBackups()..kept['me'] = sampleHome();
    await pumpApp(
      tester,
      prefs: {'language': 'en', 'introSeen': true},
      onboarded: false,
      accounts: SignsIn(),
      backups: backups,
      home: const HomeData().copyWith(spaces: [sampleHome().spaces.last]),
    );
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Which home to use?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('answer-0')));
    await tester.pumpAndSettle();
    expect(find.byType(HouseSetupScreen), findsNothing);
    await tester.pump(const Duration(seconds: 30));
  });
}
