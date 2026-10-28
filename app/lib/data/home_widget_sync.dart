import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import '../widgets/dday_badge.dart';
import '../widgets/header_line.dart';
import '../widgets/keep_words.dart';
import 'home_store.dart';

/// The lines the home screen widget shows (Android layout home_fairy_widget).
Map<String, String> widgetLines(AppLocalizations l, HomeData d, AppSettings s, DateTime now) {
  final change = lastChange(d);
  final urgent = byExpiry(d, now).where((e) => e.$2.isUrgent).toList();
  final returns = returnsDue(d, now).where((e) => e.$2.isUrgent).toList();
  final low = lowStock(d);
  final counts = [
    if (s.expiryOn && urgent.isNotEmpty) l.widgetUseFirst(urgent.length),
    if (s.lowStockOn && low.isNotEmpty) l.widgetToBuy(low.length),
    if (s.returnsOn && returns.isNotEmpty) l.widgetGetBack(returns.length),
  ];
  // Under the counts: what to use first, else what to buy.
  final detail = s.expiryOn && urgent.isNotEmpty
      ? [for (final (item, status) in urgent.take(3)) '${item.name} ${expiryLabel(l, status)}']
      : [
          if (s.lowStockOn)
            for (final item in low.take(3)) item.name,
        ];
  return {
    'title': l.appTitle,
    'change': change == null ? '' : '${changeText(l, d, change)} · ${agoText(l, change.at, now)}',
    'search': l.searchHint,
    'counts': counts.isEmpty ? l.widgetSummary(d.items.length, d.spaces.length) : counts.join(' · '),
    'detail': detail.join(' · '),
  };
}

/// Where the widget's lines go. Phones only; tests use [NoHomeScreenWidget].
abstract interface class HomeScreenWidget {
  Future<void> show(Map<String, String> lines);

  /// Taps that opened the app from the widget (the search box sends homefairy://search).
  Stream<Uri?> get taps;
  Future<Uri?> launchedFrom();
}

class NoHomeScreenWidget implements HomeScreenWidget {
  const NoHomeScreenWidget();

  @override
  Future<void> show(Map<String, String> lines) async {}

  @override
  Stream<Uri?> get taps => const Stream.empty();

  @override
  Future<Uri?> launchedFrom() async => null;
}

class AndroidHomeScreenWidget implements HomeScreenWidget {
  @override
  Future<void> show(Map<String, String> lines) async {
    for (final e in lines.entries) {
      await HomeWidget.saveWidgetData<String>(e.key, e.value);
    }
    await HomeWidget.updateWidget(qualifiedAndroidName: 'io.github.graviton94.homefairy.HomeFairyWidget');
  }

  @override
  Stream<Uri?> get taps => HomeWidget.widgetClicked;

  @override
  Future<Uri?> launchedFrom() => HomeWidget.initiallyLaunchedFromHomeWidget();
}

/// Overridden in main() on Android.
final homeScreenWidgetProvider = Provider<HomeScreenWidget>((ref) => const NoHomeScreenWidget());

/// Keeps the widget in step with the home and the extras. Watched once by the app.
final homeWidgetSyncProvider = Provider<void>((ref) {
  final backend = ref.watch(homeScreenWidgetProvider);
  if (backend is NoHomeScreenWidget) return;
  final d = ref.watch(homeProvider).value;
  final settings = ref.watch(settingsProvider);
  if (d == null) return;
  final locale = settings.language.locale ?? PlatformDispatcher.instance.locale;
  final l = localizationsFor(
    AppLocalizations.supportedLocales.contains(Locale(locale.languageCode)) ? Locale(locale.languageCode) : const Locale('en'),
  );
  final timer = Timer(const Duration(seconds: 1), () {
    backend.show(widgetLines(l, d, settings, DateTime.now())).catchError((Object e) => debugPrint('widget: ${e.runtimeType}'));
  });
  ref.onDispose(timer.cancel);
});

/// Asks Home to put the cursor in the search box (the widget's search was tapped).
class SearchRequest extends Notifier<int> {
  @override
  int build() => 0;

  void ask() => state++;
}

final searchRequestProvider = NotifierProvider<SearchRequest, int>(SearchRequest.new);
