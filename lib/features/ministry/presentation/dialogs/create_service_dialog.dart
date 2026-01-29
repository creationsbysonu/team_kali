import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/ministry/presentation/bloc/staff_service_bloc.dart';

/// Dialog to create a new service with staff account
/// Follows the same pattern as CreateMinistryDialog
class CreateServiceDialog extends StatefulWidget {
  const CreateServiceDialog({super.key});

  @override
  State<CreateServiceDialog> createState() => _CreateServiceDialogState();
}

class _CreateServiceDialogState extends State<CreateServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _staffNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Uint8List? _serviceLogoBytes;
  String? _serviceLogoFileName;
  Uint8List? _staffImageBytes;
  String? _staffImageFileName;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _serviceNameController.dispose();
    _staffNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  void _handleCreate() {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    context.read<StaffServiceBloc>().add(
      CreateStaffServiceEvent(
        serviceName: _serviceNameController.text.trim(),
        staffName: _staffNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
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
            Text('Service "$serviceName" created successfully!'),
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
        if (state is StaffServiceCreated) {
          _showSuccess(state.service.serviceName);
        } else if (state is StaffServiceError) {
          _showError(state.message);
        }
      },
      child: PopScope(
        canPop: !_isLoading,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.add_business, color: AppTheme.accentBlue),
              const SizedBox(width: 12),
              const Text('Add New Service'),
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
                                          'Add Logo',
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
                                          'Add Image',
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

                        // Staff Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Staff Email *',
                            hintText: 'staff@ministry.gov.np',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v?.isEmpty == true) return 'Email is required';
                            if (!v!.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Staff Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Staff Password *',
                            hintText: 'Min 8 characters',
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v?.isEmpty == true) {
                              return 'Password is required';
                            }
                            if (v!.length < 8) return 'Minimum 8 characters';
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleCreate(),
                        ),
                        const SizedBox(height: 16),

                        // Info Text
                        Text(
                          'This will create a new service and staff account.',
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
              onPressed: _isLoading ? null : _handleCreate,
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
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
