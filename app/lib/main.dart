import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/accounts.dart';
import 'data/home_store.dart';
import 'data/reminders.dart';
import 'data/smart_suggest.dart';
import 'settings/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final docs = await getApplicationDocumentsDirectory();
  // Firebase only when the build carries its settings (CI builds do). The app
  // works fully without it; suggestions just fall back to the rules.
  var suggest = const NoSuggest() as SmartSuggest;
  var accounts = const NoAccounts() as Accounts;
  if (FirebaseConfig.available) {
    try {
      await Firebase.initializeApp(options: FirebaseConfig.options);
      suggest = FunctionsSuggest();
      accounts = FirebaseAccounts();
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
        if (Platform.isAndroid) remindersBackendProvider.overrideWithValue(PhoneReminders()),
      ],
      child: const HomeFairyApp(),
    ),
  );
}
