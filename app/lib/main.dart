import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/home_store.dart';
import 'settings/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final docs = await getApplicationDocumentsDirectory();
  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        homeRepositoryProvider.overrideWithValue(FileHomeRepository(Directory('${docs.path}/home'))),
        photoDirProvider.overrideWithValue(Directory('${docs.path}/photos')),
      ],
      child: const HomeFairyApp(),
    ),
  );
}
