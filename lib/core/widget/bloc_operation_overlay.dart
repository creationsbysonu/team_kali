import 'package:flutter/material.dart';

/// A reusable blocking overlay that prevents user interaction
/// during async operations while showing a loading indicator.
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     YourContent(),
///     BlocOperationOverlay(
///       isLoading: state is SomeLoadingState,
///       message: 'Processing...',
///     ),
///   ],
/// )
/// ```
class BlocOperationOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final Color? barrierColor;

  const BlocOperationOverlay({
    super.key,
    required this.isLoading,
    this.message,
    this.barrierColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: barrierColor ?? Colors.black45,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
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

/// A wrapper widget that shows content with an optional loading overlay
///
/// Usage:
/// ```dart
/// OperationAwareContent(
///   isOperating: state is MinistryUpdating,
///   operationMessage: 'Processing...',
///   child: YourContent(),
/// )
/// ```
class OperationAwareContent extends StatelessWidget {
  final bool isOperating;
  final String? operationMessage;
  final Widget child;
  final Color? barrierColor;

  const OperationAwareContent({
    super.key,
    required this.isOperating,
    required this.child,
    this.operationMessage,
    this.barrierColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        BlocOperationOverlay(
          isLoading: isOperating,
          message: operationMessage,
          barrierColor: barrierColor,
        ),
      ],
    );
  }
}

/// Extension to check if a bloc state represents an operation in progress
extension OperationStateChecker on Object {
  /// Returns true if this state represents an operation in progress
  /// that should block user interaction
  bool get isOperating {
    final typeName = runtimeType.toString();
    return typeName.contains('Creating') ||
        typeName.contains('Updating') ||
        typeName.contains('Deleting') ||
        typeName.contains('Loading');
  }

  /// Returns true if this is specifically a background loading state
  /// (not blocking operations like create/update/delete)
  bool get isBackgroundLoading {
    final typeName = runtimeType.toString();
    return typeName.contains('Loading') || typeName.contains('Refreshing');
  }
}
