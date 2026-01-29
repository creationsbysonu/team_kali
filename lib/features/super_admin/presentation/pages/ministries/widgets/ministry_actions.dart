import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/core/widget/global_operation_overlay.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/presentation/bloc/ministry_bloc.dart';
import 'package:sewa_web/features/super_admin/presentation/dialogs/edit_ministry_dialog.dart';
import 'package:sewa_web/features/super_admin/presentation/dialogs/reset_password_dialog.dart';
import 'package:sewa_web/features/places/presentation/bloc/place_bloc.dart';

/// Action button component for ministry row
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const ActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color ?? AppTheme.textSecondary),
        ),
      ),
    );
  }
}

/// Ministry actions helper class
class MinistryActions {
  static void showEditDialog(BuildContext context, Ministry ministry) {
    final ministryBloc = context.read<MinistryBloc>();
    final placeBloc = context.read<PlaceBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: ministryBloc),
          BlocProvider.value(value: placeBloc),
        ],
        child: EditMinistryDialog(ministry: ministry),
      ),
    );
  }

  static void showResetPasswordDialog(BuildContext context, Ministry ministry) {
    final ministryBloc = context.read<MinistryBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: ministryBloc,
        child: ResetPasswordDialog(ministry: ministry),
      ),
    );
  }

  static void activateMinistry(BuildContext context, Ministry ministry) {
    GlobalOperationOverlay.show(message: 'Activating ministry...');
    context.read<MinistryBloc>().add(
      ActivateMinistryEvent(ministryId: ministry.id),
    );
  }

  static void showSuspendDialog(BuildContext context, Ministry ministry) {
    final ministryBloc = context.read<MinistryBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Suspend Ministry'),
        content: Text(
          'Are you sure you want to suspend "${ministry.name}"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              GlobalOperationOverlay.show(message: 'Suspending ministry...');
              ministryBloc.add(SuspendMinistryEvent(ministryId: ministry.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  static void showDeleteDialog(BuildContext context, Ministry ministry) {
    final ministryBloc = context.read<MinistryBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Ministry'),
        content: Text(
          'Are you sure you want to delete "${ministry.name}"?\n\n'
          'This ministry will be moved to trash and can be restored later.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              GlobalOperationOverlay.show(message: 'Deleting ministry...');
              ministryBloc.add(DeleteMinistryEvent(ministryId: ministry.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static void restoreMinistry(BuildContext context, Ministry ministry) {
    GlobalOperationOverlay.show(message: 'Restoring ministry...');
    context.read<MinistryBloc>().add(
      RestoreMinistryEvent(ministryId: ministry.id),
    );
  }

  static void showHardDeleteDialog(BuildContext context, Ministry ministry) {
    final ministryBloc = context.read<MinistryBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.error),
            SizedBox(width: 12),
            Text('Permanent Deletion'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${ministry.name}"?\n\n'
          'This action cannot be undone!',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              GlobalOperationOverlay.show(message: 'Permanently deleting...');
              ministryBloc.add(
                HardDeleteMinistryEvent(ministryId: ministry.id),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}
