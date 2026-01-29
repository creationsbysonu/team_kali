import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/widget/bloc_operation_overlay.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/presentation/bloc/ministry_bloc.dart';
import 'package:sewa_web/features/super_admin/presentation/widgets/widgets.dart';

/// Active Ministries Tab - Shows all active ministries with proper loading states
class ActiveMinistriesTab extends StatelessWidget {
  final void Function(BuildContext, Ministry) onEdit;
  final void Function(BuildContext, Ministry) onSuspend;
  final void Function(BuildContext, Ministry) onResetPassword;
  final Future<void> Function(BuildContext, Ministry) onActivate;
  final Future<void> Function(BuildContext, Ministry) onDelete;

  const ActiveMinistriesTab({
    super.key,
    required this.onEdit,
    required this.onSuspend,
    required this.onResetPassword,
    required this.onActivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MinistryBloc, MinistryState>(
      builder: (context, state) {
        // Determine loading/operating states
        final isOperating =
            state is MinistryUpdating || state is MinistryCreating;
        final isRefreshing = state is MinistryRefreshing;
        final isInitialLoading =
            state is MinistryLoading || state is MinistryInitial;

        // Extract ministries from any applicable state
        List<Ministry> ministries = _extractMinistries(state);

        // If we have no data and it's initial loading
        if (ministries.isEmpty && isInitialLoading) {
          return _buildLoadingState();
        }

        // If error
        if (state is MinistryError && ministries.isEmpty) {
          return _buildErrorState(state.message, () {
            context.read<MinistryBloc>().add(const LoadMinistriesEvent());
          });
        }

        // If empty (no ministries)
        if (ministries.isEmpty &&
            !isInitialLoading &&
            !isRefreshing &&
            !isOperating) {
          return _buildEmptyState();
        }

        // Show content with overlay during operations
        return OperationAwareContent(
          isOperating: isOperating,
          operationMessage: _getOperationMessage(state),
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
    if (state is MinistryLoaded) return state.ministries;
    if (state is MinistryRefreshing) return state.ministries;
    if (state is MinistryCreating) return state.ministries;
    if (state is MinistryUpdating) return state.ministries;
    return [];
  }

  String? _getOperationMessage(MinistryState state) {
    if (state is MinistryUpdating) return 'Processing...';
    if (state is MinistryCreating) return 'Creating ministry...';
    return null;
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading ministries...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
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
            onPressed: onRetry,
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
          Icon(Icons.account_balance, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No ministries yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first ministry to get started',
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
          isDeleted: false,
          onEdit: () => onEdit(context, ministry),
          onActivate: () => onActivate(context, ministry),
          onSuspend: () => onSuspend(context, ministry),
          onDelete: () => onDelete(context, ministry),
          onRestore: () {},
          onHardDelete: () {},
          onResetPassword: () => onResetPassword(context, ministry),
        );
      },
    );
  }
}
