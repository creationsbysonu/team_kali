import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/di/injection_container.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/core/widget/global_operation_overlay.dart';
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_web/features/notice/domain/entities/notice_entity.dart';
import 'package:sewa_web/features/notice/presentation/bloc/notice_bloc.dart';
import 'package:sewa_web/features/notice/presentation/widgets/notice_header.dart';
import 'package:sewa_web/features/notice/presentation/widgets/notice_table.dart';
import 'package:sewa_web/features/notice/presentation/widgets/notice_upload_dialog.dart';
import 'package:sewa_web/features/notice/presentation/widgets/notice_widgets.dart';

/// Main page for managing notices
class NoticeListPage extends StatefulWidget {
  const NoticeListPage({super.key});

  @override
  State<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends State<NoticeListPage> {
  String? _selectedServiceId;
  String? _selectedStatus;
  String _searchQuery = '';
  List<NoticeServiceEntity> _services = [];

  Timer? _searchDebounce;

  /// Check if current user is staff admin
  bool get _isStaffAdmin {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      return authState.user.isStaff;
    }
    return false;
  }

  /// Check if current user is ministry admin
  bool get _isMinistryAdmin {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      return authState.user.isAdmin;
    }
    return false;
  }

  /// Get the appropriate page title
  String get _pageTitle {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      if (authState.user.isStaff && authState.user.service != null) {
        return '${authState.user.service!.name} Notices';
      } else if (authState.user.isAdmin && authState.user.ministry != null) {
        return '${authState.user.ministry!.name} Notices';
      }
    }
    return 'Notice Management';
  }

  /// Get subtitle based on user type
  String get _pageSubtitle {
    if (_isStaffAdmin) {
      return 'Manage notices for your service to display in citizen app';
    } else if (_isMinistryAdmin) {
      return 'Manage ministry notices to display in citizen app';
    }
    return 'Upload and manage public notices';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _loadData() {
    context.read<NoticeBloc>().add(const LoadNoticesEvent());
    // Only load services filter for ministry admin (staff sees only their service)
    if (_isMinistryAdmin) {
      context.read<NoticeBloc>().add(const LoadServicesEvent());
    }
    context.read<NoticeBloc>().add(const LoadNoticeStatsEvent());
  }

  void _applyFilters() {
    context.read<NoticeBloc>().add(
      LoadNoticesEvent(
        serviceId: _selectedServiceId,
        status: _selectedStatus,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = value;
      });
      _applyFilters();
    });
  }

  void _onServiceChanged(String? value) {
    setState(() {
      _selectedServiceId = value;
    });
    _applyFilters();
  }

  void _onStatusChanged(String? value) {
    setState(() {
      _selectedStatus = value;
    });
    _applyFilters();
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<NoticeBloc>(),
        child: const NoticeUploadDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NoticeBloc, NoticeState>(
      listener: (context, state) {
        // Handle loading overlay
        if (state is NoticeOperationInProgress) {
          GlobalOperationOverlay.show(message: state.message);
        } else if (state is NoticeOperationSuccess ||
            state is NoticeOperationFailure ||
            state is NoticeLoaded) {
          GlobalOperationOverlay.hide();
        }

        // Show snackbar feedback
        if (state is NoticeOperationSuccess) {
          _showSnackBar(state.message, isSuccess: true);
        } else if (state is NoticeOperationFailure) {
          _showSnackBar(state.message, isSuccess: false);
        }

        // Update services list
        if (state is ServicesLoaded) {
          setState(() {
            _services = state.services;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Column(
          children: [
            BlocBuilder<NoticeBloc, NoticeState>(
              buildWhen: (prev, curr) =>
                  curr is NoticeLoaded ||
                  curr is NoticeLoading ||
                  curr is NoticeError,
              builder: (context, state) {
                int totalCount = 0;
                if (state is NoticeLoaded) {
                  totalCount = state.totalCount;
                }
                return NoticeHeader(
                  title: _pageTitle,
                  subtitle: _pageSubtitle,
                  onUpload: _showUploadDialog,
                  onRefresh: _loadData,
                  selectedServiceId: _selectedServiceId,
                  selectedStatus: _selectedStatus,
                  searchQuery: _searchQuery,
                  services: _isMinistryAdmin
                      ? _services
                      : [], // Only show for ministry admin
                  onServiceChanged: _onServiceChanged,
                  onStatusChanged: _onStatusChanged,
                  onSearchChanged: _onSearchChanged,
                  totalCount: totalCount,
                  showServiceFilter:
                      _isMinistryAdmin, // Only show filter for ministry admin
                );
              },
            ),
            Expanded(
              child: BlocBuilder<NoticeBloc, NoticeState>(
                buildWhen: (prev, curr) =>
                    curr is NoticeLoading ||
                    curr is NoticeLoaded ||
                    curr is NoticeLoadingMore ||
                    curr is NoticeError ||
                    curr is NoticeOperationSuccess ||
                    curr is NoticeOperationFailure,
                builder: (context, state) {
                  if (state is NoticeLoading) {
                    return const NoticeLoadingShimmer();
                  }

                  if (state is NoticeError && state.currentNotices == null) {
                    return NoticeErrorState(
                      message: state.message,
                      onRetry: _loadData,
                    );
                  }

                  // Get notices from various states
                  List<NoticeEntity> notices = [];
                  bool hasMore = false;

                  if (state is NoticeLoaded) {
                    notices = state.notices;
                    hasMore = state.hasMore;
                  } else if (state is NoticeLoadingMore) {
                    notices = state.notices;
                  } else if (state is NoticeOperationSuccess) {
                    notices = state.currentNotices;
                  } else if (state is NoticeOperationFailure) {
                    notices = state.currentNotices;
                  } else if (state is NoticeError) {
                    notices = state.currentNotices ?? [];
                  }

                  if (notices.isEmpty) {
                    return NoticeEmptyState(
                      title: 'No notices found',
                      subtitle: _hasActiveFilters()
                          ? 'Try adjusting your filters'
                          : 'Get started by uploading your first notice',
                      actionLabel: _hasActiveFilters() ? null : 'Upload Notice',
                      onAction: _hasActiveFilters() ? null : _showUploadDialog,
                    );
                  }

                  return Column(
                    children: [
                      Expanded(child: NoticeTable(notices: notices)),
                      if (hasMore)
                        _buildLoadMoreButton(state is NoticeLoadingMore),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryCobalt,
                  ),
                ),
              )
            : TextButton.icon(
                onPressed: () {
                  context.read<NoticeBloc>().add(const LoadMoreNoticesEvent());
                },
                icon: const Icon(Icons.expand_more),
                label: const Text('Load More'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryCobalt,
                ),
              ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedServiceId != null ||
        _selectedStatus != null ||
        _searchQuery.isNotEmpty;
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

/// Wrapper to provide BLoC from DI
class NoticeListPageWrapper extends StatelessWidget {
  const NoticeListPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NoticeBloc>(
      create: (_) => sl<NoticeBloc>(),
      child: const NoticeListPage(),
    );
  }
}
