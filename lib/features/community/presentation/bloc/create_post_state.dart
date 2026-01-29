part of 'create_post_bloc.dart';

/// States for CreatePostBloc - simplified MVP flow.
abstract class CreatePostState extends Equatable {
  const CreatePostState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class CreatePostInitial extends CreatePostState {}

/// Editing state with current form values.
class CreatePostEditing extends CreatePostState {
  final File? selectedImage;
  final String caption;
  final PostType postType;

  const CreatePostEditing({
    this.selectedImage,
    required this.caption,
    required this.postType,
  });

  @override
  List<Object?> get props => [selectedImage, caption, postType];

  /// Check if form is valid for submission.
  bool get isValid => caption.isNotEmpty;
}

/// Submitting post (includes auto-moderation if image present).
class CreatePostSubmitting extends CreatePostState {
  final String message;

  const CreatePostSubmitting({this.message = 'Submitting...'});

  @override
  List<Object?> get props => [message];
}

/// Success state with created post.
class CreatePostSuccess extends CreatePostState {
  final PostEntity post;

  const CreatePostSuccess({required this.post});

  @override
  List<Object?> get props => [post];
}

/// Error state.
class CreatePostError extends CreatePostState {
  final String message;
  final File? previousImage;
  final String previousCaption;
  final PostType previousPostType;

  const CreatePostError({
    required this.message,
    this.previousImage,
    this.previousCaption = '',
    this.previousPostType = PostType.issue,
  });

  @override
  List<Object?> get props => [
    message,
    previousImage,
    previousCaption,
    previousPostType,
  ];
}
