import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sewa_web/core/theme/theme.dart';

import 'queue_config_common.dart';
import 'queue_config_form_data.dart';

/// Emergency Settings Section Widget
class EmergencySection extends StatelessWidget {
  final QueueConfigFormData formData;
  final bool isMobile;

  const EmergencySection({
    super.key,
    required this.formData,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return QueueConfigSectionCard(
      title: 'Emergency Booking',
      icon: Icons.warning_amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enable Toggle
          Row(
            children: [
              Switch(
                value: formData.emergencyAllowed,
                onChanged: (value) => formData.setEmergencyAllowed(value),
                activeThumbColor: AppTheme.primaryCobalt,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allow Emergency Booking',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Priority slots for urgent cases with additional fee',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Settings (shown when enabled)
          if (formData.emergencyAllowed) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                // Emergency Fee
                SizedBox(
                  width: isMobile ? double.infinity : 200,
                  child: TextFormField(
                    initialValue: formData.emergencyFee.toStringAsFixed(0),
                    decoration: queueConfigInputDecoration(
                      label: 'Emergency Fee',
                      hint: '500',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Text(
                          'Rs.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final fee = double.tryParse(value) ?? 500;
                      formData.setEmergencyFee(fee);
                    },
                  ),
                ),

                // Quota Per Day
                SizedBox(
                  width: isMobile ? double.infinity : 200,
                  child: TextFormField(
                    initialValue: formData.emergencyQuotaPerDay.toString(),
                    decoration: queueConfigInputDecoration(
                      label: 'Daily Quota',
                      hint: '5',
                      suffixIcon: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Text(
                          'slots',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final quota = int.tryParse(value) ?? 5;
                      formData.setEmergencyQuotaPerDay(quota);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Warning Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: AppTheme.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Emergency slots cost Rs. ${formData.emergencyFee.toStringAsFixed(0)} extra. '
                      'Limited to ${formData.emergencyQuotaPerDay} per day.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
