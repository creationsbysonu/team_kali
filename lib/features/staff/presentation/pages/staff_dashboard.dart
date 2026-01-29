import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_web/features/staff/presentation/bloc/staff_dashboard_bloc.dart';

/// Staff Dashboard - Entry point for staff admin
/// Shows service info and provides navigation to staff features
/// Reuses UI/UX from Ministry Admin Panel with role-specific labels
class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is Authenticated) {
          return BlocProvider(
            create: (context) =>
                StaffDashboardBloc()
                  ..add(LoadStaffDashboardEvent(user: authState.user)),
            child: const _StaffDashboardView(),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _StaffDashboardView extends StatelessWidget {
  const _StaffDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StaffDashboardBloc, StaffDashboardState>(
      builder: (context, state) {
        if (state is StaffDashboardLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryCobalt),
          );
        }

        if (state is StaffDashboardError) {
          return _buildErrorView(context, state.message);
        }

        if (state is StaffDashboardLoaded) {
          return _buildDashboardView(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.error.withAlpha(180),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyLarge().copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<StaffDashboardBloc>().add(
                const RefreshStaffDashboardEvent(),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCobalt,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView(BuildContext context, StaffDashboardLoaded state) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page Header
          _buildPageHeader(context, state),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(state),
                  const SizedBox(height: 24),

                  // Service Info Card
                  _buildServiceInfoCard(state),
                  const SizedBox(height: 24),

                  // Quick Stats
                  _buildQuickStatsSection(),
                  const SizedBox(height: 24),

                  // Main Content Area
                  _buildContentPlaceholder(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, StaffDashboardLoaded state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor.withAlpha(80)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryCobalt.withAlpha(25),
            ),
            child: const Icon(
              Icons.medical_services,
              color: AppTheme.primaryCobalt,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Dashboard',
                  style: AppTheme.headingLarge().copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.service.name,
                  style: AppTheme.bodyMedium().copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryCobalt),
            onPressed: () {
              context.read<StaffDashboardBloc>().add(
                const RefreshStaffDashboardEvent(),
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(StaffDashboardLoaded state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryCobalt, Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: AppTheme.bodyLarge().copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  state.user.displayName,
                  style: AppTheme.headingMedium().copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.service.name} - ${state.ministry?.name ?? ""}',
                  style: AppTheme.bodyMedium().copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_services,
              size: 48,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfoCard(StaffDashboardLoaded state) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryCobalt),
                const SizedBox(width: 12),
                Text(
                  'Service Information',
                  style: AppTheme.bodyLarge().copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppTheme.borderColor.withAlpha(80)),
            const SizedBox(height: 16),
            _buildInfoRow('Service', state.service.name),
            _buildInfoRow('Slug', state.service.slug),
            if (state.ministry != null)
              _buildInfoRow('Ministry', state.ministry!.name),
            if (state.place != null) _buildInfoRow('Place', state.place!.name),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTheme.bodyMedium().copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium().copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: AppTheme.bodyLarge().copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Applications',
                '0',
                Icons.description,
                AppTheme.primaryCobalt,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Pending',
                '0',
                Icons.pending_actions,
                AppTheme.warning,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Completed',
                '0',
                Icons.check_circle,
                AppTheme.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTheme.headingMedium().copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTheme.bodySmall().copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentPlaceholder() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor.withAlpha(80)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: AppTheme.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'More Features Coming Soon',
              style: AppTheme.headingSmall().copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the sidebar to access Queue Dashboard and Progress Workbench',
              style: AppTheme.bodyMedium().copyWith(
                color: AppTheme.textSecondary.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
