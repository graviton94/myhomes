import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opened in main() before runApp and injected with an override.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('prefsProvider not overridden'));

/// App language choice. [system] follows the phone; English is the fallback.
enum AppLanguage {
  system(null),
  en(Locale('en')),
  ko(Locale('ko'));

  const AppLanguage(this.locale);
  final Locale? locale;
}

@immutable
class AppSettings {
  const AppSettings({this.language = AppLanguage.system, this.themeMode = ThemeMode.system});

  final AppLanguage language;
  final ThemeMode themeMode;

  AppSettings copyWith({AppLanguage? language, ThemeMode? themeMode}) =>
      AppSettings(language: language ?? this.language, themeMode: themeMode ?? this.themeMode);
}

class SettingsController extends Notifier<AppSettings> {
  static const _languageKey = 'language';
  static const _themeKey = 'theme';

  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  AppSettings build() {
    T byName<T extends Enum>(List<T> values, String? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    return AppSettings(
      language: byName(AppLanguage.values, _prefs.getString(_languageKey), AppLanguage.system),
      themeMode: byName(ThemeMode.values, _prefs.getString(_themeKey), ThemeMode.system),
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    await _prefs.setString(_languageKey, language.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_themeKey, mode.name);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Build label shown in Settings. CI passes --dart-define=APP_VERSION=...
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');
