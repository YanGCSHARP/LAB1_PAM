import 'package:flutter/material.dart';

/// Inter-based type scale.
///
/// Hierarchy is carried by size and weight, not by tinting everything
/// differently: money is the largest thing on a screen, section titles sit
/// clearly below it, and metadata is small and muted.
abstract final class AppTypography {
  static const String family = 'Inter';

  /// Optical size cut used for large numerals only.
  static const String displayFamily = 'InterDisplay';

  /// Monospaced digits. Without this a column of amounts jitters as the digits
  /// change width, which makes a transaction list look ragged.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextTheme textTheme(Color text, Color muted) {
    TextStyle base(
      double size,
      FontWeight weight, {
      double? tracking,
      double? height,
      Color? color,
      String? fontFamily,
    }) {
      return TextStyle(
        fontFamily: fontFamily ?? family,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: tracking,
        height: height,
        color: color ?? text,
      );
    }

    return TextTheme(
      // Hero numbers — the account balance on the dashboard.
      displayLarge: base(
        40,
        FontWeight.w600,
        tracking: -1.2,
        height: 1.04,
        fontFamily: displayFamily,
      ),
      displayMedium: base(
        34,
        FontWeight.w600,
        tracking: -1,
        height: 1.06,
        fontFamily: displayFamily,
      ),
      displaySmall: base(
        28,
        FontWeight.w600,
        tracking: -0.6,
        height: 1.1,
        fontFamily: displayFamily,
      ),

      // Screen and section headings.
      headlineLarge: base(24, FontWeight.w600, tracking: -0.4, height: 1.2),
      headlineMedium: base(21, FontWeight.w600, tracking: -0.3, height: 1.2),
      headlineSmall: base(19, FontWeight.w600, tracking: -0.2, height: 1.25),
      titleLarge: base(18, FontWeight.w600, tracking: -0.2, height: 1.3),
      titleMedium: base(16, FontWeight.w600, tracking: -0.1, height: 1.3),
      titleSmall: base(15, FontWeight.w600, height: 1.3),

      // Reading text.
      bodyLarge: base(16, FontWeight.w400, height: 1.45),
      bodyMedium: base(15, FontWeight.w400, height: 1.45),
      bodySmall: base(13, FontWeight.w400, height: 1.35, color: muted),

      // Controls and metadata.
      labelLarge: base(15, FontWeight.w600, height: 1.2),
      labelMedium: base(12, FontWeight.w500, height: 1.2),
      labelSmall: base(11, FontWeight.w500, height: 1.2, color: muted),
    );
  }
}

/// Money styles, kept out of [TextTheme] because they are a separate axis:
/// any of them can appear at several places in the hierarchy.
@immutable
class AppMoneyStyles extends ThemeExtension<AppMoneyStyles> {
  const AppMoneyStyles({
    required this.hero,
    required this.large,
    required this.medium,
    required this.small,
  });

  /// Total balance at the top of the dashboard.
  final TextStyle hero;

  /// Account card balance, amount on a transaction detail screen.
  final TextStyle large;

  /// Amount in a transaction row, totals inside cards.
  final TextStyle medium;

  /// Legend, budget captions.
  final TextStyle small;

  factory AppMoneyStyles.of(Color text) {
    TextStyle money(
      double size,
      FontWeight weight, {
      double? tracking,
      String family = AppTypography.family,
    }) {
      return TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: tracking,
        height: 1.15,
        color: text,
        fontFeatures: AppTypography.tabular,
      );
    }

    return AppMoneyStyles(
      hero: money(
        36,
        FontWeight.w600,
        tracking: -1.2,
        family: AppTypography.displayFamily,
      ),
      large: money(
        24,
        FontWeight.w600,
        tracking: -0.6,
        family: AppTypography.displayFamily,
      ),
      medium: money(16, FontWeight.w600, tracking: -0.1),
      small: money(13, FontWeight.w500),
    );
  }

  @override
  AppMoneyStyles copyWith({
    TextStyle? hero,
    TextStyle? large,
    TextStyle? medium,
    TextStyle? small,
  }) {
    return AppMoneyStyles(
      hero: hero ?? this.hero,
      large: large ?? this.large,
      medium: medium ?? this.medium,
      small: small ?? this.small,
    );
  }

  @override
  AppMoneyStyles lerp(ThemeExtension<AppMoneyStyles>? other, double t) {
    if (other is! AppMoneyStyles) {
      return this;
    }
    return AppMoneyStyles(
      hero: TextStyle.lerp(hero, other.hero, t)!,
      large: TextStyle.lerp(large, other.large, t)!,
      medium: TextStyle.lerp(medium, other.medium, t)!,
      small: TextStyle.lerp(small, other.small, t)!,
    );
  }
}
