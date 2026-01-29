import 'package:flutter/material.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/queue_config_entity.dart';

/// Badge widget for displaying availability status.
class AvailabilityBadge extends StatelessWidget {
  final AvailabilityStatus status;
  final bool showDetails;

  const AvailabilityBadge({
    super.key,
    required this.status,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showDetails ? 16 : 10,
        vertical: showDetails ? 12 : 6,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(showDetails ? 12 : 8),
        border: showDetails ? Border.all(color: _getBorderColor()) : null,
      ),
      child: showDetails
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getIcon(), size: 18, color: _getTextColor()),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getTextColor(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildDetailItem(
                      icon: Icons.people_outline,
                      label: 'Current Queue',
                      value: '${status.currentQueueLength}',
                    ),
                    const SizedBox(width: 24),
                    _buildDetailItem(
                      icon: Icons.access_time,
                      label: 'Est. Wait',
                      value: status.estimatedWaitTimeDisplay,
                    ),
                  ],
                ),
                if (status.isAcceptingTokens &&
                    status.nextAvailableSlot != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailItem(
                    icon: Icons.schedule,
                    label: 'Next Slot',
                    value: status.nextAvailableSlot!,
                  ),
                ],
                if (!status.isAcceptingTokens && status.reason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    status.reason,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getTextColor().withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getIcon(), size: 14, color: _getTextColor()),
                const SizedBox(width: 6),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getTextColor(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: _getTextColor().withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: _getTextColor().withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _getTextColor(),
          ),
        ),
      ],
    );
  }

  Color _getBackgroundColor() {
    if (status.isAcceptingTokens) {
      return Colors.green.shade50;
    } else {
      return Colors.red.shade50;
    }
  }

  Color _getBorderColor() {
    if (status.isAcceptingTokens) {
      return Colors.green.shade200;
    } else {
      return Colors.red.shade200;
    }
  }

  Color _getTextColor() {
    if (status.isAcceptingTokens) {
      return Colors.green.shade700;
    } else {
      return Colors.red.shade700;
    }
  }

  IconData _getIcon() {
    if (status.isAcceptingTokens) {
      return Icons.check_circle;
    } else {
      return Icons.cancel;
    }
  }

  String _getStatusText() {
    if (status.isAcceptingTokens) {
      return 'Accepting Tokens';
    } else {
      return 'Not Accepting';
    }
  }
}

/// Compact availability indicator.
class AvailabilityIndicator extends StatelessWidget {
  final bool isAvailable;
  final String? reason;

  const AvailabilityIndicator({
    super.key,
    required this.isAvailable,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAvailable ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isAvailable ? 'Available' : (reason ?? 'Unavailable'),
          style: TextStyle(
            fontSize: 12,
            color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ],
    );
  }
}
