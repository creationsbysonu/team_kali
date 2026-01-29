import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/ministry/domain/entities/staff_service_entity.dart';
import 'package:sewa_web/features/ministry/presentation/bloc/staff_service_bloc.dart';
import 'package:sewa_web/features/ministry/presentation/pages/services/widgets/edit_service_dialog.dart';
import 'package:sewa_web/features/ministry/presentation/pages/services/widgets/reset_password_dialog.dart';

/// Services Table Widget - Displays list of staff services
class ServicesTable extends StatelessWidget {
  final List<StaffService> services;

  const ServicesTable({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.backgroundLight),
          columnSpacing: 20,
          horizontalMargin: 20,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 56,
          columns: const [
            DataColumn(
              label: Expanded(
                child: Text(
                  'Service Name',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  'Staff Name',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: services.map((service) => _buildRow(context, service)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, StaffService service) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (service.serviceLogo != null)
                CircleAvatar(
                  backgroundImage: NetworkImage(service.serviceLogo!),
                  radius: 16,
                  backgroundColor: Colors.transparent,
                )
              else
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(
                    Icons.medical_services,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  service.serviceName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (service.staffImage != null)
                CircleAvatar(
                  backgroundImage: NetworkImage(service.staffImage!),
                  radius: 16,
                  backgroundColor: Colors.transparent,
                )
              else
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(service.staffName, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        DataCell(Text(service.email, overflow: TextOverflow.ellipsis)),
        DataCell(_buildStatusChip(service)),
        DataCell(_buildActions(context, service)),
      ],
    );
  }

  Widget _buildStatusChip(StaffService service) {
    final isActive = service.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.success.withAlpha(25)
            : AppTheme.warning.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.pause_circle,
            size: 14,
            color: isActive ? AppTheme.success : AppTheme.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Paused',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? AppTheme.success : AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, StaffService service) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _showEditDialog(context, service),
          icon: const Icon(Icons.edit, size: 18),
          tooltip: 'Edit',
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          color: AppTheme.primaryCobalt,
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _showResetPasswordDialog(context, service),
          icon: const Icon(Icons.lock_reset, size: 18),
          tooltip: 'Reset Password',
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          color: AppTheme.warning,
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _toggleStatus(context, service),
          icon: Icon(
            service.isActive ? Icons.pause : Icons.play_arrow,
            size: 18,
          ),
          tooltip: service.isActive ? 'Pause' : 'Activate',
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          color: service.isActive ? AppTheme.warning : AppTheme.success,
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _confirmDelete(context, service),
          icon: const Icon(Icons.delete, size: 18),
          tooltip: 'Delete',
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          color: AppTheme.error,
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, StaffService service) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<StaffServiceBloc>(),
        child: EditServiceDialog(service: service),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, StaffService service) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<StaffServiceBloc>(),
        child: ResetPasswordDialog(service: service),
      ),
    );
  }

  void _toggleStatus(BuildContext context, StaffService service) {
    context.read<StaffServiceBloc>().add(
      ToggleStaffServiceStatusEvent(id: service.id),
    );
  }

  void _confirmDelete(BuildContext context, StaffService service) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "${service.serviceName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<StaffServiceBloc>().add(
                DeleteStaffServiceEvent(id: service.id),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
