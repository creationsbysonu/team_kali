import 'package:flutter/material.dart';
import 'package:sewa_web/core/theme/theme.dart';

import 'queue_config_common.dart';
import 'queue_config_form_data.dart';

/// Progress Steps Configuration Section Widget
class ProgressStepsSection extends StatelessWidget {
  final QueueConfigFormData formData;
  final bool isMobile;

  const ProgressStepsSection({
    super.key,
    required this.formData,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return QueueConfigSectionCard(
      title: 'Progress Steps Configuration',
      icon: Icons.timeline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enable Toggle
          Row(
            children: [
              Switch(
                value: formData.enableProgressTracking,
                onChanged: (value) => formData.setEnableProgressTracking(value),
                activeThumbColor: AppTheme.primaryCobalt,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable Progress Tracking',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Track application progress through defined steps',
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

          // Steps (shown when enabled)
          if (formData.enableProgressTracking) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Steps List with Reorder
            if (formData.progressSteps.isNotEmpty) ...[
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false, // Disable default handles
                itemCount: formData.progressSteps.length,
                onReorder: (oldIndex, newIndex) {
                  formData.reorderProgressSteps(oldIndex, newIndex);
                },
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                        child: child,
                      );
                    },
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  return _ProgressStepItem(
                    key: ValueKey('step_$index'),
                    index: index,
                    stepTitle: formData.progressSteps[index],
                    onEdit: () => _showEditStepDialog(context, index),
                    onDelete: () => formData.removeProgressStep(index),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Add Step Button
            OutlinedButton.icon(
              onPressed: () => _showAddStepDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Progress Step'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryCobalt,
                side: const BorderSide(color: AppTheme.primaryCobalt),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),

            if (formData.progressSteps.isEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.info.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.info, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add progress steps to track application workflow. '
                        'Drag steps to reorder them.',
                        style: TextStyle(
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
        ],
      ),
    );
  }

  void _showAddStepDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Progress Step'),
        content: SizedBox(
          width: 400,
          child: TextFormField(
            controller: controller,
            decoration: queueConfigInputDecoration(
              label: 'Step Title',
              hint: 'e.g., Document Verification',
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                formData.addProgressStep(controller.text.trim());
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCobalt,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditStepDialog(BuildContext context, int index) {
    final controller = TextEditingController(
      text: formData.progressSteps[index],
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Progress Step'),
        content: SizedBox(
          width: 400,
          child: TextFormField(
            controller: controller,
            decoration: queueConfigInputDecoration(
              label: 'Step Title',
              hint: 'e.g., Document Verification',
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                formData.updateProgressStep(index, controller.text.trim());
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCobalt,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Individual Progress Step Item
class _ProgressStepItem extends StatelessWidget {
  final int index;
  final String stepTitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProgressStepItem({
    super.key,
    required this.index,
    required this.stepTitle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Drag Handle (left side only) - wrapped in ReorderableDragStartListener
          ReorderableDragStartListener(
            index: index,
            child: const MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Icon(Icons.drag_handle, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(width: 12),

          // Step Number
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryCobalt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Step Title
          Expanded(
            child: Text(
              stepTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // Actions
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 20),
            color: AppTheme.textSecondary,
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 20),
            color: AppTheme.error,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
