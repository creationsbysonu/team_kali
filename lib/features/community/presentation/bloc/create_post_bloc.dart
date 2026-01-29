import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/features/community/data/services/moderation_service.dart';
import 'package:sewa_sathi/features/community/domain/entities/community_entities.dart';
import 'package:sewa_sathi/features/community/domain/usecases/community_usecases.dart';

part 'create_post_event.dart';
part 'create_post_state.dart';

/// BLoC for creating new posts with automatic AI moderation.
///
/// Simplified MVP Flow:
/// 1. User selects image (optional) + writes caption
/// 2. User clicks Submit
/// 3. If image present → Auto-moderate via AI → Get classification
/// 4. Create post with content_status
/// 5. Post displays in feed: NORMAL/WARNING/BLOCKED
class CreatePostBloc extends Bloc<CreatePostEvent, CreatePostState> {
  final CreatePostUseCase createPost;
  final ModerationService moderationService;

  CreatePostBloc({required this.createPost, required this.moderationService})
    : super(CreatePostInitial()) {
    on<SelectImageEvent>(_onSelectImage);
    on<RemoveImageEvent>(_onRemoveImage);
    on<UpdateCaptionEvent>(_onUpdateCaption);
    on<UpdatePostTypeEvent>(_onUpdatePostType);
    on<SubmitPostEvent>(_onSubmitPost);
    on<ResetCreatePostEvent>(_onReset);
  }

  File? _selectedImage;
  String _caption = '';
  PostType _postType = PostType.issue;

  void _onSelectImage(SelectImageEvent event, Emitter<CreatePostState> emit) {
    _selectedImage = event.image;
    emit(_buildEditingState());
  }

  void _onRemoveImage(RemoveImageEvent event, Emitter<CreatePostState> emit) {
    _selectedImage = null;
    emit(_buildEditingState());
  }

  void _onUpdateCaption(
    UpdateCaptionEvent event,
    Emitter<CreatePostState> emit,
  ) {
    _caption = event.caption;
    emit(_buildEditingState());
  }

  void _onUpdatePostType(
    UpdatePostTypeEvent event,
    Emitter<CreatePostState> emit,
  ) {
    _postType = event.postType;
    emit(_buildEditingState());
  }

  /// Submit post with automatic AI moderation.
  /// If image is present, moderate it first, then submit.
  Future<void> _onSubmitPost(
    SubmitPostEvent event,
    Emitter<CreatePostState> emit,
  ) async {
    // Validate caption
    if (_caption.isEmpty) {
      emit(
        CreatePostError(
          message: 'Please add a caption',
          previousImage: _selectedImage,
          previousCaption: _caption,
          previousPostType: _postType,
        ),
      );
      return;
    }

    ContentStatus? contentStatus;

    // If image present, auto-moderate it
    if (_selectedImage != null) {
      emit(const CreatePostSubmitting(message: 'Analyzing image...'));

      try {
        debugPrint('🔍 Auto-moderating image...');
        final result = await moderationService.moderateImage(_selectedImage!);
        contentStatus = result.status;
        debugPrint(
          '✅ Moderation result: ${result.status} (${(result.confidence * 100).toStringAsFixed(0)}%)',
        );
      } catch (e) {
        debugPrint('❌ Moderation failed: $e');
        emit(
          CreatePostError(
            message: 'Failed to analyze image. Please try again.',
            previousImage: _selectedImage,
            previousCaption: _caption,
            previousPostType: _postType,
          ),
        );
        return;
      }
    }

    // Submit post
    emit(const CreatePostSubmitting(message: 'Posting...'));

    final result = await createPost(
      CreatePostParams(
        image: _selectedImage,
        caption: _caption,
        postType: _postType,
        contentStatus: contentStatus,
      ),
    );

    result.fold(
      (failure) => emit(
        CreatePostError(
          message: failure.message,
          previousImage: _selectedImage,
          previousCaption: _caption,
          previousPostType: _postType,
        ),
      ),
      (post) {
        debugPrint(
          '✅ Post created: ${post.id} (status: ${post.contentStatus})',
        );
        emit(CreatePostSuccess(post: post));
        // Reset state
        _selectedImage = null;
        _caption = '';
        _postType = PostType.issue;
      },
    );
  }

  void _onReset(ResetCreatePostEvent event, Emitter<CreatePostState> emit) {
    _selectedImage = null;
    _caption = '';
    _postType = PostType.issue;
    emit(CreatePostInitial());
  }

  CreatePostEditing _buildEditingState() {
    return CreatePostEditing(
      selectedImage: _selectedImage,
      caption: _caption,
      postType: _postType,
    );
  }
}
