import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sewa_web/core/theme/theme.dart';

import 'queue_config_common.dart';
import 'queue_config_form_data.dart';

/// Documents Required Section Widget
/// Handles document list with file picker for sample images
class DocumentsSection extends StatelessWidget {
  final QueueConfigFormData formData;
  final bool isMobile;

  const DocumentsSection({
    super.key,
    required this.formData,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return QueueConfigSectionCard(
      title: 'Required Documents',
      icon: Icons.description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add documents that applicants need to provide for this service',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Documents List
          if (formData.documents.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: formData.documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _DocumentItemCard(
                  document: formData.documents[index],
                  index: index,
                  onEdit: () => _showEditDocumentDialog(context, index),
                  onDelete: () => formData.removeDocument(index),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Add Document Button
          OutlinedButton.icon(
            onPressed: () => _showAddDocumentDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Document'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryCobalt,
              side: const BorderSide(color: AppTheme.primaryCobalt),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDocumentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _DocumentDialog(
        onSave: (name, imageUrl) {
          formData.addDocument(
            DocumentItem(name: name, sampleImageUrl: imageUrl),
          );
        },
      ),
    );
  }

  void _showEditDocumentDialog(BuildContext context, int index) {
    final doc = formData.documents[index];
    showDialog(
      context: context,
      builder: (ctx) => _DocumentDialog(
        initialName: doc.name,
        initialImageUrl: doc.sampleImageUrl,
        isEditing: true,
        onSave: (name, imageUrl) {
          formData.updateDocument(
            index,
            DocumentItem(name: name, sampleImageUrl: imageUrl),
          );
        },
      ),
    );
  }
}

/// Document Item Card
class _DocumentItemCard extends StatelessWidget {
  final DocumentItem document;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DocumentItemCard({
    required this.document,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Document Icon or Image Preview
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryCobalt.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: document.sampleImageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    child: Image.network(
                      document.sampleImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.description,
                        color: AppTheme.primaryCobalt,
                      ),
                    ),
                  )
                : const Icon(Icons.description, color: AppTheme.primaryCobalt),
          ),
          const SizedBox(width: 16),

          // Document Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (document.sampleImageUrl.isNotEmpty)
                  const Text(
                    'Sample image attached',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
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

/// Document Add/Edit Dialog with File Picker
class _DocumentDialog extends StatefulWidget {
  final String? initialName;
  final String? initialImageUrl;
  final bool isEditing;
  final Function(String name, String imageUrl) onSave;

  const _DocumentDialog({
    this.initialName,
    this.initialImageUrl,
    this.isEditing = false,
    required this.onSave,
  });

  @override
  State<_DocumentDialog> createState() => _DocumentDialogState();
}

class _DocumentDialogState extends State<_DocumentDialog> {
  late final TextEditingController _nameController;
  String? _selectedImageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  final bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedImageUrl = widget.initialImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _selectedImageBytes = file.bytes;
            _selectedFileName = file.name;
            _selectedImageUrl = _bytesToDataUrl(file.bytes!, file.extension);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  String _bytesToDataUrl(Uint8List bytes, String? extension) {
    final mimeType = _getMimeType(extension);
    return Uri.dataFromBytes(bytes, mimeType: mimeType).toString();
  }

  String _getMimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageUrl = null;
      _selectedImageBytes = null;
      _selectedFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Document' : 'Add Document'),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Name Input
            TextFormField(
              controller: _nameController,
              decoration: queueConfigInputDecoration(
                label: 'Document Name',
                hint: 'e.g., Citizenship Certificate',
              ),
            ),
            const SizedBox(height: 20),

            // Sample Image Section
            const Text(
              'Sample Image (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Image Preview or Picker
            if (_selectedImageUrl != null && _selectedImageUrl!.isNotEmpty)
              _buildImagePreview()
            else
              _buildImagePicker(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading
              ? null
              : () {
                  if (_nameController.text.trim().isNotEmpty) {
                    widget.onSave(
                      _nameController.text.trim(),
                      _selectedImageUrl ?? '',
                    );
                    Navigator.of(context).pop();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryCobalt,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: _selectedImageBytes != null
                ? Image.memory(
                    _selectedImageBytes!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    _selectedImageUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 40,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _buildImageActionButton(
                  icon: Icons.refresh,
                  onPressed: _pickImage,
                  tooltip: 'Change Image',
                ),
                const SizedBox(width: 8),
                _buildImageActionButton(
                  icon: Icons.delete,
                  onPressed: _removeImage,
                  tooltip: 'Remove Image',
                  isDestructive: true,
                ),
              ],
            ),
          ),
          if (_selectedFileName != null)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _selectedFileName!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: Colors.grey[500],
            ),
            const SizedBox(height: 8),
            Text(
              'Click to upload sample image',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'PNG, JPG, GIF up to 5MB',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isDestructive = false,
  }) {
    return Material(
      color: isDestructive ? AppTheme.error.withOpacity(0.9) : Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
