import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated button wrapper that provides visual feedback on tap
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDownValue;
  final bool enableHapticFeedback;
  final Duration animationDuration;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDownValue = 0.95,
    this.enableHapticFeedback = true,
    this.animationDuration = const Duration(milliseconds: 100),
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDownValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // Spring curve for bouncy feel
      reverseCurve: Curves.easeInBack,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _handleTapDown : null,
      onTapUp: widget.onTap != null ? _handleTapUp : null,
      onTapCancel: widget.onTap != null ? _handleTapCancel : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Animated icon button with ripple effect
class AnimatedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;
  final String? tooltip;
  final bool enableHapticFeedback;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size,
    this.tooltip,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = AnimatedButton(
      onTap: onPressed,
      enableHapticFeedback: enableHapticFeedback,
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Animated card that responds to taps
class AnimatedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool enableHapticFeedback;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
    this.borderRadius,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: margin,
      color: color,
      elevation: elevation,
      shape: borderRadius != null
          ? RoundedRectangleBorder(borderRadius: borderRadius!)
          : null,
      child: padding != null
          ? Padding(
              padding: padding!,
              child: child,
            )
          : child,
    );

    if (onTap != null) {
      return AnimatedButton(
        onTap: onTap,
        enableHapticFeedback: enableHapticFeedback,
        child: card,
      );
    }

    return card;
  }
}

