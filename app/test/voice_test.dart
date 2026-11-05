import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_widget_sync.dart';
import 'package:homefairy/data/voice.dart';

import 'helpers.dart';

/// Says [words] as soon as listening starts.
class _Says implements Voice {
  _Says(this.words);

  final String words;
  var started = 0;

  @override
  Future<bool> listen(String localeId, void Function(String words, bool done) onWords) async {
    started++;
    onWords(words, true);
    return true;
  }

  @override
  Future<void> stop() async {}
}

class _Taps implements HomeScreenWidget {
  _Taps(this.taps);

  @override
  final Stream<Uri?> taps;

  @override
  Future<Uri?> launchedFrom() async => null;

  @override
  Future<void> show(Map<String, String> lines) async {}
}

void main() {
  testWidgets('the microphone fills the search box with what was said', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome(), voice: _Says('where is the remote'));
    await tester.tap(find.byKey(const ValueKey('home-mic')));
    await tester.pumpAndSettle();
    expect(find.text('where is the remote'), findsOneWidget);
    expect(find.text('Remote'), findsWidgets);
  });

  testWidgets('without a recogniser the phone says so', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    await tester.tap(find.byKey(const ValueKey('home-mic')));
    await tester.pumpAndSettle();
    expect(find.text('This phone cannot listen'), findsOneWidget);
  });

  testWidgets('the widget microphone opens Home listening; an assistant link searches', (tester) async {
    final taps = StreamController<Uri?>.broadcast();
    final voice = _Says('scissors');
    await pumpApp(tester, location: '/put', prefs: {'language': 'en'}, home: sampleHome(), voice: voice, homeScreen: _Taps(taps.stream));
    taps.add(Uri.parse('homefairy://listen'));
    await tester.pumpAndSettle();
    expect(voice.started, 1);
    expect(find.text('scissors'), findsOneWidget);
    taps.add(Uri.parse('homefairy://search?q=milk'));
    await tester.pumpAndSettle();
    expect(find.text('milk'), findsOneWidget);
    expect(find.text('Milk ×2'), findsOneWidget);
  });
}
