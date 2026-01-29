part of 'feed_bloc.dart';

/// Events for FeedBloc - Simplified for hackathon MVP.
abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

/// Load issues feed.
class LoadIssuesEvent extends FeedEvent {}

/// Load ideas feed.
class LoadIdeasEvent extends FeedEvent {}

/// Refresh feed.
class RefreshFeedEvent extends FeedEvent {
  final PostType currentTab;

  const RefreshFeedEvent({required this.currentTab});

  @override
  List<Object?> get props => [currentTab];
}

/// Vote on a post (upvote/downvote).
class VotePostEvent extends FeedEvent {
  final int postId;
  final PostType postType;
  final VoteType voteType;

  const VotePostEvent({
    required this.postId,
    required this.postType,
    required this.voteType,
  });

  @override
  List<Object?> get props => [postId, postType, voteType];
}

/// Add a new post (optimistic update after creation).
class AddNewPostEvent extends FeedEvent {
  final PostEntity post;

  const AddNewPostEvent({required this.post});

  @override
  List<Object?> get props => [post];
}
