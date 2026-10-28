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
    this.expiryOn = false,
    this.returnsOn = false,
    this.lowStockOn = false,
    this.familyAlertsOn = false,
  });

  final AppLanguage language;
  final ThemeMode themeMode;

  /// The three intro pages were shown (or skipped).
  final bool introSeen;

  /// The user got past the login screen, signed in or as a guest.
  final bool started;

  /// Add-on features, off until switched on in Settings: use-by dates and
  /// their reminders, return dates for lent things, minimum amounts and the
  /// shopping list.
  final bool expiryOn;
  final bool returnsOn;
  final bool lowStockOn;

  /// Family changes in a shared home arrive as notifications.
  final bool familyAlertsOn;

  AppSettings copyWith({
    AppLanguage? language,
    ThemeMode? themeMode,
    bool? introSeen,
    bool? started,
    bool? expiryOn,
    bool? returnsOn,
    bool? lowStockOn,
    bool? familyAlertsOn,
  }) => AppSettings(
    language: language ?? this.language,
    themeMode: themeMode ?? this.themeMode,
    introSeen: introSeen ?? this.introSeen,
    started: started ?? this.started,
    expiryOn: expiryOn ?? this.expiryOn,
    returnsOn: returnsOn ?? this.returnsOn,
    lowStockOn: lowStockOn ?? this.lowStockOn,
    familyAlertsOn: familyAlertsOn ?? this.familyAlertsOn,
  );
}

class SettingsController extends Notifier<AppSettings> {
  static const _languageKey = 'language';
  static const _themeKey = 'theme';
  static const _introKey = 'introSeen';
  static const _startedKey = 'started';
  static const _expiryKey = 'feature.expiry';
  static const _returnsKey = 'feature.returns';
  static const _lowStockKey = 'feature.lowStock';
  static const _familyAlertsKey = 'feature.familyAlerts';

  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  AppSettings build() {
    T byName<T extends Enum>(List<T> values, String? name, T fallback) => values.where((v) => v.name == name).firstOrNull ?? fallback;
    return AppSettings(
      language: byName(AppLanguage.values, _prefs.getString(_languageKey), AppLanguage.system),
      themeMode: byName(ThemeMode.values, _prefs.getString(_themeKey), ThemeMode.system),
      introSeen: _prefs.getBool(_introKey) ?? false,
      started: _prefs.getBool(_startedKey) ?? false,
      expiryOn: _prefs.getBool(_expiryKey) ?? false,
      returnsOn: _prefs.getBool(_returnsKey) ?? false,
      lowStockOn: _prefs.getBool(_lowStockKey) ?? false,
      familyAlertsOn: _prefs.getBool(_familyAlertsKey) ?? false,
    );
  }

  Future<void> setExpiryOn(bool on) async {
    state = state.copyWith(expiryOn: on);
    await _prefs.setBool(_expiryKey, on);
  }

  Future<void> setReturnsOn(bool on) async {
    state = state.copyWith(returnsOn: on);
    await _prefs.setBool(_returnsKey, on);
  }

  Future<void> setFamilyAlertsOn(bool on) async {
    state = state.copyWith(familyAlertsOn: on);
    await _prefs.setBool(_familyAlertsKey, on);
  }

  Future<void> setLowStockOn(bool on) async {
    state = state.copyWith(lowStockOn: on);
    await _prefs.setBool(_lowStockKey, on);
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

  /// Past the login screen. That screen already offered sign-in, so the
  /// one-time sign-in sheet on Home is not needed either.
  Future<void> start() async {
    state = state.copyWith(started: true);
    await _prefs.setBool(_startedKey, true);
    await _prefs.setBool(_loginAskedKey, true);
  }

  /// Settings > Show intro again: the intro, then the login screen for guests.
  Future<void> replayIntro({required bool signedIn}) async {
    state = state.copyWith(introSeen: false, started: signedIn ? null : false);
    await _prefs.setBool(_introKey, false);
    if (!signedIn) await _prefs.setBool(_startedKey, false);
  }

  /// A guest goes back to the login screen (things on the phone stay).
  Future<void> leaveGuest() async {
    state = state.copyWith(started: false);
    await _prefs.setBool(_startedKey, false);
  }

  static const _loginAskedKey = 'loginAsked';
  static const _planPhotoKey = 'plan.photo';
  static const _planPhotoScaleKey = 'plan.photoScale';
  static const _planPhotoShownKey = 'plan.photoShown';

  /// A floor-plan photo to trace rooms over, kept on this phone only.
  String? get planPhoto => _prefs.getString(_planPhotoKey);
  double get planPhotoScale => _prefs.getDouble(_planPhotoScaleKey) ?? 1;
  bool get planPhotoShown => _prefs.getBool(_planPhotoShownKey) ?? true;

  Future<void> setPlanPhoto(String? path) async {
    path == null ? await _prefs.remove(_planPhotoKey) : await _prefs.setString(_planPhotoKey, path);
    await _prefs.setBool(_planPhotoShownKey, true);
  }

  Future<void> setPlanPhotoScale(double v) => _prefs.setDouble(_planPhotoScaleKey, v);

  Future<void> setPlanPhotoShown(bool v) => _prefs.setBool(_planPhotoShownKey, v);

  /// Guests from before the login screen offered sign-in are asked once on Home.
  bool get loginAsked => _prefs.getBool(_loginAskedKey) ?? false;

  Future<void> setLoginAsked() => _prefs.setBool(_loginAskedKey, true);
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Build label shown in Settings. CI passes --dart-define=APP_VERSION=...
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');
