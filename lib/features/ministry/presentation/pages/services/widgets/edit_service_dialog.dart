import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/ministry/domain/entities/staff_service_entity.dart';
import 'package:sewa_web/features/ministry/presentation/bloc/staff_service_bloc.dart';

/// Dialog to edit an existing service
/// Follows the same pattern as CreateServiceDialog
class EditServiceDialog extends StatefulWidget {
  final StaffService service;

  const EditServiceDialog({super.key, required this.service});

  @override
  State<EditServiceDialog> createState() => _EditServiceDialogState();
}

class _EditServiceDialogState extends State<EditServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _serviceNameController;
  late final TextEditingController _staffNameController;

  Uint8List? _serviceLogoBytes;
  String? _serviceLogoFileName;
  Uint8List? _staffImageBytes;
  String? _staffImageFileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _serviceNameController = TextEditingController(
      text: widget.service.serviceName,
    );
    _staffNameController = TextEditingController(
      text: widget.service.staffName,
    );
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _staffNameController.dispose();
    super.dispose();
  }

  Future<void> _pickServiceLogo() async {
    if (_isLoading) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _serviceLogoBytes = result.files.single.bytes;
        _serviceLogoFileName = result.files.single.name;
      });
    }
  }

  Future<void> _pickStaffImage() async {
    if (_isLoading) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _staffImageBytes = result.files.single.bytes;
        _staffImageFileName = result.files.single.name;
      });
    }
  }

  void _handleUpdate() {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    context.read<StaffServiceBloc>().add(
      UpdateStaffServiceEvent(
        id: widget.service.id,
        serviceName: _serviceNameController.text.trim(),
        staffName: _staffNameController.text.trim(),
        serviceLogoBytes: _serviceLogoBytes,
        serviceLogoFileName: _serviceLogoFileName,
        staffImageBytes: _staffImageBytes,
        staffImageFileName: _staffImageFileName,
      ),
    );
  }

  void _showSuccess(String serviceName) {
    Navigator.of(context).pop(); // Close this dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('Service "$serviceName" updated successfully!'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffServiceBloc, StaffServiceState>(
      listener: (context, state) {
        if (state is StaffServiceOperationSuccess) {
          _showSuccess(widget.service.serviceName);
        } else if (state is StaffServiceError) {
          _showError(state.message);
        }
      },
      child: PopScope(
        canPop: !_isLoading,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit, color: AppTheme.accentBlue),
              const SizedBox(width: 12),
              Text('Edit ${widget.service.serviceName}'),
              if (_isLoading) ...[
                const Spacer(),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          content: SizedBox(
            width: 500,
            child: AbsorbPointer(
              absorbing: _isLoading,
              child: Opacity(
                opacity: _isLoading ? 0.6 : 1.0,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service Logo Upload
                        const Text(
                          'Service Logo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: GestureDetector(
                            onTap: _pickServiceLogo,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              child: _serviceLogoBytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        _serviceLogoBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : widget.service.serviceLogo != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        widget.service.serviceLogo!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 32,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Change Logo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Service Name Field
                        TextFormField(
                          controller: _serviceNameController,
                          decoration: const InputDecoration(
                            labelText: 'Service Name *',
                            hintText: 'e.g., Birth Certificate',
                            prefixIcon: Icon(Icons.business_center),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v?.isEmpty == true
                              ? 'Service name is required'
                              : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Staff Name Field
                        TextFormField(
                          controller: _staffNameController,
                          decoration: const InputDecoration(
                            labelText: 'Staff Name *',
                            hintText: 'e.g., Ram Prasad Sharma',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v?.isEmpty == true
                              ? 'Staff name is required'
                              : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Staff Image Upload
                        const Text(
                          'Staff Image',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: GestureDetector(
                            onTap: _pickStaffImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              child: _staffImageBytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        _staffImageBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : widget.service.staffImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        widget.service.staffImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          size: 32,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Change Image',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Info Text
                        Text(
                          'Only changed fields will be updated.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
