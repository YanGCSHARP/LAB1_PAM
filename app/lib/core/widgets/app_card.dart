import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// Section container: an outlined surface one step above the background.
///
/// Shadows are not used — on a near-black ground they are invisible, so depth
/// is carried by the surface step plus a hairline outline.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.action,
    this.padding = Insets.cardPadding,
    this.onTap,
  });

  final Widget child;

  /// Section heading rendered inside the card.
  final String? title;
  final String? subtitle;

  /// Trailing control of the heading row, usually a text button.
  final Widget? action;

  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            SectionHeader(title: title!, subtitle: subtitle, action: action),
            const SizedBox(height: Insets.lg),
          ],
          child,
        ],
      ),
    );

    return Card(
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Title plus optional subtitle and trailing action. Used inside cards and as
/// a standalone heading above a plain list.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: context.texts.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: Insets.xs),
                Text(subtitle!, style: context.texts.bodySmall),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: Insets.sm), action!],
      ],
    );
  }
}
