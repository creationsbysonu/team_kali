import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/core/widget/global_operation_overlay.dart';
import 'package:sewa_web/features/places/presentation/bloc/place_bloc.dart';
import 'package:sewa_web/features/super_admin/presentation/bloc/ministry_bloc.dart';
import 'package:sewa_web/features/super_admin/presentation/pages/ministries/widgets/active_ministries_tab.dart';
import 'package:sewa_web/features/super_admin/presentation/pages/ministries/widgets/deleted_ministries_tab.dart';
import 'package:sewa_web/features/super_admin/presentation/pages/ministries/widgets/ministries_header.dart';

/// Super Admin Ministries Page - Clean professional design
/// Properly structured with separate widget files for better maintainability
class SuperAdminMinistriesPage extends StatefulWidget {
  const SuperAdminMinistriesPage({super.key});

  @override
  State<SuperAdminMinistriesPage> createState() =>
      _SuperAdminMinistriesPageState();
}

class _SuperAdminMinistriesPageState extends State<SuperAdminMinistriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    // Only load places if not already loaded or if it's initial load
    final placeState = context.read<PlaceBloc>().state;
    if (_isInitialLoad || placeState is! PlacesLoaded) {
      context.read<PlaceBloc>().add(const LoadAllPlacesEvent());
    }

    // Use RefreshAllMinistriesEvent to load both active and deleted ministries sequentially
    context.read<MinistryBloc>().add(const RefreshAllMinistriesEvent());
    _isInitialLoad = false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MinistryBloc, MinistryState>(
      listener: (context, state) {
        // Show/hide loading overlay
        if (state is MinistryUpdating) {
          GlobalOperationOverlay.show(message: 'Processing...');
        } else if (state is MinistryCreated ||
            state is MinistryUpdated ||
            state is MinistryActivated ||
            state is MinistrySuspended ||
            state is MinistryDeleted ||
            state is MinistryRestored ||
            state is MinistryHardDeleted ||
            state is MinistryPasswordReset ||
            state is MinistryOperationError ||
            state is MinistryLoaded) {
          GlobalOperationOverlay.hide();
        }

        // Show snackbar feedback
        if (state is MinistryCreated) {
          _showSnackBar('Ministry created successfully', isSuccess: true);
        } else if (state is MinistryUpdated) {
          _showSnackBar('Ministry updated successfully', isSuccess: true);
        } else if (state is MinistryActivated) {
          _showSnackBar('Ministry activated', isSuccess: true);
        } else if (state is MinistrySuspended) {
          _showSnackBar('Ministry suspended', isSuccess: true);
        } else if (state is MinistryDeleted) {
          _showSnackBar('Ministry moved to trash', isSuccess: true);
        } else if (state is MinistryRestored) {
          _showSnackBar('Ministry restored', isSuccess: true);
        } else if (state is MinistryHardDeleted) {
          _showSnackBar('Ministry permanently deleted', isSuccess: true);
        } else if (state is MinistryPasswordReset) {
          _showSnackBar('Password reset successfully', isSuccess: true);
        } else if (state is MinistryOperationError) {
          _showSnackBar(state.message, isSuccess: false);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MinistriesHeader(onRefresh: _loadData),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ActiveMinistriesTab(onRefresh: _loadData),
                  DeletedMinistriesTab(onRefresh: _loadData),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryCobalt,
        unselectedLabelColor: AppTheme.textMuted,
        indicatorColor: AppTheme.primaryCobalt,
        indicatorWeight: 2,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business, size: 18),
                SizedBox(width: 8),
                Text('Active Ministries'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline, size: 18),
                SizedBox(width: 8),
                Text('Deleted'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
