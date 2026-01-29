part of 'feed_bloc.dart';

/// States for FeedBloc - Simplified for hackathon MVP.
abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class FeedInitial extends FeedState {}

/// Loading state.
class FeedLoading extends FeedState {
  final PostType currentTab;

  const FeedLoading({required this.currentTab});

  @override
  List<Object?> get props => [currentTab];
}

/// Loaded state with both issues and ideas.
class FeedLoaded extends FeedState {
  final List<PostEntity> issues;
  final List<PostEntity> ideas;
  final PostType currentTab;

  const FeedLoaded({
    required this.issues,
    required this.ideas,
    required this.currentTab,
  });

  @override
  List<Object?> get props => [issues, ideas, currentTab];

  /// Get posts for current tab.
  List<PostEntity> get currentPosts =>
      currentTab == PostType.issue ? issues : ideas;

  /// Copy with method for state updates.
  FeedLoaded copyWith({
    List<PostEntity>? issues,
    List<PostEntity>? ideas,
    PostType? currentTab,
  }) {
    return FeedLoaded(
      issues: issues ?? this.issues,
      ideas: ideas ?? this.ideas,
      currentTab: currentTab ?? this.currentTab,
    );
  }
}

/// Error state.
class FeedError extends FeedState {
  final String message;

  const FeedError({required this.message});

  @override
  List<Object?> get props => [message];
}
