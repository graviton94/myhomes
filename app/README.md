# Home Fairy app (Flutter)

```sh
dart run tool/generate.dart          # design/tokens.json -> lib/design/tokens.g.dart (--check in CI)
python3 tool/build_fonts.py          # subset fonts into assets/fonts (--check in CI)
node tool/bake_fairy.mjs             # design/fairy/parts.svg -> assets/fairy/*.webp + launcher icons
flutter test --exclude-tags golden   # unit + widget tests
flutter test --tags golden --update-goldens   # screenshots -> test/goldens/screens/
(cd packages/core && dart test)      # pure rules
```

Generated files (`tokens.g.dart`, `lib/l10n/app_localizations*.dart`, fonts, fairy images) are committed and never edited by hand.
