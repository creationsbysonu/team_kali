import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/ministry/data/models/staff_service_model.dart';

/// Public page to display services - Staff Login Flow
/// Uses BLoC pattern like MinistryListPage
/// UI matches ministry list exactly
class PublicServicesPage extends StatelessWidget {
  final List<StaffServiceModel> services;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final void Function(StaffServiceModel service) onServiceSelected;
  final VoidCallback onBack;

  const PublicServicesPage({
    super.key,
    required this.services,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onServiceSelected,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCobaltDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBack,
        ),
        title: const Text(
          'Select Service',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white.withAlpha(180),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.work_outline,
                size: 64,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              const Text(
                'No services available',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Same layout as ministry list - 600px max width, simple list
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return _ServiceCard(
              service: service,
              onTap: () => onServiceSelected(service),
            );
          },
        ),
      ),
    );
  }
}

/// Service Card - EXACTLY matching ministry card style
class _ServiceCard extends StatelessWidget {
  final StaffServiceModel service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Left: Service logo
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: service.hasLogo
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: service.serviceLogo!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.accentGreen,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.work_outline,
                            color: AppTheme.accentGreen,
                            size: 28,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.work_outline,
                        color: AppTheme.accentGreen,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),

              // Middle: Service name
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      service.serviceName,
                      style: AppTheme.bodyLarge().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Service',
                      style: AppTheme.bodySmall().copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical divider
              Container(
                height: 40,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: AppTheme.textSecondary.withAlpha(50),
              ),

              // Right: Staff info
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    // Staff avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: service.hasStaffImage
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: service.staffImage!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.withAlpha(30),
                                  child: const Icon(
                                    Icons.person,
                                    size: 28,
                                    color: Colors.grey,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.withAlpha(30),
                                  child: const Icon(
                                    Icons.person,
                                    size: 28,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.withAlpha(30),
                              child: const Icon(
                                Icons.person,
                                size: 28,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Staff name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            service.staffName,
                            style: AppTheme.bodyLarge().copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentGreen,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Staff Member',
                            style: AppTheme.bodySmall().copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
