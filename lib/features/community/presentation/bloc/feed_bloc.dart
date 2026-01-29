import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/features/community/domain/entities/community_entities.dart';
import 'package:sewa_sathi/features/community/domain/usecases/community_usecases.dart';

part 'feed_event.dart';
part 'feed_state.dart';

/// BLoC for managing community feed (Issues & Ideas).
/// Simplified for hackathon MVP - no comments, no auth.
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final GetIssuesUseCase getIssues;
  final GetIdeasUseCase getIdeas;
  final VotePostUseCase votePost;

  List<PostEntity> _issues = [];
  List<PostEntity> _ideas = [];

  FeedBloc({
    required this.getIssues,
    required this.getIdeas,
    required this.votePost,
  }) : super(FeedInitial()) {
    on<LoadIssuesEvent>(_onLoadIssues);
    on<LoadIdeasEvent>(_onLoadIdeas);
    on<RefreshFeedEvent>(_onRefreshFeed);
    on<VotePostEvent>(_onVotePost);
    on<AddNewPostEvent>(_onAddNewPost);
  }

  Future<void> _onLoadIssues(
    LoadIssuesEvent event,
    Emitter<FeedState> emit,
  ) async {
    emit(const FeedLoading(currentTab: PostType.issue));

    final result = await getIssues(const GetIssuesParams(limit: 20));

    result.fold((failure) => emit(FeedError(message: failure.message)), (
      issues,
    ) {
      _issues = issues;
      emit(_buildLoadedState(PostType.issue));
    });
  }

  Future<void> _onLoadIdeas(
    LoadIdeasEvent event,
    Emitter<FeedState> emit,
  ) async {
    emit(const FeedLoading(currentTab: PostType.idea));

    final result = await getIdeas(const GetIdeasParams(limit: 20));

    result.fold((failure) => emit(FeedError(message: failure.message)), (
      ideas,
    ) {
      _ideas = ideas;
      emit(_buildLoadedState(PostType.idea));
    });
  }

  Future<void> _onRefreshFeed(
    RefreshFeedEvent event,
    Emitter<FeedState> emit,
  ) async {
    final issuesResult = await getIssues(const GetIssuesParams(limit: 20));
    final ideasResult = await getIdeas(const GetIdeasParams(limit: 20));

    issuesResult.fold((failure) => null, (issues) => _issues = issues);

    ideasResult.fold((failure) => null, (ideas) => _ideas = ideas);

    emit(_buildLoadedState(event.currentTab));
  }

  Future<void> _onVotePost(VotePostEvent event, Emitter<FeedState> emit) async {
    final list = event.postType == PostType.issue ? _issues : _ideas;
    final index = list.indexWhere((p) => p.id == event.postId);
    if (index == -1) return;

    // Optimistic update
    _updateVoteOptimistically(event.postId, event.postType, event.voteType);

    if (state is FeedLoaded) {
      emit(_buildLoadedState((state as FeedLoaded).currentTab));
    }

    // Make API call
    final result = await votePost(
      VoteParams(
        postId: event.postId,
        postType: event.postType,
        voteType: event.voteType,
      ),
    );

    result.fold(
      (failure) {
        // Revert on failure (reload would be better)
        if (state is FeedLoaded) {
          emit(_buildLoadedState((state as FeedLoaded).currentTab));
        }
      },
      (updatedPost) {
        // Update with actual server response
        _updatePostInList(updatedPost);
        if (state is FeedLoaded) {
          emit(_buildLoadedState((state as FeedLoaded).currentTab));
        }
      },
    );
  }

  void _onAddNewPost(AddNewPostEvent event, Emitter<FeedState> emit) {
    // Add new post to the beginning of the list
    if (event.post.postType == PostType.issue) {
      _issues = [event.post, ..._issues];
    } else {
      _ideas = [event.post, ..._ideas];
    }

    if (state is FeedLoaded) {
      emit(_buildLoadedState((state as FeedLoaded).currentTab));
    }
  }

  void _updateVoteOptimistically(
    int postId,
    PostType postType,
    VoteType voteType,
  ) {
    final list = postType == PostType.issue ? _issues : _ideas;
    final index = list.indexWhere((p) => p.id == postId);

    if (index != -1) {
      final post = list[index];
      int newUpvotes = post.upvotes;
      int newDownvotes = post.downvotes;

      // Simple increment/decrement
      if (voteType == VoteType.upvote) {
        newUpvotes++;
      } else {
        newDownvotes++;
      }

      final updatedPost = post.copyWith(
        upvotes: newUpvotes,
        downvotes: newDownvotes,
      );

      if (postType == PostType.issue) {
        _issues = List.from(_issues)..[index] = updatedPost;
      } else {
        _ideas = List.from(_ideas)..[index] = updatedPost;
      }
    }
  }

  void _updatePostInList(PostEntity updatedPost) {
    if (updatedPost.postType == PostType.issue) {
      final index = _issues.indexWhere((p) => p.id == updatedPost.id);
      if (index != -1) {
        _issues = List.from(_issues)..[index] = updatedPost;
      }
    } else {
      final index = _ideas.indexWhere((p) => p.id == updatedPost.id);
      if (index != -1) {
        _ideas = List.from(_ideas)..[index] = updatedPost;
      }
    }
  }

  FeedLoaded _buildLoadedState(PostType currentTab) {
    return FeedLoaded(
      issues: List.from(_issues),
      ideas: List.from(_ideas),
      currentTab: currentTab,
    );
  }
}
