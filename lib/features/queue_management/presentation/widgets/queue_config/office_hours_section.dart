import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sewa_web/core/theme/theme.dart';

import 'queue_config_common.dart';
import 'queue_config_form_data.dart';

/// Office Hours Section Widget
/// Handles office timing, lunch break, and service time configuration
class OfficeHoursSection extends StatelessWidget {
  final QueueConfigFormData formData;
  final bool isMobile;

  const OfficeHoursSection({
    super.key,
    required this.formData,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return QueueConfigSectionCard(
      title: 'Office Hours',
      icon: Icons.access_time,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Office Hours Row
          _buildOfficeHoursRow(context),
          const SizedBox(height: 24),

          // Lunch Break Toggle
          _buildLunchBreakSection(context),
          const SizedBox(height: 24),

          // Service Time Configuration
          _buildServiceTimeSection(context),
        ],
      ),
    );
  }

  Widget _buildOfficeHoursRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Working Hours',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: isMobile ? double.infinity : 200,
              child: _TimePickerField(
                label: 'Start Time',
                time: formData.officeStartTime,
                onTap: () async {
                  final picked = await showThemedTimePicker(
                    context,
                    formData.officeStartTime,
                  );
                  if (picked != null) {
                    formData.setOfficeStartTime(picked);
                  }
                },
              ),
            ),
            SizedBox(
              width: isMobile ? double.infinity : 200,
              child: _TimePickerField(
                label: 'End Time',
                time: formData.officeEndTime,
                onTap: () async {
                  final picked = await showThemedTimePicker(
                    context,
                    formData.officeEndTime,
                  );
                  if (picked != null) {
                    formData.setOfficeEndTime(picked);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLunchBreakSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Switch(
              value: formData.hasLunchBreak,
              onChanged: (value) => formData.setHasLunchBreak(value),
              activeThumbColor: AppTheme.primaryCobalt,
            ),
            const SizedBox(width: 8),
            const Text(
              'Include Lunch Break',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        if (formData.hasLunchBreak) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 200,
                child: _TimePickerField(
                  label: 'Lunch Start',
                  time:
                      formData.lunchStartTime ??
                      const TimeOfDay(hour: 12, minute: 0),
                  onTap: () async {
                    final picked = await showThemedTimePicker(
                      context,
                      formData.lunchStartTime ??
                          const TimeOfDay(hour: 12, minute: 0),
                    );
                    if (picked != null) {
                      formData.setLunchStartTime(picked);
                    }
                  },
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 200,
                child: _TimePickerField(
                  label: 'Lunch End',
                  time:
                      formData.lunchEndTime ??
                      const TimeOfDay(hour: 13, minute: 0),
                  onTap: () async {
                    final picked = await showThemedTimePicker(
                      context,
                      formData.lunchEndTime ??
                          const TimeOfDay(hour: 13, minute: 0),
                    );
                    if (picked != null) {
                      formData.setLunchEndTime(picked);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildServiceTimeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Time Configuration',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: isMobile ? 150 : 200,
              child: TextFormField(
                initialValue: formData.avgServiceTimeMinutes.toString(),
                decoration: queueConfigInputDecoration(
                  label: 'Avg. Service Time',
                  hint: '15',
                  suffixIcon: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Text(
                      'min',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  final minutes = int.tryParse(value) ?? 15;
                  formData.setAvgServiceTimeMinutes(minutes);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final minutes = int.tryParse(value);
                  if (minutes == null || minutes <= 0) {
                    return 'Must be > 0';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 24),
            // Calculated Capacity Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, color: AppTheme.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Capacity: ${formData.calculatedDailyCapacity}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Time Picker Field Widget
class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  formatTimeDisplay(time),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.access_time,
              color: AppTheme.primaryCobalt,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
