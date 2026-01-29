import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/features/community/domain/entities/community_entities.dart';

/// Repository interface for community features (Issues & Ideas).
/// Simplified for hackathon MVP - no comments, no auth.
abstract class CommunityRepository {
  // Issues
  Future<Either<Failure, List<PostEntity>>> getIssues({
    int? limit,
    int? offset,
  });
  Future<Either<Failure, PostEntity>> createIssue({
    File? image,
    required String caption,
    ContentStatus? contentStatus, // From AI moderation
  });
  Future<Either<Failure, PostEntity>> upvoteIssue(int issueId);
  Future<Either<Failure, PostEntity>> downvoteIssue(int issueId);

  // Ideas
  Future<Either<Failure, List<PostEntity>>> getIdeas({int? limit, int? offset});
  Future<Either<Failure, PostEntity>> createIdea({
    File? image,
    required String caption,
    ContentStatus? contentStatus, // From AI moderation
  });
  Future<Either<Failure, PostEntity>> upvoteIdea(int ideaId);
  Future<Either<Failure, PostEntity>> downvoteIdea(int ideaId);
}
