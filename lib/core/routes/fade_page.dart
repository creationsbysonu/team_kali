import 'package:flutter/material.dart';

/// Custom fade page for smooth dissolve transitions.
///
/// Use this for smooth navigation transitions throughout the app.
///
/// Example usage:
/// ```dart
/// pages.add(
///   FadePage(
///     key: const ValueKey('my_page'),
///     child: MyPageWidget(),
///   ),
/// );
/// ```
class FadePage extends Page {
  final Widget child;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final Curve curve;

  const FadePage({
    required LocalKey key,
    required this.child,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOutCubic,
  }) : super(key: key);

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: curve),
          child: child,
        );
      },
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
    );
  }
}

/// Slide page for slide-in transitions from right.
///
/// Use this for hierarchical navigation (pushing new screens).
class SlidePage extends Page {
  final Widget child;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final Curve curve;
  final Offset beginOffset;

  const SlidePage({
    required LocalKey key,
    required this.child,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(1.0, 0.0), // Slide from right
  }) : super(key: key);

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
    );
  }
}

/// Scale page for zoom-in transitions.
///
/// Use this for modal-like or popup screens.
class ScalePage extends Page {
  final Widget child;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final Curve curve;
  final double beginScale;

  const ScalePage({
    required LocalKey key,
    required this.child,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOutCubic,
    this.beginScale = 0.9,
  }) : super(key: key);

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: beginScale,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
    );
  }
}
