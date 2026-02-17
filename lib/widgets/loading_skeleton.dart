import 'package:flutter/material.dart';

/// Shimmer effect widget for loading states
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - _controller.value * 2, 0.0),
              end: Alignment(1.0 - _controller.value * 2, 0.0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton loader for video cards
class VideoCardSkeleton extends StatelessWidget {
  const VideoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.primary.withOpacity(0.08);
    final highlight = Theme.of(context).colorScheme.secondary.withOpacity(0.10);
    return ShimmerEffect(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail skeleton
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: base,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
            ),
            // Text skeleton
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for category cards
class CategoryCardSkeleton extends StatelessWidget {
  const CategoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.primary.withOpacity(0.08);
    final highlight = Theme.of(context).colorScheme.secondary.withOpacity(0.10);
    return ShimmerEffect(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: highlight,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 15,
                width: 80,
                decoration: BoxDecoration(
                  color: highlight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader for list items
class ListItemSkeleton extends StatelessWidget {
  final double? height;
  
  const ListItemSkeleton({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.primary.withOpacity(0.08);
    final highlight = Theme.of(context).colorScheme.secondary.withOpacity(0.10);
    return ShimmerEffect(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        height: height ?? 60,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: highlight,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: highlight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 150,
                      decoration: BoxDecoration(
                        color: highlight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

