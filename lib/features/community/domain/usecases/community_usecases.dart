import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/community/domain/entities/community_entities.dart';
import 'package:sewa_sathi/features/community/domain/repositories/community_repository.dart';

// ============ Get Issues UseCase ============

class GetIssuesParams {
  final int? limit;
  final int? offset;

  const GetIssuesParams({this.limit, this.offset});
}

class GetIssuesUseCase implements UseCase<List<PostEntity>, GetIssuesParams> {
  final CommunityRepository repository;

  GetIssuesUseCase(this.repository);

  @override
  Future<Either<Failure, List<PostEntity>>> call(GetIssuesParams params) {
    return repository.getIssues(limit: params.limit, offset: params.offset);
  }
}

// ============ Get Ideas UseCase ============

class GetIdeasParams {
  final int? limit;
  final int? offset;

  const GetIdeasParams({this.limit, this.offset});
}

class GetIdeasUseCase implements UseCase<List<PostEntity>, GetIdeasParams> {
  final CommunityRepository repository;

  GetIdeasUseCase(this.repository);

  @override
  Future<Either<Failure, List<PostEntity>>> call(GetIdeasParams params) {
    return repository.getIdeas(limit: params.limit, offset: params.offset);
  }
}

// ============ Create Post UseCase ============

class CreatePostParams {
  final File? image;
  final String caption;
  final PostType postType;
  final ContentStatus? contentStatus; // From AI moderation

  const CreatePostParams({
    this.image,
    required this.caption,
    required this.postType,
    this.contentStatus,
  });
}

class CreatePostUseCase implements UseCase<PostEntity, CreatePostParams> {
  final CommunityRepository repository;

  CreatePostUseCase(this.repository);

  @override
  Future<Either<Failure, PostEntity>> call(CreatePostParams params) {
    if (params.postType == PostType.issue) {
      return repository.createIssue(
        image: params.image,
        caption: params.caption,
        contentStatus: params.contentStatus,
      );
    } else {
      return repository.createIdea(
        image: params.image,
        caption: params.caption,
        contentStatus: params.contentStatus,
      );
    }
  }
}

// ============ Vote UseCase ============

enum VoteType { upvote, downvote }

class VoteParams {
  final int postId;
  final PostType postType;
  final VoteType voteType;

  const VoteParams({
    required this.postId,
    required this.postType,
    required this.voteType,
  });
}

class VotePostUseCase implements UseCase<PostEntity, VoteParams> {
  final CommunityRepository repository;

  VotePostUseCase(this.repository);

  @override
  Future<Either<Failure, PostEntity>> call(VoteParams params) {
    if (params.postType == PostType.issue) {
      if (params.voteType == VoteType.upvote) {
        return repository.upvoteIssue(params.postId);
      } else {
        return repository.downvoteIssue(params.postId);
      }
    } else {
      if (params.voteType == VoteType.upvote) {
        return repository.upvoteIdea(params.postId);
      } else {
        return repository.downvoteIdea(params.postId);
      }
    }
  }
}
