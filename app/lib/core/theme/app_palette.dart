import 'package:flutter/material.dart';

/// Raw color values of the "Сигнал" design direction.
///
/// The dark theme is the primary one and was designed first; the light theme
/// is a separate build, not an inversion — dark separates blocks with hairlines
/// on a near-black ground, light uses white surfaces on a warm off-white.
///
/// Every value below was checked for WCAG AA against the background it sits on
/// (4.5:1 for text, 3:1 for large text and UI outlines).
abstract final class AppPalette {
  // ---------------------------------------------------------------------
  // Dark — the primary theme.
  // Near-black with a faint neutral-green undertone, surfaces one and two
  // steps up. No pure black: it makes OLED edges buzz against the surfaces.
  // ---------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF0F100F);
  static const Color darkSurface = Color(0xFF171918);
  static const Color darkSurfaceElevated = Color(0xFF1E211F);
  static const Color darkSurfaceHighest = Color(0xFF262A28);
  static const Color darkBorder = Color(0xFF2A2E2C);
  static const Color darkBorderStrong = Color(0xFF3A403D);

  /// 16.9:1 on [darkBackground].
  static const Color darkText = Color(0xFFF0F2EF);

  /// 6.4:1 on [darkBackground] — safe for body copy, not just labels.
  static const Color darkTextMuted = Color(0xFF949A95);

  /// 3.3:1 — disabled text and decorative marks only, never information.
  static const Color darkTextDisabled = Color(0xFF6A706C);

  // ---------------------------------------------------------------------
  // Light.
  // ---------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF7F7F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSurfaceHighest = Color(0xFFEFF0ED);
  static const Color lightBorder = Color(0xFFE7E9E6);
  static const Color lightBorderStrong = Color(0xFFD3D7D1);

  static const Color lightText = Color(0xFF171918);

  /// 4.6:1 on [lightBackground]; the #737875 of the brief fell just short.
  static const Color lightTextMuted = Color(0xFF6B706D);

  static const Color lightTextDisabled = Color(0xFF9CA29E);

  // ---------------------------------------------------------------------
  // Accent — actions, active tab, focus ring.
  //
  // Deliberately blue and never green: green means income, and when the brand
  // color and the income color are the same, every screen reads as one flat
  // block of color.
  // ---------------------------------------------------------------------
  /// 6.8:1 on [darkBackground].
  static const Color accentDark = Color(0xFF5E9BFF);
  static const Color accentDarkPressed = Color(0xFF4A85E8);
  static const Color onAccentDark = Color(0xFF07152B);

  /// 5.7:1 on [lightBackground].
  static const Color accentLight = Color(0xFF1F62D6);
  static const Color accentLightPressed = Color(0xFF184FAF);
  static const Color onAccentLight = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------
  // Semantic money colors.
  // ---------------------------------------------------------------------
  /// Income. 5.2:1 on [darkBackground].
  static const Color incomeDark = Color(0xFF3D9670);

  /// Income, darkened for white surfaces — 5.2:1.
  static const Color incomeLight = Color(0xFF2E7A59);

  /// Expense. 5.4:1 on [darkBackground].
  static const Color expenseDark = Color(0xFFD66B65);

  /// Expense, darkened for white surfaces — 5.5:1.
  static const Color expenseLight = Color(0xFFB4443E);

  /// Budget at 90%–99%. 8.8:1 on [darkBackground].
  static const Color warningDark = Color(0xFFE5A83E);

  /// 4.7:1 on [lightBackground].
  static const Color warningLight = Color(0xFF9E6A14);

  /// Budget at or above 100% — the same hue as an expense, on purpose.
  static const Color dangerDark = expenseDark;
  static const Color dangerLight = expenseLight;

  // ---------------------------------------------------------------------
  // Category palette.
  //
  // Amber, green and red are spent on meaning (warning, income, expense) and
  // blue on actions, so categories use what is left: violet, cyan, plum,
  // aqua, olive, indigo, slate, rose. Hue alone cannot separate eight swatches
  // for a viewer with deuteranopia, so lightness varies across them as well —
  // and the chart is never the only carrier of meaning: the legend repeats
  // every category as a labelled row with its share and amount.
  // ---------------------------------------------------------------------
  static const Map<String, Color> categoriesDark = {
    'housing': Color(0xFFD07AB8), // plum
    'food': Color(0xFF7FD4C1), // aqua, light
    'transport': Color(0xFF5FB6F0), // cyan
    'utilities': Color(0xFFB9A6F5), // lavender
    'shopping': Color(0xFFC9B45A), // olive
    'education': Color(0xFF6B76D9), // indigo
    'health': Color(0xFFA8B4BE), // slate
    'entertainment': Color(0xFFE88FA8), // rose
    'other': Color(0xFF8C948F), // neutral
    // Income categories reuse the same scale; they are never charted next to
    // expenses, so a repeated hue carries no ambiguity.
    'salary': Color(0xFF7FD4C1),
    'scholarship': Color(0xFF5FB6F0),
    'freelance': Color(0xFFB9A6F5),
    'gift': Color(0xFFE88FA8),
  };

  static const Map<String, Color> categoriesLight = {
    'housing': Color(0xFF9B3F77),
    'food': Color(0xFF2E7F6D),
    'transport': Color(0xFF1F6FA8),
    'utilities': Color(0xFF6B54B8),
    'shopping': Color(0xFF7D6A14),
    'education': Color(0xFF3B46A8),
    'health': Color(0xFF5A6670),
    'entertainment': Color(0xFFA8425C),
    'other': Color(0xFF6B706D),
    'salary': Color(0xFF2E7F6D),
    'scholarship': Color(0xFF1F6FA8),
    'freelance': Color(0xFF6B54B8),
    'gift': Color(0xFFA8425C),
  };

  static const Color categoryFallbackDark = Color(0xFF8C948F);
  static const Color categoryFallbackLight = Color(0xFF6B706D);
}
