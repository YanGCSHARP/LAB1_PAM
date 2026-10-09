import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_typography.dart';
import 'design_tokens.dart';

/// Colors Material 3 has no slot for: income, expense, the two budget
/// thresholds and the category scale.
///
/// Reading them from the theme keeps widgets free of brightness checks.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.income,
    required this.expense,
    required this.warning,
    required this.danger,
    required this.border,
    required this.borderStrong,
    required this.textMuted,
    required this.accentPressed,
    required this.categories,
    required this.categoryFallback,
  });

  final Color income;
  final Color expense;

  /// Budget progress in the 90%–99% band.
  final Color warning;

  /// Budget progress at or above 100%.
  final Color danger;

  /// Hairline separators and card outlines.
  final Color border;

  /// Outlines that must stay visible on their own, e.g. an outlined button.
  final Color borderStrong;

  final Color textMuted;
  final Color accentPressed;

  final Map<String, Color> categories;
  final Color categoryFallback;

  Color category(String key) => categories[key] ?? categoryFallback;

  static const AppSemanticColors dark = AppSemanticColors(
    income: AppPalette.incomeDark,
    expense: AppPalette.expenseDark,
    warning: AppPalette.warningDark,
    danger: AppPalette.dangerDark,
    border: AppPalette.darkBorder,
    borderStrong: AppPalette.darkBorderStrong,
    textMuted: AppPalette.darkTextMuted,
    accentPressed: AppPalette.accentDarkPressed,
    categories: AppPalette.categoriesDark,
    categoryFallback: AppPalette.categoryFallbackDark,
  );

  static const AppSemanticColors light = AppSemanticColors(
    income: AppPalette.incomeLight,
    expense: AppPalette.expenseLight,
    warning: AppPalette.warningLight,
    danger: AppPalette.dangerLight,
    border: AppPalette.lightBorder,
    borderStrong: AppPalette.lightBorderStrong,
    textMuted: AppPalette.lightTextMuted,
    accentPressed: AppPalette.accentLightPressed,
    categories: AppPalette.categoriesLight,
    categoryFallback: AppPalette.categoryFallbackLight,
  );

  @override
  AppSemanticColors copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    Color? danger,
    Color? border,
    Color? borderStrong,
    Color? textMuted,
    Color? accentPressed,
    Map<String, Color>? categories,
    Color? categoryFallback,
  }) {
    return AppSemanticColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textMuted: textMuted ?? this.textMuted,
      accentPressed: accentPressed ?? this.accentPressed,
      categories: categories ?? this.categories,
      categoryFallback: categoryFallback ?? this.categoryFallback,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }
    return AppSemanticColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      categories: t < 0.5 ? categories : other.categories,
      categoryFallback: Color.lerp(
        categoryFallback,
        other.categoryFallback,
        t,
      )!,
    );
  }
}

/// `context.colors`, `context.semantic`, `context.money` — the three lookups
/// every widget needs, without repeating `Theme.of(context)` everywhere.
extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.dark;

  AppMoneyStyles get money =>
      Theme.of(this).extension<AppMoneyStyles>() ??
      AppMoneyStyles.of(AppPalette.darkText);
}

/// The two themes of the app. Dark is the primary one.
abstract final class AppTheme {
  static ThemeData get dark => _build(_darkScheme, AppSemanticColors.dark);

  static ThemeData get light => _build(_lightScheme, AppSemanticColors.light);

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.accentDark,
    onPrimary: AppPalette.onAccentDark,
    primaryContainer: Color(0xFF16233A),
    onPrimaryContainer: Color(0xFFBBD3FF),
    secondary: AppPalette.darkTextMuted,
    onSecondary: AppPalette.darkBackground,
    secondaryContainer: AppPalette.darkSurfaceHighest,
    onSecondaryContainer: AppPalette.darkText,
    tertiary: AppPalette.incomeDark,
    onTertiary: Color(0xFF05130D),
    tertiaryContainer: Color(0xFF12291F),
    onTertiaryContainer: Color(0xFF8FD9BB),
    error: AppPalette.expenseDark,
    onError: Color(0xFF2A0A08),
    errorContainer: Color(0xFF3A1512),
    onErrorContainer: Color(0xFFFFD7D4),
    surface: AppPalette.darkBackground,
    onSurface: AppPalette.darkText,
    surfaceDim: AppPalette.darkBackground,
    surfaceBright: AppPalette.darkSurfaceHighest,
    surfaceContainerLowest: Color(0xFF0A0B0A),
    surfaceContainerLow: AppPalette.darkSurface,
    surfaceContainer: Color(0xFF1B1E1C),
    surfaceContainerHigh: AppPalette.darkSurfaceElevated,
    surfaceContainerHighest: AppPalette.darkSurfaceHighest,
    onSurfaceVariant: AppPalette.darkTextMuted,
    outline: AppPalette.darkBorderStrong,
    outlineVariant: AppPalette.darkBorder,
    inverseSurface: AppPalette.darkText,
    onInverseSurface: AppPalette.darkBackground,
    inversePrimary: AppPalette.accentLight,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.accentLight,
    onPrimary: AppPalette.onAccentLight,
    primaryContainer: Color(0xFFE4ECFB),
    onPrimaryContainer: Color(0xFF10358B),
    secondary: AppPalette.lightTextMuted,
    onSecondary: AppPalette.lightSurface,
    secondaryContainer: AppPalette.lightSurfaceHighest,
    onSecondaryContainer: AppPalette.lightText,
    tertiary: AppPalette.incomeLight,
    onTertiary: AppPalette.lightSurface,
    tertiaryContainer: Color(0xFFDDEFE7),
    onTertiaryContainer: Color(0xFF1B5540),
    error: AppPalette.expenseLight,
    onError: AppPalette.lightSurface,
    errorContainer: Color(0xFFFBE4E3),
    onErrorContainer: Color(0xFF7A2621),
    surface: AppPalette.lightBackground,
    onSurface: AppPalette.lightText,
    surfaceDim: Color(0xFFE9EAE7),
    surfaceBright: AppPalette.lightSurface,
    surfaceContainerLowest: AppPalette.lightSurface,
    surfaceContainerLow: AppPalette.lightSurface,
    surfaceContainer: Color(0xFFF3F4F1),
    surfaceContainerHigh: Color(0xFFEFF0ED),
    surfaceContainerHighest: AppPalette.lightSurfaceHighest,
    onSurfaceVariant: AppPalette.lightTextMuted,
    outline: AppPalette.lightBorderStrong,
    outlineVariant: AppPalette.lightBorder,
    inverseSurface: AppPalette.lightText,
    onInverseSurface: AppPalette.lightBackground,
    inversePrimary: AppPalette.accentDark,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static ThemeData _build(ColorScheme scheme, AppSemanticColors semantic) {
    final textTheme = AppTypography.textTheme(
      scheme.onSurface,
      semantic.textMuted,
    );
    final money = AppMoneyStyles.of(scheme.onSurface);

    return ThemeData(
      colorScheme: scheme,
      brightness: scheme.brightness,
      fontFamily: AppTypography.family,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      extensions: [semantic, money],

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleSpacing: Insets.page,
        titleTextStyle: textTheme.headlineSmall,
        iconTheme: IconThemeData(color: scheme.onSurface, size: IconSizes.lg),
      ),

      // Cards are one step above the background and outlined rather than
      // shadowed: on a near-black ground a shadow is invisible anyway.
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Corners.cardRadius,
          side: BorderSide(color: semantic.border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        hintStyle: textTheme.bodyMedium?.copyWith(color: semantic.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: semantic.textMuted),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
        ),
        prefixIconColor: semantic.textMuted,
        suffixIconColor: semantic.textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: Corners.fieldRadius,
          borderSide: BorderSide(color: semantic.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Corners.fieldRadius,
          borderSide: BorderSide(color: semantic.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Corners.fieldRadius,
          borderSide: BorderSide(color: scheme.primary, width: Strokes.focus),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Corners.fieldRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Corners.fieldRadius,
          borderSide: BorderSide(color: scheme.error, width: Strokes.focus),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: Corners.fieldRadius,
          borderSide: BorderSide(color: semantic.border),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: Corners.buttonRadius,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: semantic.borderStrong),
          shape: const RoundedRectangleBorder(
            borderRadius: Corners.buttonRadius,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: Corners.buttonRadius,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        extendedTextStyle: textTheme.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: Corners.buttonRadius),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        side: BorderSide(color: semantic.border),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.sm,
        ),
        shape: const RoundedRectangleBorder(borderRadius: Corners.chipRadius),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                )
              : textTheme.labelMedium?.copyWith(color: semantic.textMuted),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: IconSizes.lg,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : semantic.textMuted,
          ),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: semantic.border,
        space: Strokes.hairline,
        thickness: Strokes.hairline,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: Insets.lg),
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: semantic.textMuted,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium,
        actionTextColor: scheme.primary,
        elevation: 0,
        insetPadding: const EdgeInsets.all(Insets.lg),
        shape: RoundedRectangleBorder(
          borderRadius: Corners.cardRadius,
          side: BorderSide(color: semantic.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: Corners.cardRadius,
          side: BorderSide(color: semantic.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: semantic.borderStrong,
        shape: const RoundedRectangleBorder(borderRadius: Corners.sheetRadius),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: Strokes.progress,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: Corners.chipRadius,
          border: Border.all(color: semantic.border),
        ),
        textStyle: textTheme.labelMedium,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStatePropertyAll(semantic.border),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: scheme.surfaceContainerLow,
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          foregroundColor: semantic.textMuted,
          side: BorderSide(color: semantic.border),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: Corners.buttonRadius,
          ),
        ),
      ),
    );
  }
}
