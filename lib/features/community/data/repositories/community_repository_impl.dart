import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/features/community/data/data_sources/community_local_data_source.dart';
import 'package:sewa_sathi/features/community/domain/entities/community_entities.dart';
import 'package:sewa_sathi/features/community/domain/repositories/community_repository.dart';

/// Implementation of CommunityRepository using local Hive storage.
///
/// Hackathon MVP:
/// - All posts stored locally on device (Hive)
/// - No backend API for CRUD operations
/// - Only AI moderation server (port 8003) is used for image classification
class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityLocalDataSource localDataSource;

  CommunityRepositoryImpl({required this.localDataSource});

  // ============ Issues ============

  @override
  Future<Either<Failure, List<PostEntity>>> getIssues({
    int? limit,
    int? offset,
  }) async {
    try {
      final issues = await localDataSource.getIssues();

      // Apply pagination if needed
      List<PostEntity> result = issues.map((e) => e.toEntity()).toList();

      if (offset != null && offset > 0) {
        result = result.skip(offset).toList();
      }
      if (limit != null && limit > 0) {
        result = result.take(limit).toList();
      }

      debugPrint('📋 Loaded ${result.length} issues from local storage');
      return Right(result);
    } catch (e) {
      debugPrint('❌ Failed to get issues: $e');
      return Left(CacheFailure(message: 'Failed to load issues: $e'));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> createIssue({
    File? image,
    required String caption,
    ContentStatus? contentStatus,
  }) async {
    try {
      String? imagePath;

      // Save image locally if provided
      if (image != null) {
        imagePath = await localDataSource.saveImageLocally(image);
      }

      final issue = await localDataSource.createIssue(
        caption: caption,
        imagePath: imagePath,
        contentStatus: contentStatus ?? ContentStatus.normal,
      );

      return Right(issue.toEntity());
    } catch (e) {
      debugPrint('❌ Failed to create issue: $e');
      return Left(CacheFailure(message: 'Failed to create issue: $e'));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> upvoteIssue(int issueId) async {
    try {
      final issue = await localDataSource.upvoteIssue(issueId);
      return Right(issue.toEntity());
    } catch (e) {
      debugPrint('❌ Failed to upvote issue: $e');
      return Left(CacheFailure(message: 'Failed to upvote: $e'));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> downvoteIssue(int issueId) async {
    try {
      final issue = await localDataSource.downvoteIssue(issueId);
      return Right(issue.toEntity());
    } catch (e) {
      debugPrint('❌ Failed to downvote issue: $e');
      return Left(CacheFailure(message: 'Failed to downvote: $e'));
    }
  }

  // ============ Ideas ============

  @override
  Future<Either<Failure, List<PostEntity>>> getIdeas({
    int? limit,
    int? offset,
  }) async {
    try {
      final ideas = await localDataSource.getIdeas();

      // Apply pagination if needed
      List<PostEntity> result = ideas.map((e) => e.toEntity()).toList();

      if (offset != null && offset > 0) {
        result = result.skip(offset).toList();
      }
      if (limit != null && limit > 0) {
        result = result.take(limit).toList();
      }

      debugPrint('💡 Loaded ${result.length} ideas from local storage');
      return Right(result);
    } catch (e) {
      debugPrint('❌ Failed to get ideas: $e');
      return Left(CacheFailure(message: 'Failed to load ideas: $e'));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> createIdea({
    File? image,
    required String caption,
    ContentStatus? contentStatus,
  }) async {
    try {
      String? imagePath;

      // Save image locally if provided
      if (image != null) {
        imagePath = await localDataSource.saveImageLocally(image);
      }

      final idea = await localDataSource.createIdea(
        caption: caption,
        imagePath: imagePath,
        contentStatus: contentStatus ?? ContentStatus.normal,
      );

      return Right(idea.toEntity());
    } catch (e) {
      debugPrint('❌ Failed to create idea: $e');
      return Left(CacheFailure(message: 'Failed to create idea: $e'));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> upvoteIdea(int ideaId) async {
    try {
      final idea = await localDataSource.upvoteIdea(ideaId);
      return Right(idea.toEntity());
    } catch (e) {
      debugPrint('❌ Failed to upvote idea: $e');
      return Left(CacheFailure(message: 'Failed to upvote: $e'));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> downvoteIdea(int ideaId) async {
    try {
      final idea = await localDataSource.downvoteIdea(ideaId);
      return Right(idea.toEntity());
    } catch (e) {
      debugPrint('❌ Failed to downvote idea: $e');
      return Left(CacheFailure(message: 'Failed to downvote: $e'));
    }
  }
}
