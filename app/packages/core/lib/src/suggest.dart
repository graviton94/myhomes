/// How sure a model suggestion must be before the app uses it. Measured on
/// the evaluation sets in eval/ (see docs/next.md): at 0.7 or more the
/// decision model was right 95-100% of the time.
library;

enum SuggestLevel {
  /// Apply it as the default (the person can still change it).
  auto,

  /// Offer it as one of a few chips.
  chips,

  /// Too unsure: fall back to the rules.
  ignore,
}

const double autoConfidence = 0.7;
const double chipConfidence = 0.4;

SuggestLevel suggestLevel(double confidence) {
  if (confidence >= autoConfidence) return SuggestLevel.auto;
  if (confidence >= chipConfidence) return SuggestLevel.chips;
  return SuggestLevel.ignore;
}
