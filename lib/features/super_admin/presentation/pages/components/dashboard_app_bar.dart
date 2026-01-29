import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_web/features/super_admin/presentation/bloc/ministry_bloc.dart';

/// Dashboard AppBar with tabs and refresh/logout actions
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final VoidCallback onRefresh;

  const DashboardAppBar({
    super.key,
    required this.tabController,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primaryCobalt,
      title: const Text(
        'Super Admin Dashboard',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      elevation: 0,
      bottom: TabBar(
        controller: tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(text: 'Active Ministries', icon: Icon(Icons.account_balance)),
          Tab(text: 'Deleted Ministries', icon: Icon(Icons.delete_outline)),
        ],
      ),
      actions: [
        _RefreshButton(tabController: tabController, onRefresh: onRefresh),
        _LogoutButton(),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final TabController tabController;
  final VoidCallback onRefresh;

  const _RefreshButton({required this.tabController, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MinistryBloc, MinistryState>(
      builder: (context, state) {
        final isLoading =
            state is MinistryLoading || state is MinistryRefreshing;

        return IconButton(
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh, color: Colors.white),
          onPressed: isLoading
              ? null
              : () {
                  if (tabController.index == 0) {
                    context.read<MinistryBloc>().add(RefreshMinistriesEvent());
                  } else {
                    context.read<MinistryBloc>().add(
                      LoadDeletedMinistriesEvent(),
                    );
                  }
                },
          tooltip: 'Refresh',
        );
      },
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout, color: Colors.white),
      onPressed: () => context.read<AuthBloc>().add(LogoutEvent()),
      tooltip: 'Logout',
    );
  }
}
