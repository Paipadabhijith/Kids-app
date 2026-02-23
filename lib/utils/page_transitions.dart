import 'package:flutter/material.dart';

/// Custom page route with smooth slide and fade transitions
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;

  SmoothPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutBack,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide from right with fade
            const begin = Offset(0.3, 0.0);
            const end = Offset.zero;
            final slideTween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            final slideAnimation = animation.drive(slideTween);

            // Fade in
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeIn),
            );
            final fadeAnimation = animation.drive(fadeTween);

            // Scale slightly
            final scaleTween = Tween<double>(begin: 0.95, end: 1.0).chain(
              CurveTween(curve: curve),
            );
            final scaleAnimation = animation.drive(scaleTween);

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
              ),
            );
          },
        );
}

/// Scale and fade page transition (for dialogs/modals)
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  ScalePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Scale from center
            final scaleTween = Tween<double>(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: Curves.easeOutBack),
            );
            final scaleAnimation = animation.drive(scaleTween);

            // Fade in
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeIn),
            );
            final fadeAnimation = animation.drive(fadeTween);

            return ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Slide up page transition (for bottom sheets/full screen modals)
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideUpPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide from bottom
            const begin = Offset(0.0, 0.3);
            const end = Offset.zero;
            final slideTween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: Curves.easeOutCubic),
            );
            final slideAnimation = animation.drive(slideTween);

            // Fade in
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeIn),
            );
            final fadeAnimation = animation.drive(fadeTween);

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Helper extension to make navigation easier
extension NavigationExtension on BuildContext {
  /// Navigate with smooth transition
  Future<T?> pushSmoothly<T>(Widget page) {
    return Navigator.of(this).push<T>(SmoothPageRoute(page: page));
  }

  /// Navigate with scale transition
  Future<T?> pushWithScale<T>(Widget page) {
    return Navigator.of(this).push<T>(ScalePageRoute(page: page));
  }

  /// Navigate with slide up transition
  Future<T?> pushSlideUp<T>(Widget page) {
    return Navigator.of(this).push<T>(SlideUpPageRoute(page: page));
  }

  /// Replace with smooth transition
  Future<T?> replaceSmoothly<T>(Widget page) {
    return Navigator.of(this).pushReplacement<T, void>(SmoothPageRoute(page: page));
  }
}





