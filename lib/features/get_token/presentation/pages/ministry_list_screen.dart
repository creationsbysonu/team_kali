import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/core/di/injection_container.dart';
import 'package:sewa_sathi/core/routes/route_names.dart';
import 'package:sewa_sathi/core/theme/theme.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/ministry_entity.dart';
import 'package:sewa_sathi/features/get_token/presentation/bloc/get_token_bloc.dart';
import 'package:sewa_sathi/features/get_token/presentation/widgets/ministry_card.dart';

/// Screen for displaying list of ministries.
class MinistryListScreen extends StatelessWidget {
  final int placeId;

  const MinistryListScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<GetTokenBloc>()
            ..add(LoadMinistriesEvent(placeId: placeId.toString())),
      child: _MinistryListView(placeId: placeId),
    );
  }
}

class _MinistryListView extends StatelessWidget {
  final int placeId;

  const _MinistryListView({required this.placeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Select Ministry'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<GetTokenBloc, GetTokenState>(
        builder: (context, state) {
          if (state is GetTokenLoading) {
            return const _LoadingView();
          }

          if (state is GetTokenError) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                final bloc = context.read<GetTokenBloc>();
                bloc.add(LoadMinistriesEvent(placeId: placeId.toString()));
              },
            );
          }

          if (state is MinistriesLoaded) {
            if (state.ministries.isEmpty) {
              return const _EmptyView();
            }
            return _MinistryListContent(
              ministries: state.ministries,
              hasMore: state.hasMore,
              isLoadingMore: state.isLoadingMore,
              totalEstimate: state.totalEstimate,
            );
          }

          return const _LoadingView();
        },
      ),
    );
  }
}

class _MinistryListContent extends StatelessWidget {
  final List<MinistryEntity> ministries;
  final bool hasMore;
  final bool isLoadingMore;
  final int? totalEstimate;

  const _MinistryListContent({
    required this.ministries,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.totalEstimate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Government Ministries',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                totalEstimate != null
                    ? '${ministries.length} of ~$totalEstimate ministries'
                    : '${ministries.length} ministries available',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search ministries...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        // Ministry list with lazy loading
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification) {
                final metrics = notification.metrics;
                // Load more when 80% scrolled
                if (metrics.pixels >= metrics.maxScrollExtent * 0.8 &&
                    hasMore &&
                    !isLoadingMore) {
                  context.read<GetTokenBloc>().add(
                    const LoadMoreMinistriesEvent(),
                  );
                }
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: ministries.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the bottom
                if (index >= ministries.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  );
                }

                final ministry = ministries[index];
                return MinistryCard(
                  ministry: ministry,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      RouteNames.serviceList,
                      arguments: ministry,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
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
            'Loading ministries...',
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Ministries Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no ministries available for this location.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
