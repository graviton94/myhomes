import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_widget_sync.dart';
import 'package:homefairy/l10n/app_localizations_en.dart';
import 'package:homefairy/settings/settings.dart';

import 'helpers.dart';

void main() {
  final today = DateTime.now();

  test('the widget shows counts for the extras that are on, else a summary', () {
    final l = AppLocalizationsEn();
    final d = sampleHome();
    final off = widgetLines(l, d, const AppSettings(), today);
    expect(off['counts'], '${d.items.length} things in ${d.spaces.length} places');
    expect(off['detail'], '');
    final on = widgetLines(l, d, const AppSettings(expiryOn: true, returnsOn: true), today);
    expect(on['counts'], startsWith('Use first '));
    expect(on['detail'], contains('Milk'));
    expect(on['search'], l.searchHint);
  });

  testWidgets('tapping the widget\'s search box opens Home with the cursor in search', (tester) async {
    final taps = StreamController<Uri?>.broadcast();
    await pumpApp(tester, location: '/put', prefs: {'language': 'en'}, home: sampleHome(), homeScreen: _FakeWidget(taps.stream));
    taps.add(Uri.parse('homefairy://search'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byKey(const ValueKey('home-search')));
    expect(field.focusNode!.hasFocus, isTrue);
  });
}

class _FakeWidget implements HomeScreenWidget {
  _FakeWidget(this.taps);

  @override
  final Stream<Uri?> taps;

  @override
  Future<Uri?> launchedFrom() async => null;

  @override
  Future<void> show(Map<String, String> lines) async {}
}
