import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/features/notice/domain/entities/notice_entity.dart';
import 'package:sewa_sathi/features/notice/domain/usecases/get_notices_usecase.dart';
import 'package:sewa_sathi/features/notice/presentation/bloc/notice_bloc.dart';
import 'package:sewa_sathi/features/notice/presentation/pages/notice_detail_screen.dart';
import 'package:sewa_sathi/features/notice/presentation/widgets/notice_card.dart';
import 'package:sewa_sathi/features/notice/presentation/widgets/filter_bottom_sheet.dart';

/// Notice list screen with pagination, filters, and search.
///
/// Features:
/// - Pull-to-refresh
/// - Infinite scroll pagination
/// - Filter by ministry, service, and file type
/// - Search notices
/// - Navigate to detail on tap
class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial notices
    context.read<NoticeBloc>().add(const LoadNoticesEvent());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final state = context.read<NoticeBloc>().state;
      if (state is NoticeLoaded && state.hasMore && !state.isLoadingMore) {
        context.read<NoticeBloc>().add(LoadMoreNoticesEvent());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: BlocBuilder<NoticeBloc, NoticeState>(
        builder: (context, state) {
          if (state is NoticeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NoticeError) {
            return _buildErrorWidget(state.message);
          }

          if (state is NoticeLoaded) {
            if (state.notices.isEmpty) {
              return _buildEmptyWidget();
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: Column(
                children: [
                  if (_hasActiveFilters(state.currentParams))
                    _buildActiveFiltersChip(state.currentParams),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.notices.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.notices.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final notice = state.notices[index];
                        return NoticeCard(
                          notice: notice,
                          onTap: () => _navigateToDetail(notice),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// App bar with filter button only.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Notices',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: const Color(0xFF0047AB),
      foregroundColor: Colors.white,
      actions: [
        BlocBuilder<NoticeBloc, NoticeState>(
          builder: (context, state) {
            final hasFilters =
                state is NoticeLoaded && _hasActiveFilters(state.currentParams);

            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: _showFilterBottomSheet,
                ),
                if (hasFilters)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Active filters chip displayed at top of list.
  Widget _buildActiveFiltersChip(NoticeParams params) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0047AB).withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: Color(0xFF0047AB)),
          const SizedBox(width: 8),
          const Text(
            'Filters applied',
            style: TextStyle(
              color: Color(0xFF0047AB),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              'Clear',
              style: TextStyle(color: Color(0xFF0047AB)),
            ),
          ),
        ],
      ),
    );
  }

  /// Error widget with retry button.
  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<NoticeBloc>().add(const LoadNoticesEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0047AB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state widget.
  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No notices found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or check back later',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  /// Pull-to-refresh handler.
  Future<void> _onRefresh() async {
    context.read<NoticeBloc>().add(RefreshNoticesEvent());
    // Wait for the refresh to complete
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Show filter bottom sheet.
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<NoticeBloc>(),
        child: FilterBottomSheet(
          currentParams: _getCurrentParams(),
          onApply: (params) {
            context.read<NoticeBloc>().add(FilterNoticesEvent(params: params));
          },
        ),
      ),
    );
  }

  /// Get current filter params from state.
  NoticeParams _getCurrentParams() {
    final state = context.read<NoticeBloc>().state;
    if (state is NoticeLoaded) {
      return state.currentParams;
    }
    return const NoticeParams();
  }

  /// Check if there are active filters.
  bool _hasActiveFilters(NoticeParams params) {
    return params.ministryId != null ||
        params.serviceId != null ||
        params.fileType != null ||
        (params.search != null && params.search!.isNotEmpty);
  }

  /// Clear all filters.
  void _clearFilters() {
    context.read<NoticeBloc>().add(
      const FilterNoticesEvent(params: NoticeParams()),
    );
  }

  /// Navigate to notice detail screen.
  void _navigateToDetail(NoticeEntity notice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoticeDetailScreen(noticeId: notice.id),
      ),
    );
  }
}
