import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/di/injection_container.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/core/utils/responsive_helper.dart';
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_web/features/officials/domain/entities/official.dart';
import 'package:sewa_web/features/officials/presentation/bloc/officials_bloc.dart';
import 'package:sewa_web/features/officials/presentation/widgets/official_form_dialog.dart';

/// Officials Management Page - Ministry Admin can manage ministry officials
class OfficialsPage extends StatelessWidget {
  const OfficialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthBloc>().state;
        String? ministryId;

        if (authState is Authenticated) {
          ministryId = authState.user.ministry?.id;
        }

        return sl<OfficialsBloc>()
          ..add(LoadOfficialsEvent(ministryId: ministryId ?? ''));
      },
      child: const _OfficialsPageContent(),
    );
  }
}

class _OfficialsPageContent extends StatelessWidget {
  const _OfficialsPageContent();

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return BlocSelector<OfficialsBloc, OfficialsState, bool>(
      selector: (state) =>
          state is OfficialCreating ||
          state is OfficialUpdating ||
          state is OfficialDeleting,
      builder: (context, isOperationInProgress) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppTheme.background,
              body: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, isMobile),
                    const SizedBox(height: 24),
                    Expanded(child: _buildOfficialsList(context, isMobile)),
                  ],
                ),
              ),
            ),
            // Blur loading overlay for operations
            if (isOperationInProgress)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      color: Colors.white.withOpacity(0.3),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
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
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryCobalt,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Processing...',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final authState = context.read<AuthBloc>().state;
    String? ministryId;

    if (authState is Authenticated) {
      ministryId = authState.user.ministry?.id;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ministry Officials',
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage officials for queue configuration',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            _showOfficialDialog(context, ministryId: ministryId);
          },
          icon: const Icon(Icons.add),
          label: Text(isMobile ? 'Add' : 'Add Official'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryCobalt,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 12 : 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfficialsList(BuildContext context, bool isMobile) {
    return BlocConsumer<OfficialsBloc, OfficialsState>(
      listener: (context, state) {
        if (state is OfficialsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
            ),
          );
        }

        if (state is OfficialCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Official created successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
        }

        if (state is OfficialUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Official updated successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
        }

        if (state is OfficialDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Official deleted successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is OfficialsLoading ||
            state is OfficialCreating ||
            state is OfficialUpdating ||
            state is OfficialDeleting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary),
            ),
          );
        }

        if (state is OfficialsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is Authenticated) {
                      context.read<OfficialsBloc>().add(
                        LoadOfficialsEvent(
                          ministryId: authState.user.ministry?.id ?? '',
                        ),
                      );
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is OfficialsLoaded) {
          if (state.officials.isEmpty) {
            return _buildEmptyState();
          }

          return _buildOfficialsGrid(context, state.officials, isMobile);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppTheme.textMuted),
          SizedBox(height: 16),
          Text(
            'No officials found',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first official to get started',
            style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialsGrid(
    BuildContext context,
    List<Official> officials,
    bool isMobile,
  ) {
    final authState = context.read<AuthBloc>().state;
    String? ministryId;

    if (authState is Authenticated) {
      ministryId = authState.user.ministry?.id;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile
            ? 1
            : (ResponsiveHelper.isTablet(context) ? 2 : 3),
        childAspectRatio: isMobile ? 3 : 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: officials.length,
      itemBuilder: (context, index) {
        final official = officials[index];
        return _buildOfficialCard(context, official, ministryId);
      },
    );
  }

  Widget _buildOfficialCard(
    BuildContext context,
    Official official,
    String? ministryId,
  ) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryCobalt.withOpacity(0.1),
                  child: Text(
                    official.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryCobalt,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        official.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        official.role,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: official.isActive
                        ? AppTheme.success.withOpacity(0.2)
                        : AppTheme.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    official.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: official.isActive
                          ? AppTheme.success
                          : AppTheme.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _showOfficialDialog(
                      context,
                      official: official,
                      ministryId: ministryId,
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.info),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showDeleteConfirmation(context, official, ministryId);
                  },
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOfficialDialog(
    BuildContext context, {
    Official? official,
    String? ministryId,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<OfficialsBloc>(),
        child: OfficialFormDialog(
          official: official,
          ministryId: ministryId ?? '',
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Official official,
    String? ministryId,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.primaryMedium,
        title: const Text(
          'Delete Official',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete ${official.name}?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<OfficialsBloc>().add(
                DeleteOfficialEvent(
                  ministryId: ministryId ?? '',
                  officialId: official.id,
                ),
              );
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
