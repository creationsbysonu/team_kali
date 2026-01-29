import 'package:flutter/material.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';

/// Widget to display a ministry card with actions
class MinistryCard extends StatelessWidget {
  final Ministry ministry;
  final bool isDeleted;
  final VoidCallback onEdit;
  final VoidCallback onActivate;
  final VoidCallback onSuspend;
  final VoidCallback onDelete;
  final VoidCallback onRestore;
  final VoidCallback onHardDelete;
  final VoidCallback onResetPassword;

  const MinistryCard({
    super.key,
    required this.ministry,
    required this.isDeleted,
    required this.onEdit,
    required this.onActivate,
    required this.onSuspend,
    required this.onDelete,
    required this.onRestore,
    required this.onHardDelete,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildLogo(),
            const SizedBox(width: 16),
            Expanded(child: _buildInfo()),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ministry.logoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ministry.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.account_balance,
                  color: AppTheme.accentBlue,
                  size: 28,
                ),
              ),
            )
          : const Icon(
              Icons.account_balance,
              color: AppTheme.accentBlue,
              size: 28,
            ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ministry.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        if (ministry.email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            ministry.email,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
        if (ministry.phone != null) ...[
          const SizedBox(height: 2),
          Text(
            ministry.phone!,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            StatusBadge(status: ministry.status, isActive: ministry.isActive),
            if (isDeleted) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Text(
                  'DELETED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    if (isDeleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.restore, color: Colors.green),
            onPressed: onRestore,
            tooltip: 'Restore',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: onHardDelete,
            tooltip: 'Delete Forever',
          ),
        ],
      );
    }

    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'activate':
            onActivate();
            break;
          case 'suspend':
            onSuspend();
            break;
          case 'delete':
            onDelete();
            break;
          case 'reset_password':
            onResetPassword();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        if (!ministry.isActive)
          const PopupMenuItem(
            value: 'activate',
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('Activate'),
              ],
            ),
          ),
        if (ministry.isActive)
          const PopupMenuItem(
            value: 'suspend',
            child: Row(
              children: [
                Icon(Icons.pause_circle, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text('Suspend'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'reset_password',
          child: Row(
            children: [
              Icon(Icons.lock_reset, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text('Reset Password'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }
}

/// Status badge widget
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isActive;

  const StatusBadge({super.key, required this.status, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green[300]! : Colors.orange[300]!,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.green[700] : Colors.orange[700],
        ),
      ),
    );
  }
}
