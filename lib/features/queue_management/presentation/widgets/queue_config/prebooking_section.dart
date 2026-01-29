import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sewa_web/core/theme/theme.dart';

import 'queue_config_common.dart';
import 'queue_config_form_data.dart';

/// Prebooking Settings Section Widget
class PrebookingSection extends StatelessWidget {
  final QueueConfigFormData formData;
  final bool isMobile;

  const PrebookingSection({
    super.key,
    required this.formData,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return QueueConfigSectionCard(
      title: 'Prebooking Settings',
      icon: Icons.calendar_today,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enable Toggle
          Row(
            children: [
              Switch(
                value: formData.prebookingAllowed,
                onChanged: (value) => formData.setPrebookingAllowed(value),
                activeThumbColor: AppTheme.primaryCobalt,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allow Prebooking',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Citizens can book appointments in advance',
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
          if (formData.prebookingAllowed) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                // Lead Hours
                SizedBox(
                  width: isMobile ? double.infinity : 200,
                  child: TextFormField(
                    initialValue: formData.prebookingLeadHours.toString(),
                    decoration: queueConfigInputDecoration(
                      label: 'Lead Time (Hours)',
                      hint: '24',
                      suffixIcon: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Text(
                          'hrs',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final hours = int.tryParse(value) ?? 24;
                      formData.setPrebookingLeadHours(hours);
                    },
                  ),
                ),

                // Quota Per Day
                SizedBox(
                  width: isMobile ? double.infinity : 200,
                  child: TextFormField(
                    initialValue: formData.prebookingQuotaPerDay.toString(),
                    decoration: queueConfigInputDecoration(
                      label: 'Daily Quota',
                      hint: '10',
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
                      final quota = int.tryParse(value) ?? 10;
                      formData.setPrebookingQuotaPerDay(quota);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.info,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Users can book appointments ${formData.prebookingLeadHours} hours in advance. '
                      'Maximum ${formData.prebookingQuotaPerDay} prebookings per day.',
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
