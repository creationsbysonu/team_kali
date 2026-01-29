import 'package:flutter/material.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/presentation/pages/ministries/widgets/ministry_actions.dart';

/// Ministries table component
class MinistriesTable extends StatelessWidget {
  final List<Ministry> ministries;
  final bool isDeleted;

  const MinistriesTable({
    super.key,
    required this.ministries,
    required this.isDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const TableHeaderCell(title: 'Ministry', flex: 3),
                  const TableHeaderCell(title: 'Email', flex: 2),
                  TableHeaderCell(
                    title: isDeleted ? 'Deleted At' : 'Place',
                    flex: 2,
                  ),
                  if (!isDeleted)
                    const TableHeaderCell(
                      title: 'Status',
                      flex: 1,
                      center: true,
                    ),
                  const SizedBox(
                    width: 140,
                    child: Text(
                      'ACTIONS',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Container(height: 1, color: AppTheme.borderColor.withAlpha(100)),
            // Table Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ministries.length,
              separatorBuilder: (_, __) => Container(
                height: 1,
                color: AppTheme.borderColor.withAlpha(50),
              ),
              itemBuilder: (context, index) {
                return MinistryRow(
                  ministry: ministries[index],
                  isDeleted: isDeleted,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Table header cell component
class TableHeaderCell extends StatelessWidget {
  final String title;
  final int flex;
  final bool center;

  const TableHeaderCell({
    super.key,
    required this.title,
    this.flex = 1,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        textAlign: center ? TextAlign.center : TextAlign.start,
      ),
    );
  }
}

/// Ministry row component
class MinistryRow extends StatelessWidget {
  final Ministry ministry;
  final bool isDeleted;

  const MinistryRow({
    super.key,
    required this.ministry,
    required this.isDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Logo and Name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _buildLogo(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ministry.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Email
          Expanded(
            flex: 2,
            child: Text(
              ministry.email.isNotEmpty ? ministry.email : '-',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
          // Place or Deleted At
          Expanded(
            flex: 2,
            child: Text(
              isDeleted
                  ? _formatDeletedAt(ministry.deletedAt)
                  : ministry.placeName ?? '-',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          // Status (only for active)
          if (!isDeleted)
            Expanded(flex: 1, child: Center(child: _buildStatusBadge())),
          // Actions
          SizedBox(
            width: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: isDeleted
                  ? _buildDeletedActions(context)
                  : _buildActiveActions(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    if (ministry.logoUrl != null && ministry.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          ministry.logoUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
        ),
      );
    }
    return _buildLogoPlaceholder();
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryCobalt.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.account_balance,
        color: AppTheme.primaryCobalt,
        size: 18,
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isActive = ministry.isActive;
    final isSuspended = ministry.isSuspended;

    // Determine color based on actual status
    Color badgeColor;
    if (isActive) {
      badgeColor = AppTheme.success;
    } else if (isSuspended) {
      badgeColor = AppTheme.warning;
    } else {
      // Pending or other statuses
      badgeColor = AppTheme.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ministry.status.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<Widget> _buildActiveActions(BuildContext context) {
    return [
      ActionButton(
        icon: Icons.edit_outlined,
        tooltip: 'Edit',
        onPressed: () => MinistryActions.showEditDialog(context, ministry),
      ),
      ActionButton(
        icon: Icons.key_outlined,
        tooltip: 'Reset Password',
        onPressed: () =>
            MinistryActions.showResetPasswordDialog(context, ministry),
      ),
      ActionButton(
        icon: ministry.isActive
            ? Icons.pause_outlined
            : Icons.play_arrow_outlined,
        tooltip: ministry.isActive ? 'Suspend' : 'Activate',
        onPressed: () => ministry.isActive
            ? MinistryActions.showSuspendDialog(context, ministry)
            : MinistryActions.activateMinistry(context, ministry),
      ),
      ActionButton(
        icon: Icons.delete_outline,
        tooltip: 'Delete',
        color: AppTheme.error,
        onPressed: () => MinistryActions.showDeleteDialog(context, ministry),
      ),
    ];
  }

  List<Widget> _buildDeletedActions(BuildContext context) {
    return [
      ActionButton(
        icon: Icons.restore,
        tooltip: 'Restore',
        color: AppTheme.success,
        onPressed: () => MinistryActions.restoreMinistry(context, ministry),
      ),
      ActionButton(
        icon: Icons.delete_forever,
        tooltip: 'Delete Permanently',
        color: AppTheme.error,
        onPressed: () =>
            MinistryActions.showHardDeleteDialog(context, ministry),
      ),
    ];
  }

  String _formatDeletedAt(DateTime? deletedAt) {
    if (deletedAt == null) return '-';
    final now = DateTime.now();
    final difference = now.difference(deletedAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${deletedAt.day}/${deletedAt.month}/${deletedAt.year}';
    }
  }
}
