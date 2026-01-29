import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/core/di/injection_container.dart';
import 'package:sewa_sathi/core/theme/theme.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/queue_token_entity.dart';
import 'package:sewa_sathi/features/get_token/presentation/bloc/get_token_bloc.dart';
import 'package:sewa_sathi/features/get_token/presentation/widgets/token_card.dart';

/// Screen for displaying user's booked tokens.
class MyTokensScreen extends StatelessWidget {
  const MyTokensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<GetTokenBloc>()..add(const LoadMyTokensEvent()),
      child: const _MyTokensView(),
    );
  }
}

class _MyTokensView extends StatefulWidget {
  const _MyTokensView();

  @override
  State<_MyTokensView> createState() => _MyTokensViewState();
}

class _MyTokensViewState extends State<_MyTokensView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('My Tokens'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: BlocConsumer<GetTokenBloc, GetTokenState>(
        listener: (context, state) {
          if (state is TokenCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Token cancelled successfully'),
                backgroundColor: Colors.green,
              ),
            );
            // Reload tokens
            context.read<GetTokenBloc>().add(const LoadMyTokensEvent());
          } else if (state is GetTokenError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is GetTokenLoading) {
            return const _LoadingView();
          }

          if (state is GetTokenError && state is! MyTokensLoaded) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                context.read<GetTokenBloc>().add(const LoadMyTokensEvent());
              },
            );
          }

          if (state is MyTokensLoaded) {
            return _TokensTabView(
              tabController: _tabController,
              tokens: state.tokens,
              hasMore: state.hasMore,
              isLoadingMore: state.isLoadingMore,
              onCancel: (token) => _showCancelDialog(context, token),
              onLoadMore: () {
                context.read<GetTokenBloc>().add(const LoadMoreMyTokensEvent());
              },
            );
          }

          return const _LoadingView();
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, QueueTokenEntity token) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Token?'),
        content: Text(
          'Are you sure you want to cancel token #${token.tokenNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No, Keep'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<GetTokenBloc>().add(
                CancelTokenEvent(tokenId: token.id),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

class _TokensTabView extends StatelessWidget {
  final TabController tabController;
  final List<QueueTokenEntity> tokens;
  final bool hasMore;
  final bool isLoadingMore;
  final Function(QueueTokenEntity) onCancel;
  final VoidCallback onLoadMore;

  const _TokensTabView({
    required this.tabController,
    required this.tokens,
    this.hasMore = false,
    this.isLoadingMore = false,
    required this.onCancel,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final activeTokens = tokens.where((t) => t.isActive).toList();
    final completedTokens = tokens.where((t) => t.isCompleted).toList();
    final cancelledTokens = tokens.where((t) => t.isCancelled).toList();

    return TabBarView(
      controller: tabController,
      children: [
        _TokenList(
          tokens: activeTokens,
          onCancel: onCancel,
          emptyMessage: 'No active tokens',
          emptyIcon: Icons.confirmation_number_outlined,
          hasMore: hasMore,
          isLoadingMore: isLoadingMore,
          onLoadMore: onLoadMore,
        ),
        _TokenList(
          tokens: completedTokens,
          onCancel: null,
          emptyMessage: 'No completed tokens',
          emptyIcon: Icons.check_circle_outline,
          hasMore: hasMore,
          isLoadingMore: isLoadingMore,
          onLoadMore: onLoadMore,
        ),
        _TokenList(
          tokens: cancelledTokens,
          onCancel: null,
          emptyMessage: 'No cancelled tokens',
          emptyIcon: Icons.cancel_outlined,
          hasMore: hasMore,
          isLoadingMore: isLoadingMore,
          onLoadMore: onLoadMore,
        ),
      ],
    );
  }
}

class _TokenList extends StatelessWidget {
  final List<QueueTokenEntity> tokens;
  final Function(QueueTokenEntity)? onCancel;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const _TokenList({
    required this.tokens,
    required this.onCancel,
    required this.emptyMessage,
    required this.emptyIcon,
    this.hasMore = false,
    this.isLoadingMore = false,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<GetTokenBloc>().add(const LoadMyTokensEvent());
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            final metrics = notification.metrics;
            // Load more when 80% scrolled
            if (metrics.pixels >= metrics.maxScrollExtent * 0.8 &&
                hasMore &&
                !isLoadingMore) {
              onLoadMore();
            }
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: tokens.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the bottom
            if (index >= tokens.length) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: isLoadingMore
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        )
                      : TextButton.icon(
                          onPressed: onLoadMore,
                          icon: const Icon(Icons.expand_more),
                          label: const Text('Load More'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                          ),
                        ),
                ),
              );
            }

            final token = tokens[index];
            return TokenCard(
              token: token,
              onCancel: onCancel != null && token.canCancel
                  ? () => onCancel!(token)
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primary),
          SizedBox(height: 16),
          Text(
            'Loading your tokens...',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
