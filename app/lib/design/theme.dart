import 'package:flutter/material.dart';

import 'tokens.g.dart';

/// Extra colour roles that Material's ColorScheme has no slot for
/// (soft backgrounds and readable "ink" text on them).
@immutable
class HfColors extends ThemeExtension<HfColors> {
  const HfColors(this.c);

  final AppColors c;

  static AppColors of(BuildContext context) => Theme.of(context).extension<HfColors>()!.c;

  @override
  HfColors copyWith({AppColors? c}) => HfColors(c ?? this.c);

  @override
  HfColors lerp(HfColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    primaryContainer: c.primarySoft,
    onPrimaryContainer: c.primaryInk,
    secondary: c.secondary,
    onSecondary: c.onPrimary,
    secondaryContainer: c.secondarySoft,
    onSecondaryContainer: c.secondaryInk,
    tertiary: c.accent,
    onTertiary: c.fg,
    tertiaryContainer: c.accentSoft,
    onTertiaryContainer: c.accentInk,
    error: c.danger,
    onError: c.onPrimary,
    errorContainer: c.dangerSoft,
    onErrorContainer: c.dangerInk,
    surface: c.bg,
    onSurface: c.fg,
    onSurfaceVariant: c.mutedFg,
    surfaceContainerLowest: c.card,
    surfaceContainerLow: c.card,
    surfaceContainer: c.card,
    surfaceContainerHigh: c.muted,
    surfaceContainerHighest: c.muted,
    outline: c.border,
    outlineVariant: c.border,
    scrim: c.scrim,
  );

  TextStyle ink(TextStyle s, [Color? color]) => s.copyWith(color: color ?? c.fg);
  final text = TextTheme(
    displaySmall: ink(AppType.display),
    headlineSmall: ink(AppType.title),
    titleLarge: ink(AppType.title),
    titleMedium: ink(AppType.heading),
    titleSmall: ink(AppType.label),
    bodyLarge: ink(AppType.body),
    bodyMedium: ink(AppType.body.copyWith(fontSize: 15)),
    bodySmall: ink(AppType.caption, c.mutedFg),
    labelLarge: ink(AppType.label),
    labelMedium: ink(AppType.label.copyWith(fontSize: 13)),
    labelSmall: ink(AppType.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
  );

  final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));
  const minSize = Size(AppSize.touch, AppSize.touch);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.bodyFallback,
    textTheme: text,
    extensions: [HfColors(c)],
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.fg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: ink(AppType.title),
    ),
    cardTheme: CardThemeData(
      color: c.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: c.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: minSize, shape: rounded, textStyle: AppType.label),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minSize,
        shape: rounded,
        foregroundColor: c.fg,
        side: BorderSide(color: c.border),
        textStyle: AppType.label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: minSize, foregroundColor: c.link, textStyle: AppType.label),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: minSize)),
    chipTheme: ChipThemeData(
      backgroundColor: c.card,
      selectedColor: c.primarySoft,
      side: BorderSide(color: c.border),
      labelStyle: AppType.label.copyWith(fontSize: 13, color: c.mutedFg),
      secondaryLabelStyle: AppType.label.copyWith(fontSize: 13, color: c.primaryInk),
      shape: const StadiumBorder(),
      showCheckmark: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: c.primarySoft,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => AppType.caption.copyWith(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
          color: s.contains(WidgetState.selected) ? c.primaryInk : c.mutedFg,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? c.primaryInk : c.mutedFg),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.card,
      hintStyle: AppType.body.copyWith(color: c.mutedFg, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: c.primary, width: 2)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.fg,
      contentTextStyle: AppType.body.copyWith(color: c.bg, fontSize: 15),
      shape: rounded,
    ),
    dividerTheme: DividerThemeData(color: c.border, space: 1),
    listTileTheme: ListTileThemeData(minTileHeight: AppSize.touch + 8, iconColor: c.mutedFg),
  );
}
