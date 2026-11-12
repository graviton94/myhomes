import 'dart:async';
import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/app_update.dart';
import 'data/accounts.dart';
import 'data/barcode.dart';
import 'data/home_store.dart';
import 'data/home_widget_sync.dart';
import 'data/household.dart';
import 'data/receipt_reader.dart';
import 'data/voice.dart';
import 'data/reminders.dart';
import 'data/shop.dart';
import 'data/smart_suggest.dart';
import 'settings/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phones only, upright (user decision 2026-11-04).
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  final docs = await getApplicationDocumentsDirectory();
  // Firebase only when the build carries its settings (CI builds do). The app
  // works fully without it; suggestions just fall back to the rules.
  var suggest = const NoSuggest() as SmartSuggest;
  var accounts = const NoAccounts() as Accounts;
  var households = const NoHouseholds() as Households;
  var barcodes = const NoBarcodeLookup() as BarcodeLookup;
  var shop = const NoShop() as Shop;
  if (FirebaseConfig.available) {
    try {
      await Firebase.initializeApp(options: FirebaseConfig.options);
      // App Check (Play Integrity): calls to our server carry proof that they
      // come from this app as the store installed it. Until the app is
      // registered in the Firebase console the proof is simply missing, and
      // the server does not ask for it yet (enforce_app_check in main.py).
      unawaited(
        FirebaseAppCheck.instance
            .activate(providerAndroid: const AndroidPlayIntegrityProvider())
            .catchError((Object e) => debugPrint('app check: ${e.runtimeType}')),
      );
      suggest = FunctionsSuggest();
      accounts = FirebaseAccounts();
      barcodes = FunctionsBarcodeLookup();
      if (Platform.isAndroid) shop = PlayShop();
      households = FirebaseHouseholds(photoDir: Directory('${docs.path}/photos'));
      // Crashes and uncaught errors from release builds go to Crashlytics.
      if (kReleaseMode) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }
    } catch (e) {
      debugPrint('Firebase not available: ${e.runtimeType}');
    }
  }
  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        homeRepositoryProvider.overrideWithValue(FileHomeRepository(Directory('${docs.path}/home'))),
        photoDirProvider.overrideWithValue(Directory('${docs.path}/photos')),
        smartSuggestBackendProvider.overrideWithValue(suggest),
        accountsProvider.overrideWithValue(accounts),
        householdsProvider.overrideWithValue(households),
        barcodeLookupProvider.overrideWithValue(barcodes),
        shopProvider.overrideWithValue(shop),
        ...householdOverrides,
        if (Platform.isAndroid) remindersBackendProvider.overrideWithValue(PhoneReminders()),
        if (Platform.isAndroid) homeScreenWidgetProvider.overrideWithValue(AndroidHomeScreenWidget()),
        if (Platform.isAndroid) receiptReaderProvider.overrideWithValue(MlKitReceiptReader()),
        if (Platform.isAndroid) voiceProvider.overrideWithValue(PhoneVoice()),
        if (Platform.isAndroid) appUpdaterProvider.overrideWithValue(PlayUpdates()),
      ],
      child: const HomeFairyApp(),
    ),
  );
}
