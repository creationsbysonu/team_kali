import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/staff/domain/entities/staff_member.dart';
import 'package:sewa_web/features/staff/presentation/bloc/staff_bloc.dart';

/// Staff Management Page - For ministry admins to manage staff
class StaffManagementPage extends StatelessWidget {
  final VoidCallback? onAddStaff;

  const StaffManagementPage({super.key, this.onAddStaff});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StaffBloc, StaffState, bool>(
      selector: (state) => state is StaffOperationLoading,
      builder: (context, isOperationInProgress) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppTheme.primaryCobaltDark,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Staff Management',
                          style: AppTheme.headingMedium().copyWith(
                            color: Colors.white,
                          ),
                        ),
                        if (onAddStaff != null)
                          ElevatedButton.icon(
                            onPressed: onAddStaff,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Staff'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Staff list
                  Expanded(
                    child: BlocBuilder<StaffBloc, StaffState>(
                      builder: (context, state) {
                        if (state is StaffLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }

                        if (state is StaffError) {
                          return _buildErrorState(context, state.message);
                        }

                        if (state is StaffLoaded) {
                          if (state.staff.isEmpty) {
                            return _buildEmptyState();
                          }
                          return _buildStaffList(state.staff);
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Blur loading overlay for operations
            if (isOperationInProgress)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
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

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.accentRed, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyLarge().copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<StaffBloc>().add(LoadStaffEvent());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          Text(
            'No staff members yet',
            style: AppTheme.bodyLarge().copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first staff member to get started',
            style: AppTheme.bodyMedium().copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList(List<StaffMember> staff) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: staff.length,
      itemBuilder: (context, index) => _StaffCard(staff: staff[index]),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffMember staff;

  const _StaffCard({required this.staff});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.accentBlue.withAlpha(25),
              backgroundImage: staff.imageUrl != null
                  ? NetworkImage(staff.imageUrl!)
                  : null,
              child: staff.imageUrl == null
                  ? Text(
                      staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        staff.name,
                        style: AppTheme.headingSmall().copyWith(
                          color: AppTheme.primaryCobaltDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: staff.isActive
                              ? AppTheme.accentGreen.withAlpha(25)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          staff.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: staff.isActive
                                ? AppTheme.accentGreen
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    staff.email,
                    style: AppTheme.bodyMedium().copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (staff.serviceName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      staff.serviceName,
                      style: AppTheme.labelSmall().copyWith(
                        color: AppTheme.accentBlue,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                // TODO: Handle actions
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'password',
                  child: Text('Reset Password'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
