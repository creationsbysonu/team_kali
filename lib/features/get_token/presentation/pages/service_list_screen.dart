import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sewa_sathi/core/di/injection_container.dart';
import 'package:sewa_sathi/core/routes/route_names.dart';
import 'package:sewa_sathi/core/theme/theme.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/ministry_entity.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/staff_service_entity.dart';
import 'package:sewa_sathi/features/get_token/presentation/bloc/get_token_bloc.dart';
import 'package:sewa_sathi/features/get_token/presentation/widgets/service_card.dart';

/// Screen for displaying list of services under a ministry.
class ServiceListScreen extends StatelessWidget {
  final MinistryEntity ministry;

  const ServiceListScreen({super.key, required this.ministry});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<GetTokenBloc>()
        ..add(
          LoadServicesEvent(
            ministryId: ministry.id,
            ministryName: ministry.name,
          ),
        ),
      child: _ServiceListView(ministry: ministry),
    );
  }
}

class _ServiceListView extends StatelessWidget {
  final MinistryEntity ministry;

  const _ServiceListView({required this.ministry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // App bar with ministry info
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _MinistryHeader(ministry: ministry),
            ),
            title: Text(
              ministry.name,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),

          // Content
          BlocBuilder<GetTokenBloc, GetTokenState>(
            builder: (context, state) {
              if (state is GetTokenLoading) {
                return const SliverFillRemaining(child: _LoadingView());
              }

              if (state is GetTokenError) {
                return SliverFillRemaining(
                  child: _ErrorView(
                    message: state.message,
                    onRetry: () {
                      context.read<GetTokenBloc>().add(
                        LoadServicesEvent(
                          ministryId: ministry.id,
                          ministryName: ministry.name,
                        ),
                      );
                    },
                  ),
                );
              }

              if (state is ServicesLoaded) {
                if (state.services.isEmpty) {
                  return const SliverFillRemaining(child: _EmptyView());
                }
                return _ServiceList(
                  services: state.services,
                  hasMore: state.hasMore,
                  isLoadingMore: state.isLoadingMore,
                  totalEstimate: state.totalEstimate,
                );
              }

              return const SliverFillRemaining(child: _LoadingView());
            },
          ),
        ],
      ),
    );
  }
}

class _MinistryHeader extends StatelessWidget {
  final MinistryEntity ministry;

  const _MinistryHeader({required this.ministry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
          child: Row(
            children: [
              // Ministry logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ministry.hasLogo
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: ministry.logoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Icon(
                            Icons.account_balance,
                            color: Colors.white,
                            size: 36,
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.account_balance,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 36,
                      ),
              ),
              const SizedBox(width: 16),
              // Ministry info
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ministry.address != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ministry.address!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${ministry.servicesCount} Services',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceList extends StatelessWidget {
  final List<StaffServiceEntity> services;
  final bool hasMore;
  final bool isLoadingMore;
  final int? totalEstimate;

  const _ServiceList({
    required this.services,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.totalEstimate,
  });

  @override
  Widget build(BuildContext context) {
    final availableServices = services
        .where((s) => s.isAvailableToday)
        .toList();
    final unavailableServices = services
        .where((s) => !s.isAvailableToday)
        .toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 16),

        // Total count indicator
        if (totalEstimate != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Showing ${services.length} of ~$totalEstimate services',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),

        // Available services section
        if (availableServices.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Available Today (${availableServices.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          ...availableServices.map(
            (service) => ServiceCard(
              service: service,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.serviceDetails,
                  arguments: service,
                );
              },
            ),
          ),
        ],

        // Unavailable services section
        if (unavailableServices.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Unavailable Today (${unavailableServices.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ...unavailableServices.map(
            (service) => ServiceCard(service: service, onTap: null),
          ),
        ],

        // Load more indicator
        if (hasMore)
          Padding(
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
                      onPressed: () {
                        context.read<GetTokenBloc>().add(
                          const LoadMoreServicesEvent(),
                        );
                      },
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Load More'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                      ),
                    ),
            ),
          ),

        const SizedBox(height: 24),
      ]),
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
            'Loading services...',
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
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Services Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This ministry has no services available at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
