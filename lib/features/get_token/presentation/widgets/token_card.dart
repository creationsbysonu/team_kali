import 'package:flutter/material.dart';
import 'package:sewa_sathi/core/theme/theme.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/queue_token_entity.dart';

/// Card widget for displaying a token.
class TokenCard extends StatelessWidget {
  final QueueTokenEntity token;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;

  const TokenCard({super.key, required this.token, this.onCancel, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with token number and status
              Row(
                children: [
                  // Token number
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Token',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                        Text(
                          '#${token.tokenNumber}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Service and ministry info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          token.serviceName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          token.ministryName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  _buildStatusBadge(),
                ],
              ),

              const Divider(height: 24),

              // Details row
              Row(
                children: [
                  // Expected time
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.access_time,
                      label: 'Expected Time',
                      value: token.expectedTimeDisplayText,
                    ),
                  ),

                  // Position in queue
                  if (token.positionInQueue != null)
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.people_outline,
                        label: 'Position',
                        value: '#${token.positionInQueue}',
                      ),
                    ),

                  // Booking type
                  if (token.isEmergency || token.isPrebooked)
                    Expanded(
                      child: _buildInfoItem(
                        icon: token.isEmergency
                            ? Icons.bolt
                            : Icons.calendar_today,
                        label: 'Type',
                        value: token.isEmergency ? 'Emergency' : 'Prebooked',
                        valueColor: token.isEmergency
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ),
                ],
              ),

              // Date
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    token.bookingDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  const Spacer(),

                  // Cancel button
                  if (token.canCancel && onCancel != null)
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 13, color: Colors.red),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        backgroundColor: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: token.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        token.statusDisplayText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: token.statusColor,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
