import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/services/domain/entities/service.dart';
import 'package:sewa_web/features/services/presentation/bloc/service_bloc.dart';

/// Page for selecting a service (for staff login)
class ServiceListPage extends StatelessWidget {
  final String ministryName;
  final Function(Service service) onServiceSelected;
  final VoidCallback onBack;

  const ServiceListPage({
    super.key,
    required this.ministryName,
    required this.onServiceSelected,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ServiceBloc, ServiceState, bool>(
      selector: (state) => state is ServiceOperationLoading,
      builder: (context, isOperationInProgress) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppTheme.primaryCobaltDark,
              body: SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(context),

                    // Service list
                    Expanded(
                      child: BlocBuilder<ServiceBloc, ServiceState>(
                        builder: (context, state) {
                          if (state is ServiceLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          }

                          if (state is ServiceError) {
                            return _buildErrorState(context, state.message);
                          }

                          if (state is ServicesLoaded) {
                            if (state.services.isEmpty) {
                              return _buildEmptyState();
                            }
                            return _buildServiceList(state.services);
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Blur loading overlay for operations
            if (isOperationInProgress)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryCobalt,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Processing...',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Service',
                  style: AppTheme.headingMedium().copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  ministryName,
                  style: AppTheme.bodyMedium().copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.accentRed, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyLarge().copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.work_off, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          Text(
            'No services available',
            style: AppTheme.bodyLarge().copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList(List<Service> services) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: services.length,
      itemBuilder: (context, index) => _ServiceCard(
        service: services[index],
        onTap: () => onServiceSelected(services[index]),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.work,
                  color: AppTheme.accentGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: AppTheme.headingSmall().copyWith(
                        color: AppTheme.primaryCobaltDark,
                      ),
                    ),
                    if (service.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        service.description!,
                        style: AppTheme.bodyMedium().copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTag(service.serviceType.value.toUpperCase()),
                        if (service.feeAmount.isNotEmpty &&
                            service.feeAmount != '0') ...[
                          const SizedBox(width: 8),
                          _buildTag('Rs. ${service.feeAmount}'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
