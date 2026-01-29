import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/widget/bloc_operation_overlay.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/presentation/bloc/ministry_bloc.dart';
import 'package:sewa_web/features/super_admin/presentation/widgets/widgets.dart';

/// Deleted Ministries Tab - Shows all soft-deleted ministries with proper loading states
class DeletedMinistriesTab extends StatelessWidget {
  final Future<void> Function(BuildContext, Ministry) onRestore;
  final Future<void> Function(BuildContext, Ministry) onHardDelete;

  const DeletedMinistriesTab({
    super.key,
    required this.onRestore,
    required this.onHardDelete,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MinistryBloc, MinistryState>(
      builder: (context, state) {
        // Determine loading/operating states
        final isOperating = state is MinistryUpdating;
        final isRefreshing = state is DeletedMinistriesRefreshing;
        final isInitialLoading = state is MinistryLoading;

        // Extract ministries from any applicable state
        List<Ministry> ministries = _extractMinistries(state);

        // If we have no data and it's initial loading
        if (ministries.isEmpty && isInitialLoading) {
          return _buildLoadingState();
        }

        // If error
        if (state is MinistryError && ministries.isEmpty) {
          return _buildErrorState(context, state.message);
        }

        // If empty (no deleted ministries)
        if (ministries.isEmpty &&
            !isInitialLoading &&
            !isRefreshing &&
            !isOperating) {
          return _buildEmptyState();
        }

        // Show content with overlay during operations
        return OperationAwareContent(
          isOperating: isOperating,
          operationMessage: 'Processing...',
          child: Stack(
            children: [
              _buildMinistryList(context, ministries),
              // Show subtle loading indicator during refresh
              if (isRefreshing)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Ministry> _extractMinistries(MinistryState state) {
    if (state is DeletedMinistriesLoaded) return state.ministries;
    if (state is DeletedMinistriesRefreshing) return state.ministries;
    if (state is MinistryUpdating) return state.deletedMinistries;
    return [];
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading deleted ministries...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<MinistryBloc>().add(LoadDeletedMinistriesEvent());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green[400]),
          const SizedBox(height: 16),
          Text(
            'No deleted ministries',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'All ministries are active',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMinistryList(BuildContext context, List<Ministry> ministries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ministries.length,
      itemBuilder: (context, index) {
        final ministry = ministries[index];
        return MinistryCard(
          ministry: ministry,
          isDeleted: true,
          onEdit: () {},
          onActivate: () {},
          onSuspend: () {},
          onDelete: () {},
          onRestore: () => onRestore(context, ministry),
          onHardDelete: () => onHardDelete(context, ministry),
          onResetPassword: () {},
        );
      },
    );
  }
}
