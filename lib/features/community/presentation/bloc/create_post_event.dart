part of 'create_post_bloc.dart';

/// Events for CreatePostBloc - simplified MVP flow.
abstract class CreatePostEvent extends Equatable {
  const CreatePostEvent();

  @override
  List<Object?> get props => [];
}

/// Image selected from gallery/camera.
class SelectImageEvent extends CreatePostEvent {
  final File image;

  const SelectImageEvent({required this.image});

  @override
  List<Object?> get props => [image];
}

/// Remove selected image.
class RemoveImageEvent extends CreatePostEvent {}

/// Caption text updated.
class UpdateCaptionEvent extends CreatePostEvent {
  final String caption;

  const UpdateCaptionEvent({required this.caption});

  @override
  List<Object?> get props => [caption];
}

/// Post type changed (Issue/Idea).
class UpdatePostTypeEvent extends CreatePostEvent {
  final PostType postType;

  const UpdatePostTypeEvent({required this.postType});

  @override
  List<Object?> get props => [postType];
}

/// Submit post - auto-moderates image if present, then submits.
class SubmitPostEvent extends CreatePostEvent {}

/// Reset create post state.
class ResetCreatePostEvent extends CreatePostEvent {}
