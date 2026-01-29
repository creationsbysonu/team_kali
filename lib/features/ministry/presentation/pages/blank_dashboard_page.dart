import 'package:flutter/material.dart';
import 'package:sewa_web/core/theme/theme.dart';

/// Blank dashboard page for Ministry Admin
/// This is a placeholder for future dashboard implementation
class BlankDashboardPage extends StatelessWidget {
  const BlankDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundLight,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_outlined, size: 64, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text(
              'Ministry Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
