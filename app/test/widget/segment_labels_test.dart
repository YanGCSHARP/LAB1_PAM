import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:walletmate/core/utils/formatters.dart';

import '../helpers/test_app.dart';

/// Loads the bundled Inter, so label widths are measured with the real glyphs.
/// The default test font draws every glyph as a 1 em square and would not
/// tell a label that fits from one that wraps.
Future<void> _loadInter() async {
  final inter = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    inter.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
  }
  await inter.load();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting(Formatters.locale);
    await _loadInter();
  });

  // A three-way segmented control splits a 360 px screen into narrow
  // segments; a label that does not fit used to wrap mid-word («Систе / ма»).
  for (final location in ['/profile', '/accounts/new']) {
    testWidgets('segment labels on $location fit one line at 360 px', (
      tester,
    ) async {
      await pumpApp(tester, location, size: const Size(360, 800));

      final labels = find.descendant(
        of: find.byWidgetPredicate((widget) => widget is SegmentedButton),
        matching: find.byType(RichText),
      );
      expect(labels, findsWidgets);

      for (final element in labels.evaluate()) {
        final paragraph = element.renderObject! as RenderParagraph;
        final text = paragraph.text.toPlainText();
        if (!RegExp(r'\p{L}', unicode: true).hasMatch(text)) {
          continue; // an icon glyph, not a label
        }
        expect(paragraph.maxLines, 1, reason: '«$text» may wrap');
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: '«$text» does not fit its segment',
        );
      }
    });
  }
}
