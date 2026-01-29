import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/core/widget/global_operation_overlay.dart';
import 'package:sewa_web/features/ministry/domain/entities/staff_service_entity.dart';
import 'package:sewa_web/features/ministry/presentation/bloc/staff_service_bloc.dart';
import 'package:sewa_web/features/ministry/presentation/pages/services/widgets/services_header.dart';
import 'package:sewa_web/features/ministry/presentation/pages/services/widgets/services_table.dart';
import 'package:sewa_web/features/ministry/presentation/pages/services/widgets/service_shared_widgets.dart';

/// Ministry Services List Page - Clean professional design
/// Manages staff-services CRUD operations
class ServicesListPage extends StatefulWidget {
  const ServicesListPage({super.key});

  @override
  State<ServicesListPage> createState() => _ServicesListPageState();
}

class _ServicesListPageState extends State<ServicesListPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<StaffServiceBloc>().add(LoadStaffServicesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffServiceBloc, StaffServiceState>(
      listener: (context, state) {
        // Show/hide loading overlay
        if (state is StaffServiceOperationInProgress) {
          GlobalOperationOverlay.show(message: 'Processing...');
        } else if (state is StaffServiceOperationSuccess ||
            state is StaffServiceError ||
            state is StaffServiceLoaded) {
          GlobalOperationOverlay.hide();
        }

        // Show snackbar feedback
        if (state is StaffServiceOperationSuccess) {
          _showSnackBar(state.message, isSuccess: true);
        } else if (state is StaffServiceError) {
          _showSnackBar(state.message, isSuccess: false);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ServicesHeader(onRefresh: _loadData),
            Expanded(
              child: BlocBuilder<StaffServiceBloc, StaffServiceState>(
                builder: (context, state) {
                  if (state is StaffServiceLoading) {
                    return const LoadingView();
                  }

                  if (state is StaffServiceError &&
                      state.currentServices == null) {
                    return ErrorView(
                      message: state.message,
                      onRetry: _loadData,
                    );
                  }

                  // Get services from various states
                  final services = state is StaffServiceLoaded
                      ? state.services
                      : state is StaffServiceOperationInProgress
                      ? state.currentServices
                      : state is StaffServiceError
                      ? state.currentServices ?? []
                      : <StaffService>[];

                  if (services.isEmpty) {
                    return EmptyView(
                      icon: Icons.medical_services_outlined,
                      title: 'No services yet',
                      subtitle: 'Get started by adding your first service',
                      actionLabel: 'Add Service',
                      onAction: () => showCreateServiceDialog(context),
                    );
                  }

                  return ServicesTable(services: services);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
