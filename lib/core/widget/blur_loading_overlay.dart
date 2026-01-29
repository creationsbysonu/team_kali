import 'dart:ui';
import 'package:flutter/material.dart';

/// Professional blur loading overlay widget
/// - Blurs background instead of hiding it
/// - Shows loading indicator with optional message
/// - Can be used across all feature pages
class BlurLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final Widget child;
  final double blurSigma;
  final Color overlayColor;

  const BlurLoadingOverlay({
    super.key,
    required this.isLoading,
    this.message,
    required this.child,
    this.blurSigma = 3.0,
    this.overlayColor = const Color(0x40FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content - always visible
        child,

        // Blur overlay - only when loading
        if (isLoading)
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(
                  color: overlayColor,
                  child: Center(child: _buildLoadingIndicator()),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A5F)),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact version for inline loading (e.g., in cards, buttons)
class InlineLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const InlineLoadingIndicator({super.key, this.message, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        if (message != null) ...[
          const SizedBox(width: 8),
          Text(message!, style: const TextStyle(fontSize: 13)),
        ],
      ],
    );
  }
}
