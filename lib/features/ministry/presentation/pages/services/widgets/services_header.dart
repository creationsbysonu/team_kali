import 'package:flutter/material.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/ministry/presentation/pages/services/widgets/service_shared_widgets.dart';

/// Header for Services Page with title, count, and actions
class ServicesHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const ServicesHeader({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.medical_services,
            size: 28,
            color: AppTheme.primaryCobalt,
          ),
          const SizedBox(width: 12),
          const Text(
            'Services Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => showCreateServiceDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCobalt,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
