import 'package:flutter/material.dart';

/// Spacing scale. Every gap in the app is one of these values — no ad-hoc
/// paddings, so vertical rhythm stays on a 4 pt grid.
abstract final class Insets {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;

  /// Horizontal page margin. 16 keeps content readable at 360 px.
  static const double page = lg;

  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(
    horizontal: page,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}

/// Corner radii. Deliberately different per level: a chip is not as round as a
/// sheet, and the step between levels is what makes the system readable.
abstract final class Corners {
  static const double chip = 10;
  static const double field = 12;
  static const double button = 12;
  static const double card = 14;
  static const double sheet = 20;

  /// Fully rounded — avatars, the income/expense switch, progress tracks.
  static const double pill = 999;

  static const BorderRadius chipRadius = BorderRadius.all(
    Radius.circular(chip),
  );
  static const BorderRadius fieldRadius = BorderRadius.all(
    Radius.circular(field),
  );
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}

/// Motion. Kept short: this is a utility app, not a showcase.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve curve = Curves.easeOutCubic;
}

/// Stroke widths and icon sizes.
abstract final class Strokes {
  /// Hairline separators and card outlines.
  static const double hairline = 1;

  /// Focus ring and the active side of a segmented control.
  static const double focus = 2;

  /// Budget progress track.
  static const double progress = 8;
}

abstract final class IconSizes {
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;

  /// Category avatar in a transaction row.
  static const double avatar = 40;

  /// Illustration circle of an empty state.
  static const double illustration = 72;
}
