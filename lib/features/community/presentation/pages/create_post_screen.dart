import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sewa_sathi/core/di/injection_container.dart' as di;
import 'package:sewa_sathi/features/community/domain/entities/community_entities.dart';
import 'package:sewa_sathi/features/community/presentation/bloc/create_post_bloc.dart';

/// Screen for creating new Issues or Ideas.
/// Simple MVP flow: Select Image (optional) → Write Caption → Submit
/// AI moderation happens automatically on submit.
class CreatePostScreen extends StatefulWidget {
  final PostType initialPostType;

  const CreatePostScreen({super.key, this.initialPostType = PostType.issue});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _imagePicker = ImagePicker();
  late PostType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialPostType;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<CreatePostBloc>(),
      child: BlocConsumer<CreatePostBloc, CreatePostState>(
        listener: (context, state) {
          if (state is CreatePostSuccess) {
            _showSuccessMessage(context, state.post);
            Navigator.pop(context, state.post);
          }

          if (state is CreatePostError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is CreatePostSubmitting;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(context, isSubmitting),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post type selector
                  _buildTypeSelector(context),
                  const SizedBox(height: 24),

                  // Caption input (required)
                  _buildCaptionInput(),
                  const SizedBox(height: 24),

                  // Image picker (optional)
                  _buildImageSection(context, state),
                  const SizedBox(height: 24),

                  // Info notice about AI moderation
                  _buildInfoNotice(),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomBar(context, state),
          );
        },
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, PostEntity post) {
    String message;
    Color bgColor;

    if (post.isBlocked) {
      message = 'Post submitted. Content flagged as 18+ and hidden from feed.';
      bgColor = Colors.red;
    } else if (post.isSensitive) {
      message = 'Post submitted. Content will appear blurred in feed.';
      bgColor = Colors.orange;
    } else {
      message = post.postType == PostType.issue
          ? 'Issue reported successfully!'
          : 'Idea shared successfully!';
      bgColor = Colors.green;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: bgColor));
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isSubmitting) {
    return AppBar(
      backgroundColor: const Color(0xFF0047AB),
      foregroundColor: Colors.white,
      title: const Text(
        'Create Post',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: isSubmitting ? null : () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Post Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TypeOption(
                title: 'Issue',
                subtitle: 'Report a problem',
                icon: Icons.report_problem_outlined,
                isSelected: _selectedType == PostType.issue,
                onTap: () {
                  setState(() => _selectedType = PostType.issue);
                  context.read<CreatePostBloc>().add(
                    const UpdatePostTypeEvent(postType: PostType.issue),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TypeOption(
                title: 'Idea',
                subtitle: 'Share a suggestion',
                icon: Icons.lightbulb_outline,
                isSelected: _selectedType == PostType.idea,
                onTap: () {
                  setState(() => _selectedType = PostType.idea);
                  context.read<CreatePostBloc>().add(
                    const UpdatePostTypeEvent(postType: PostType.idea),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCaptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text(
                  'Caption',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(width: 4),
                Text('*', style: TextStyle(fontSize: 16, color: Colors.red)),
              ],
            ),
            Text(
              '${_captionController.text.length}/300',
              style: TextStyle(
                fontSize: 12,
                color: _captionController.text.length > 300
                    ? Colors.red
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _captionController,
          maxLength: 300,
          maxLines: 4,
          onChanged: (value) {
            setState(() {});
            context.read<CreatePostBloc>().add(
              UpdateCaptionEvent(caption: value),
            );
          },
          decoration: InputDecoration(
            hintText: _selectedType == PostType.issue
                ? 'Describe the issue you want to report...'
                : 'Share your idea for the community...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0047AB), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(BuildContext context, CreatePostState state) {
    File? selectedImage;
    bool isSubmitting = state is CreatePostSubmitting;

    if (state is CreatePostEditing) {
      selectedImage = state.selectedImage;
    } else if (state is CreatePostError) {
      selectedImage = state.previousImage;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(optional)',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: isSubmitting ? null : () => _showImageSourceDialog(context),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: selectedImage != null
                  ? Border.all(color: Colors.grey.shade300, width: 1.5)
                  : null,
            ),
            child: selectedImage != null
                ? _buildSelectedImage(context, selectedImage, isSubmitting)
                : _buildImagePlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedImage(
    BuildContext context,
    File image,
    bool isSubmitting,
  ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            image,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        if (!isSubmitting)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                context.read<CreatePostBloc>().add(RemoveImageEvent());
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0047AB).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            size: 32,
            color: Color(0xFF0047AB),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tap to add a photo',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF0047AB),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'JPG, PNG up to 10MB',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildInfoNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Images are automatically checked by AI to keep our community safe.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CreatePostState state) {
    final isSubmitting = state is CreatePostSubmitting;
    final submittingMessage = isSubmitting ? (state).message : '';

    final hasCaption = _captionController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isSubmitting || !hasCaption
              ? null
              : () => _submitPost(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0047AB),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade500,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      submittingMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Text(
                  _selectedType == PostType.issue
                      ? 'Submit Issue'
                      : 'Share Idea',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Select Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _ImageSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _pickImage(context, ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ImageSourceOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _pickImage(context, ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (mounted) {
          context.read<CreatePostBloc>().add(SelectImageEvent(image: file));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _submitPost(BuildContext context) {
    context.read<CreatePostBloc>().add(SubmitPostEvent());
  }
}

/// Type option card widget.
class _TypeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0047AB).withValues(alpha: 0.1)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0047AB) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected
                  ? const Color(0xFF0047AB)
                  : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF0047AB)
                    : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Image source option widget.
class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF0047AB)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
