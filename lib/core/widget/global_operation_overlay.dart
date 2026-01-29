import 'package:flutter/material.dart';

/// Global operation overlay controller for showing loading states
/// across the entire application.
///
/// Usage:
/// 1. Wrap your MaterialApp with GlobalOperationOverlay.wrap()
/// 2. Use GlobalOperationOverlay.show() and GlobalOperationOverlay.hide()
///    to control the overlay from anywhere in the app.
///
/// Example:
/// ```dart
/// // In main.dart or app.dart
/// MaterialApp(
///   builder: (context, child) => GlobalOperationOverlay.wrap(child!),
/// )
///
/// // Anywhere in your code
/// GlobalOperationOverlay.show(message: 'Creating ministry...');
/// await someAsyncOperation();
/// GlobalOperationOverlay.hide();
/// ```
class GlobalOperationOverlay extends StatefulWidget {
  final Widget child;

  const GlobalOperationOverlay({super.key, required this.child});

  /// Wrap your app with this to enable global overlay
  static Widget wrap(Widget child) {
    return GlobalOperationOverlay(child: child);
  }

  /// Show the global loading overlay
  static void show({String? message, bool dismissible = false}) {
    _GlobalOperationOverlayState._instance?.show(
      message: message,
      dismissible: dismissible,
    );
  }

  /// Hide the global loading overlay
  static void hide() {
    _GlobalOperationOverlayState._instance?.hide();
  }

  /// Update the message while loading
  static void updateMessage(String message) {
    _GlobalOperationOverlayState._instance?.updateMessage(message);
  }

  /// Check if overlay is currently showing
  static bool get isShowing =>
      _GlobalOperationOverlayState._instance?._isShowing ?? false;

  @override
  State<GlobalOperationOverlay> createState() => _GlobalOperationOverlayState();
}

class _GlobalOperationOverlayState extends State<GlobalOperationOverlay>
    with SingleTickerProviderStateMixin {
  static _GlobalOperationOverlayState? _instance;

  bool _isShowing = false;
  String? _message;
  bool _dismissible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _instance = this;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (_instance == this) {
      _instance = null;
    }
    super.dispose();
  }

  void show({String? message, bool dismissible = false}) {
    if (mounted) {
      setState(() {
        _isShowing = true;
        _message = message;
        _dismissible = dismissible;
      });
      _animationController.forward();
    }
  }

  void hide() {
    if (mounted) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isShowing = false;
            _message = null;
          });
        }
      });
    }
  }

  void updateMessage(String message) {
    if (mounted && _isShowing) {
      setState(() => _message = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_isShowing)
            FadeTransition(
              opacity: _fadeAnimation,
              child: _OperationOverlayContent(
                message: _message,
                dismissible: _dismissible,
                onDismiss: _dismissible ? hide : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _OperationOverlayContent extends StatelessWidget {
  final String? message;
  final bool dismissible;
  final VoidCallback? onDismiss;

  const _OperationOverlayContent({
    this.message,
    this.dismissible = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: dismissible ? onDismiss : null,
      child: Container(
        color: Colors.black.withAlpha(80),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF3B82F6), // Clean blue color
                    ),
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937), // Dark gray text
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
                if (dismissible) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Tap anywhere to dismiss',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension methods for showing operation overlay with bloc operations
extension OperationOverlayExtension on BuildContext {
  /// Show loading overlay and execute an async operation
  /// Automatically hides the overlay when done or on error
  Future<T?> showOperationOverlay<T>({
    required Future<T> Function() operation,
    required String message,
    String? successMessage,
    String? errorMessage,
    bool showSuccessSnackbar = true,
    bool showErrorSnackbar = true,
  }) async {
    GlobalOperationOverlay.show(message: message);
    try {
      final result = await operation();
      GlobalOperationOverlay.hide();
      if (showSuccessSnackbar && successMessage != null) {
        _showSuccessSnackbar(successMessage);
      }
      return result;
    } catch (e) {
      GlobalOperationOverlay.hide();
      if (showErrorSnackbar) {
        _showErrorSnackbar(errorMessage ?? e.toString());
      }
      return null;
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
