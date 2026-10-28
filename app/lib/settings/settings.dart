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
  const AppSettings({
    this.language = AppLanguage.system,
    this.themeMode = ThemeMode.system,
    this.introSeen = false,
    this.started = false,
    this.smartSuggest = true,
  });

  final AppLanguage language;
  final ThemeMode themeMode;

  /// The three intro pages were shown (or skipped).
  final bool introSeen;

  /// The user got past the login screen (guest for now; accounts in Phase 3).
  final bool started;

  /// Ask the House Fairy's server for categories, icons and search matches
  /// (sends item names over the internet). Rules on the phone are used when off.
  final bool smartSuggest;

  AppSettings copyWith({AppLanguage? language, ThemeMode? themeMode, bool? introSeen, bool? started, bool? smartSuggest}) => AppSettings(
    language: language ?? this.language,
    themeMode: themeMode ?? this.themeMode,
    introSeen: introSeen ?? this.introSeen,
    started: started ?? this.started,
    smartSuggest: smartSuggest ?? this.smartSuggest,
  );
}

class SettingsController extends Notifier<AppSettings> {
  static const _languageKey = 'language';
  static const _themeKey = 'theme';
  static const _introKey = 'introSeen';
  static const _startedKey = 'started';
  static const _smartKey = 'smartSuggest';

  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  AppSettings build() {
    T byName<T extends Enum>(List<T> values, String? name, T fallback) => values.where((v) => v.name == name).firstOrNull ?? fallback;
    return AppSettings(
      language: byName(AppLanguage.values, _prefs.getString(_languageKey), AppLanguage.system),
      themeMode: byName(ThemeMode.values, _prefs.getString(_themeKey), ThemeMode.system),
      introSeen: _prefs.getBool(_introKey) ?? false,
      started: _prefs.getBool(_startedKey) ?? false,
      smartSuggest: _prefs.getBool(_smartKey) ?? true,
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

  Future<void> setIntroSeen(bool seen) async {
    state = state.copyWith(introSeen: seen);
    await _prefs.setBool(_introKey, seen);
  }

  Future<void> setSmartSuggest(bool on) async {
    state = state.copyWith(smartSuggest: on);
    await _prefs.setBool(_smartKey, on);
  }

  Future<void> startAsGuest() async {
    state = state.copyWith(started: true);
    await _prefs.setBool(_startedKey, true);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Build label shown in Settings. CI passes --dart-define=APP_VERSION=...
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');
