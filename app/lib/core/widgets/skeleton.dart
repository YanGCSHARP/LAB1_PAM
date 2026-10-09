import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// Placeholder block with a slow shimmer, used while data is loading.
///
/// The pulse is driven by a single local [AnimationController] — no state is
/// lifted, and the animation stops as soon as the widget leaves the tree.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    required this.width,
    required this.height,
    super.key,
    this.borderRadius = Corners.chipRadius,
  });

  const SkeletonBox.line({Key? key, double width = double.infinity})
    : this(key: key, width: width, height: 14);

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colors.surfaceContainerHigh;
    final highlight = context.colors.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(base, highlight, _controller.value),
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}

/// Loading placeholder shaped like a transaction list.
class TransactionListSkeleton extends StatelessWidget {
  const TransactionListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < itemCount; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.lg,
              vertical: Insets.md,
            ),
            child: Row(
              children: [
                const SkeletonBox(
                  width: IconSizes.avatar,
                  height: IconSizes.avatar,
                  borderRadius: Corners.pillRadius,
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 120 + (i % 3) * 40, height: 14),
                      const SizedBox(height: Insets.sm),
                      const SkeletonBox(width: 90, height: 11),
                    ],
                  ),
                ),
                const SizedBox(width: Insets.md),
                const SkeletonBox(width: 72, height: 16),
              ],
            ),
          ),
      ],
    );
  }
}

/// Loading placeholder shaped like a dashboard card.
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key, this.height = 140});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: double.infinity,
      height: height,
      borderRadius: Corners.cardRadius,
    );
  }
}
