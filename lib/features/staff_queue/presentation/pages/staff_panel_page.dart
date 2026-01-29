import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/di/injection_container.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/staff_queue/presentation/bloc/staff_panel_bloc.dart';
import 'package:sewa_web/features/staff_queue/presentation/pages/tabs/active_tokens_tab.dart';
import 'package:sewa_web/features/staff_queue/presentation/pages/tabs/all_tokens_tab.dart';
import 'package:sewa_web/features/staff_queue/presentation/pages/tabs/pending_tokens_tab.dart';

/// Staff Panel Page - Main queue management page with 3 tabs
///
/// Three sections:
/// 1. Active Tokens - WAITING and IN_SERVICE tokens
/// 2. All Tokens - Complete history (read-only)
/// 3. Pending Tokens - Government fault tokens
class StaffPanelPage extends StatelessWidget {
  final String staffServiceId;
  final String serviceName;

  const StaffPanelPage({
    super.key,
    required this.staffServiceId,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<StaffPanelBloc>()
        ..add(
          InitializeStaffPanel(
            staffServiceId: staffServiceId,
            serviceName: serviceName,
          ),
        ),
      child: const _StaffPanelContent(),
    );
  }
}

class _StaffPanelContent extends StatefulWidget {
  const _StaffPanelContent();

  @override
  State<_StaffPanelContent> createState() => _StaffPanelContentState();
}

class _StaffPanelContentState extends State<_StaffPanelContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      context.read<StaffPanelBloc>().add(ChangeTab(tab: _tabController.index));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StaffPanelBloc, StaffPanelState>(
      listener: (context, state) {
        // Show success message
        if (state.actionSuccess != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccess!),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Show error message
        if (state.actionError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionError!),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, state),
              // Tab Bar
              _buildTabBar(context, state),
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    ActiveTokensTab(),
                    AllTokensTab(),
                    PendingTokensTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, StaffPanelState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Staff Queue Panel',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.serviceName ?? 'Queue Management',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
              // Refresh button
              IconButton(
                onPressed: state.isLoading
                    ? null
                    : () =>
                          context.read<StaffPanelBloc>().add(RefreshAllData()),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, color: AppTheme.primaryCobalt),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Summary cards
          _buildSummaryCards(context, state),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, StaffPanelState state) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildSummaryCard(
          context,
          icon: Icons.play_circle_outline,
          label: 'Now Serving',
          value: state.currentServing > 0 ? '#${state.currentServing}' : '-',
          color: AppTheme.success,
        ),
        _buildSummaryCard(
          context,
          icon: Icons.hourglass_empty,
          label: 'Waiting',
          value: '${state.totalWaiting}',
          color: AppTheme.warning,
        ),
        _buildSummaryCard(
          context,
          icon: Icons.pending_actions,
          label: 'In Service',
          value: '${state.totalInService}',
          color: AppTheme.info,
        ),
        _buildSummaryCard(
          context,
          icon: Icons.pause_circle_outline,
          label: 'Pending',
          value: '${state.pendingTokensCount}',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, StaffPanelState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryCobalt,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryCobalt,
        unselectedLabelColor: AppTheme.textMuted,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow),
                const SizedBox(width: 8),
                const Text('Active Tokens'),
                if (state.activeTokensCount > 0) ...[
                  const SizedBox(width: 8),
                  _buildBadge(state.activeTokensCount, AppTheme.success),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.list_alt),
                const SizedBox(width: 8),
                const Text('All Tokens'),
                if (state.allTokensCount > 0) ...[
                  const SizedBox(width: 8),
                  _buildBadge(state.allTokensCount, AppTheme.info),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pending_actions),
                const SizedBox(width: 8),
                const Text('Pending Tokens'),
                if (state.pendingTokensCount > 0) ...[
                  const SizedBox(width: 8),
                  _buildBadge(state.pendingTokensCount, Colors.orange),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
