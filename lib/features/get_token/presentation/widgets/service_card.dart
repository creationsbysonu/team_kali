import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sewa_sathi/core/theme/theme.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/staff_service_entity.dart';

/// Card widget for displaying a service.
class ServiceCard extends StatelessWidget {
  final StaffServiceEntity service;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAvailable = service.isAvailableToday;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAvailable ? Colors.grey.shade200 : Colors.red.shade100,
        ),
      ),
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.7,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Service logo
                _buildLogo(),
                const SizedBox(width: 16),

                // Service info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              service.serviceName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildAvailabilityBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Staff info
                      Row(
                        children: [
                          _buildStaffAvatar(),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              service.staffName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Unavailability reason
                      if (!isAvailable &&
                          service.availabilityReason != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  service.availabilityReason!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow icon
                if (isAvailable)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: service.hasLogo
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: service.serviceLogoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Icon(
                  Icons.description_outlined,
                  color: AppTheme.primary,
                  size: 24,
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.description_outlined,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
            )
          : const Icon(
              Icons.description_outlined,
              color: AppTheme.primary,
              size: 24,
            ),
    );
  }

  Widget _buildStaffAvatar() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: service.hasStaffImage
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: service.staffImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                errorWidget: (context, url, error) =>
                    Icon(Icons.person, size: 14, color: Colors.grey.shade500),
              ),
            )
          : Icon(Icons.person, size: 14, color: Colors.grey.shade500),
    );
  }

  Widget _buildAvailabilityBadge() {
    final isAvailable = service.isAvailableToday;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'Available' : 'Unavailable',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
