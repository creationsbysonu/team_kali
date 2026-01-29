import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sewa_sathi/features/community/data/models/hive_post_model.dart';
import 'package:sewa_sathi/features/community/domain/entities/community_entities.dart';

/// Local data source for community posts using Hive.
/// All posts are stored locally on device - no backend required.
abstract class CommunityLocalDataSource {
  /// Initialize Hive boxes (call once at app startup)
  Future<void> init();

  // Issues
  Future<List<HivePostModel>> getIssues();
  Future<HivePostModel> createIssue({
    required String caption,
    String? imagePath,
    ContentStatus contentStatus,
  });
  Future<HivePostModel> upvoteIssue(int issueId);
  Future<HivePostModel> downvoteIssue(int issueId);

  // Ideas
  Future<List<HivePostModel>> getIdeas();
  Future<HivePostModel> createIdea({
    required String caption,
    String? imagePath,
    ContentStatus contentStatus,
  });
  Future<HivePostModel> upvoteIdea(int ideaId);
  Future<HivePostModel> downvoteIdea(int ideaId);

  /// Save image to local storage and return path
  Future<String> saveImageLocally(File image);
}

/// Implementation using Hive for local storage.
class CommunityLocalDataSourceImpl implements CommunityLocalDataSource {
  static const String _issuesBoxName = 'issues_box';
  static const String _ideasBoxName = 'ideas_box';
  static const String _counterBoxName = 'counter_box';

  Box<HivePostModel>? _issuesBox;
  Box<HivePostModel>? _ideasBox;
  Box<int>? _counterBox;

  @override
  Future<void> init() async {
    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HivePostModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HiveContentStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HivePostTypeAdapter());
    }

    // Open boxes
    _issuesBox = await Hive.openBox<HivePostModel>(_issuesBoxName);
    _ideasBox = await Hive.openBox<HivePostModel>(_ideasBoxName);
    _counterBox = await Hive.openBox<int>(_counterBoxName);

    debugPrint('✅ Hive boxes initialized for community feature');
  }

  /// Get next ID for issues or ideas
  int _getNextId(String key) {
    final currentId = _counterBox?.get(key) ?? 0;
    final nextId = currentId + 1;
    _counterBox?.put(key, nextId);
    return nextId;
  }

  // ============ Issues ============

  @override
  Future<List<HivePostModel>> getIssues() async {
    final issues = _issuesBox?.values.toList() ?? [];
    // Sort by createdAt descending (newest first)
    issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return issues;
  }

  @override
  Future<HivePostModel> createIssue({
    required String caption,
    String? imagePath,
    ContentStatus contentStatus = ContentStatus.normal,
  }) async {
    final id = _getNextId('issue_counter');

    final issue = HivePostModel.create(
      id: id,
      caption: caption,
      imagePath: imagePath,
      contentStatus: contentStatus,
      postType: PostType.issue,
    );

    await _issuesBox?.put(id, issue);
    debugPrint('✅ Created issue #$id locally');
    return issue;
  }

  @override
  Future<HivePostModel> upvoteIssue(int issueId) async {
    final issue = _issuesBox?.get(issueId);
    if (issue == null) {
      throw Exception('Issue not found: $issueId');
    }

    issue.upvotes++;
    await issue.save();
    debugPrint('👍 Upvoted issue #$issueId (now ${issue.upvotes})');
    return issue;
  }

  @override
  Future<HivePostModel> downvoteIssue(int issueId) async {
    final issue = _issuesBox?.get(issueId);
    if (issue == null) {
      throw Exception('Issue not found: $issueId');
    }

    issue.downvotes++;
    await issue.save();
    debugPrint('👎 Downvoted issue #$issueId (now ${issue.downvotes})');
    return issue;
  }

  // ============ Ideas ============

  @override
  Future<List<HivePostModel>> getIdeas() async {
    final ideas = _ideasBox?.values.toList() ?? [];
    // Sort by createdAt descending (newest first)
    ideas.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ideas;
  }

  @override
  Future<HivePostModel> createIdea({
    required String caption,
    String? imagePath,
    ContentStatus contentStatus = ContentStatus.normal,
  }) async {
    final id = _getNextId('idea_counter');

    final idea = HivePostModel.create(
      id: id,
      caption: caption,
      imagePath: imagePath,
      contentStatus: contentStatus,
      postType: PostType.idea,
    );

    await _ideasBox?.put(id, idea);
    debugPrint('✅ Created idea #$id locally');
    return idea;
  }

  @override
  Future<HivePostModel> upvoteIdea(int ideaId) async {
    final idea = _ideasBox?.get(ideaId);
    if (idea == null) {
      throw Exception('Idea not found: $ideaId');
    }

    idea.upvotes++;
    await idea.save();
    debugPrint('👍 Upvoted idea #$ideaId (now ${idea.upvotes})');
    return idea;
  }

  @override
  Future<HivePostModel> downvoteIdea(int ideaId) async {
    final idea = _ideasBox?.get(ideaId);
    if (idea == null) {
      throw Exception('Idea not found: $ideaId');
    }

    idea.downvotes++;
    await idea.save();
    debugPrint('👎 Downvoted idea #$ideaId (now ${idea.downvotes})');
    return idea;
  }

  // ============ Image Storage ============

  @override
  Future<String> saveImageLocally(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/community_images');

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final fileName =
        'img_${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
    final savedPath = '${imagesDir.path}/$fileName';

    await image.copy(savedPath);
    debugPrint('📸 Saved image to: $savedPath');

    return savedPath;
  }
}
