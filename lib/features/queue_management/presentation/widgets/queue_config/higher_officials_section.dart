import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/officials/presentation/bloc/officials_bloc.dart';

import 'queue_config_common.dart';
import 'queue_config_form_data.dart';

/// Higher Officials Assignment Section Widget
/// Multi-select interface for assigning higher officials to the queue
class HigherOfficialsSection extends StatelessWidget {
  final QueueConfigFormData formData;
  final bool isMobile;

  const HigherOfficialsSection({
    super.key,
    required this.formData,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return QueueConfigSectionCard(
      title: 'Higher Officials Assignment',
      icon: Icons.people,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assign higher officials for escalation and grievance handling',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          BlocBuilder<OfficialsBloc, OfficialsState>(
            builder: (context, state) {
              if (state is OfficialsLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (state is OfficialsLoaded) {
                return _buildOfficialsSelector(context, state.officials);
              }

              if (state is OfficialsError) {
                return _buildErrorState(state.message);
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialsSelector(
    BuildContext context,
    List<dynamic> officials,
  ) {
    if (officials.isEmpty) {
      return _buildEmptyState();
    }

    // Get selected officials details
    final selectedOfficials = officials
        .where((o) => formData.selectedOfficialIds.contains(o.id))
        .toList();

    // Get available officials (not yet selected)
    final availableOfficials = officials
        .where((o) => !formData.selectedOfficialIds.contains(o.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected officials chips
        if (selectedOfficials.isNotEmpty) ...[
          const Text(
            'Selected Officials:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedOfficials.map((official) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: AppTheme.primaryCobalt,
                  child: Text(
                    official.displayName.isNotEmpty
                        ? official.displayName[0].toUpperCase()
                        : 'O',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                label: Text(
                  official.displayName,
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                backgroundColor: AppTheme.primaryCobalt.withOpacity(0.15),
                deleteIcon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                onDeleted: () => formData.removeOfficialId(official.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Add official dropdown - wrapped in LayoutBuilder for proper constraints
        // Key is required to force rebuild when available officials change
        if (availableOfficials.isNotEmpty)
          LayoutBuilder(
            key: ValueKey(
              'dropdown_${availableOfficials.length}_${formData.selectedOfficialIds.length}',
            ),
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(
                    'officials_dropdown_${availableOfficials.map((o) => o.id).join('_')}',
                  ),
                  initialValue: null,
                  isExpanded: true,
                  decoration: queueConfigInputDecoration(
                    label: 'Add Official',
                    hint: 'Select an official to add',
                  ),
                  items: availableOfficials.map((official) {
                    return DropdownMenuItem<String>(
                      value: official.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.primaryCobalt,
                            child: Text(
                              official.displayName.isNotEmpty
                                  ? official.displayName[0].toUpperCase()
                                  : 'O',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  official.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (official.role.isNotEmpty)
                                  Text(
                                    official.role,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      formData.addOfficialId(value);
                    }
                  },
                ),
              );
            },
          )
        else if (selectedOfficials.isEmpty)
          _buildInfoState(
            'No officials selected. Select officials from the dropdown above.',
          )
        else
          _buildSuccessState(
            'All ${officials.length} officials have been assigned',
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.warning),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.warning),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No officials found. Please add officials from the Officials page first.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error loading officials: $message',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
