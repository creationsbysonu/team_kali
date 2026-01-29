import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sewa_web/core/theme/theme.dart';

/// Dialog shown when clicking non-editable days (Saturday/Holiday)
class NonEditableDayDialog extends StatelessWidget {
  final DateTime date;
  final String type; // 'Saturday' or 'Holiday'
  final String? holidayName;

  const NonEditableDayDialog({
    super.key,
    required this.date,
    required this.type,
    this.holidayName,
  });

  @override
  Widget build(BuildContext context) {
    final isSaturday = type == 'Saturday';
    final icon = isSaturday ? Icons.weekend : Icons.celebration;
    final color = isSaturday ? Colors.grey[600]! : Colors.orange[600]!;

    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSaturday ? 'Weekly Holiday' : 'Public Holiday',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 48, color: color),
                  const SizedBox(height: 16),
                  Text(
                    isSaturday
                        ? 'Saturday - Weekly Holiday'
                        : holidayName ?? 'Holiday',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This day is automatically marked as absent and cannot be edited.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryCobalt,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
