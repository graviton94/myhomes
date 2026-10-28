import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../l10n/keep_words.g.dart';

/// Screen text for [locale]. Korean lines break between words, not in the
/// middle of one ("있어 / 야 해요"); Flutter has no word-break setting.
AppLocalizations localizationsFor(Locale locale) {
  final l = lookupAppLocalizations(locale);
  return locale.languageCode == 'ko' ? KeepWordsLocalizations(l) : l;
}

/// Replaces AppLocalizations.delegate in the app.
class KeepWordsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const KeepWordsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(localizationsFor(locale));

  @override
  bool isSupported(Locale locale) => AppLocalizations.delegate.isSupported(locale);

  @override
  bool shouldReload(KeepWordsDelegate old) => false;
}
