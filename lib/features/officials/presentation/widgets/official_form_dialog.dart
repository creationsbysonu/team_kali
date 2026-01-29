import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/officials/domain/entities/official.dart';
import 'package:sewa_web/features/officials/presentation/bloc/officials_bloc.dart';

/// Dialog for creating or editing an official
class OfficialFormDialog extends StatefulWidget {
  final Official? official;
  final String ministryId;

  const OfficialFormDialog({
    super.key,
    this.official,
    required this.ministryId,
  });

  @override
  State<OfficialFormDialog> createState() => _OfficialFormDialogState();
}

class _OfficialFormDialogState extends State<OfficialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.official?.name ?? '');
    _roleController = TextEditingController(text: widget.official?.role ?? '');
    _isActive = widget.official?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.official != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_add,
                      color: AppTheme.primaryCobalt,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Edit Official' : 'Add New Official',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryCobalt,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                const Divider(height: 32),
                const SizedBox(height: 24),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildRoleField(),
                if (isEditing) ...[
                  const SizedBox(height: 16),
                  _buildActiveSwitch(),
                ],
                const SizedBox(height: 24),
                _buildActions(context, isEditing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Name *',
        labelStyle: TextStyle(color: Colors.grey[700]),
        hintText: 'Enter official name',
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: const BorderSide(color: AppTheme.primaryCobalt, width: 2),
        ),
        prefixIcon: const Icon(Icons.person, color: AppTheme.primaryCobalt),
      ),
      style: const TextStyle(color: Colors.black87),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Name is required';
        }
        return null;
      },
    );
  }

  Widget _buildRoleField() {
    return TextFormField(
      controller: _roleController,
      decoration: InputDecoration(
        labelText: 'Role *',
        labelStyle: TextStyle(color: Colors.grey[700]),
        hintText: 'Enter official role/designation',
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: const BorderSide(color: AppTheme.primaryCobalt, width: 2),
        ),
        prefixIcon: const Icon(Icons.work, color: AppTheme.primaryCobalt),
      ),
      style: const TextStyle(color: Colors.black87),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Role is required';
        }
        return null;
      },
    );
  }

  Widget _buildActiveSwitch() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Active Status',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
            activeThumbColor: AppTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isEditing) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleSubmit(context, isEditing),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCobalt,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isEditing ? 'Update' : 'Create',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  void _handleSubmit(BuildContext context, bool isEditing) {
    if (_formKey.currentState!.validate()) {
      if (isEditing) {
        context.read<OfficialsBloc>().add(
          UpdateOfficialEvent(
            ministryId: widget.ministryId,
            officialId: widget.official!.id,
            name: _nameController.text.trim(),
            role: _roleController.text.trim(),
            isActive: _isActive,
          ),
        );
      } else {
        context.read<OfficialsBloc>().add(
          CreateOfficialEvent(
            ministryId: widget.ministryId,
            name: _nameController.text.trim(),
            role: _roleController.text.trim(),
          ),
        );
      }
      Navigator.of(context).pop();
    }
  }
}
