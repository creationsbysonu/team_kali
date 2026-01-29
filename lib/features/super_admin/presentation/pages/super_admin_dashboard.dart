import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/di/injection_container.dart' as di;
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/presentation/bloc/ministry_bloc.dart';
import 'package:sewa_web/features/super_admin/presentation/dialogs/dialogs.dart';
import 'package:sewa_web/features/super_admin/presentation/pages/components/components.dart';
import 'package:sewa_web/features/super_admin/presentation/pages/tabs/tabs.dart';

/// Super Admin Dashboard - Entry point
/// Manages all ministries: Create, Edit, Activate, Suspend, Delete, Restore
class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          di.sl<MinistryBloc>()..add(const LoadMinistriesEvent()),
      child: const _SuperAdminDashboardView(),
    );
  }
}

class _SuperAdminDashboardView extends StatefulWidget {
  const _SuperAdminDashboardView();

  @override
  State<_SuperAdminDashboardView> createState() =>
      _SuperAdminDashboardViewState();
}

class _SuperAdminDashboardViewState extends State<_SuperAdminDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Track if an action is in progress to prevent double-clicks
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      context.read<MinistryBloc>().add(const LoadMinistriesEvent());
    } else {
      context.read<MinistryBloc>().add(LoadDeletedMinistriesEvent());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false, IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ?? (isError ? Icons.error : Icons.check_circle),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MinistryBloc, MinistryState>(
      listener: (context, state) {
        // Handle action completion states
        if (state is MinistryActivated) {
          _isProcessing = false;
          _showSnackBar(
            'Ministry "${state.ministry.name}" activated!',
            icon: Icons.check_circle,
          );
        } else if (state is MinistryDeleted) {
          _isProcessing = false;
          _showSnackBar('Ministry moved to trash', icon: Icons.delete);
        } else if (state is MinistryRestored) {
          _isProcessing = false;
          _showSnackBar(
            'Ministry "${state.ministry.name}" restored!',
            icon: Icons.restore,
          );
        } else if (state is MinistryHardDeleted) {
          _isProcessing = false;
          _showSnackBar(
            'Ministry permanently deleted',
            icon: Icons.delete_forever,
          );
        } else if (state is MinistryOperationError) {
          _isProcessing = false;
          _showSnackBar(state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: DashboardAppBar(
          tabController: _tabController,
          onRefresh: _handleRefresh,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Create Ministry'),
          backgroundColor: AppTheme.accentBlue,
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            ActiveMinistriesTab(
              onEdit: _showEditDialog,
              onSuspend: _showSuspendDialog,
              onResetPassword: _showResetPasswordDialog,
              onActivate: _handleActivate,
              onDelete: _handleDelete,
            ),
            DeletedMinistriesTab(
              onRestore: _handleRestore,
              onHardDelete: _handleHardDelete,
            ),
          ],
        ),
      ),
    );
  }

  void _handleRefresh() {
    if (_tabController.index == 0) {
      context.read<MinistryBloc>().add(RefreshMinistriesEvent());
    } else {
      context.read<MinistryBloc>().add(LoadDeletedMinistriesEvent());
    }
  }

  // ============================================
  // DIALOG HANDLERS
  // ============================================

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<MinistryBloc>(),
        child: const CreateMinistryDialog(),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Ministry ministry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<MinistryBloc>(),
        child: EditMinistryDialog(ministry: ministry),
      ),
    );
  }

  void _showSuspendDialog(BuildContext context, Ministry ministry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<MinistryBloc>(),
        child: SuspendMinistryDialog(ministry: ministry),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, Ministry ministry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<MinistryBloc>(),
        child: ResetPasswordDialog(ministry: ministry),
      ),
    );
  }

  // ============================================
  // ACTION HANDLERS - Simple and Clean
  // ============================================

  Future<void> _handleActivate(BuildContext context, Ministry ministry) async {
    if (_isProcessing) return;

    final confirmed = await _showConfirmDialog(
      title: 'Activate Ministry',
      message: 'Activate "${ministry.name}"?',
      confirmText: 'Activate',
      confirmColor: AppTheme.success,
    );

    if (confirmed && mounted) {
      _isProcessing = true;
      this.context.read<MinistryBloc>().add(
        ActivateMinistryEvent(ministryId: ministry.id),
      );
    }
  }

  Future<void> _handleDelete(BuildContext context, Ministry ministry) async {
    if (_isProcessing) return;

    final confirmed = await _showConfirmDialog(
      title: 'Delete Ministry',
      message: 'Delete "${ministry.name}"?\n\nIt will be moved to trash.',
      confirmText: 'Delete',
      confirmColor: AppTheme.error,
      isDanger: true,
    );

    if (confirmed && mounted) {
      _isProcessing = true;
      this.context.read<MinistryBloc>().add(
        DeleteMinistryEvent(ministryId: ministry.id),
      );
    }
  }

  Future<void> _handleRestore(BuildContext context, Ministry ministry) async {
    if (_isProcessing) return;

    final confirmed = await _showConfirmDialog(
      title: 'Restore Ministry',
      message: 'Restore "${ministry.name}"?',
      confirmText: 'Restore',
      confirmColor: AppTheme.success,
    );

    if (confirmed && mounted) {
      _isProcessing = true;
      this.context.read<MinistryBloc>().add(
        RestoreMinistryEvent(ministryId: ministry.id),
      );
    }
  }

  Future<void> _handleHardDelete(
    BuildContext context,
    Ministry ministry,
  ) async {
    if (_isProcessing) return;

    final confirmed = await _showConfirmDialog(
      title: 'Permanently Delete',
      message: '⚠️ CANNOT BE UNDONE!\n\nPermanently delete "${ministry.name}"?',
      confirmText: 'Delete Forever',
      confirmColor: AppTheme.error,
      isDanger: true,
    );

    if (confirmed && mounted) {
      _isProcessing = true;
      this.context.read<MinistryBloc>().add(
        HardDeleteMinistryEvent(ministryId: ministry.id),
      );
    }
  }

  /// Simple confirmation dialog
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    bool isDanger = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }
}
