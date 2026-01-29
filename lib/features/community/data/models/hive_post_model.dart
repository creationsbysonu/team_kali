import 'package:hive/hive.dart';
import 'package:sewa_sathi/features/community/domain/entities/community_entities.dart';

part 'hive_post_model.g.dart';

/// Hive type IDs for community feature
/// - 0: HivePostModel
/// - 1: HiveContentStatus
/// - 2: HivePostType

@HiveType(typeId: 1)
enum HiveContentStatus {
  @HiveField(0)
  normal,
  @HiveField(1)
  warning,
  @HiveField(2)
  blocked,
}

@HiveType(typeId: 2)
enum HivePostType {
  @HiveField(0)
  issue,
  @HiveField(1)
  idea,
}

/// Hive model for storing posts locally.
/// Supports both issues and ideas with AI moderation status.
@HiveType(typeId: 0)
class HivePostModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String caption;

  @HiveField(2)
  final String? imagePath; // Local file path

  @HiveField(3)
  final HiveContentStatus contentStatus;

  @HiveField(4)
  int upvotes;

  @HiveField(5)
  int downvotes;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final HivePostType postType;

  HivePostModel({
    required this.id,
    required this.caption,
    this.imagePath,
    this.contentStatus = HiveContentStatus.normal,
    this.upvotes = 0,
    this.downvotes = 0,
    required this.createdAt,
    required this.postType,
  });

  /// Convert to domain entity.
  PostEntity toEntity() {
    return PostEntity(
      id: id,
      caption: caption,
      imageUrl: imagePath, // Local file path used as URL
      contentStatus: _toContentStatus(contentStatus),
      upvotes: upvotes,
      downvotes: downvotes,
      createdAt: createdAt,
      postType: _toPostType(postType),
    );
  }

  /// Create from domain entity.
  factory HivePostModel.fromEntity(PostEntity entity) {
    return HivePostModel(
      id: entity.id,
      caption: entity.caption,
      imagePath: entity.imageUrl,
      contentStatus: _fromContentStatus(entity.contentStatus),
      upvotes: entity.upvotes,
      downvotes: entity.downvotes,
      createdAt: entity.createdAt,
      postType: _fromPostType(entity.postType),
    );
  }

  /// Create new post with generated ID.
  factory HivePostModel.create({
    required int id,
    required String caption,
    String? imagePath,
    ContentStatus contentStatus = ContentStatus.normal,
    required PostType postType,
  }) {
    return HivePostModel(
      id: id,
      caption: caption,
      imagePath: imagePath,
      contentStatus: _fromContentStatus(contentStatus),
      upvotes: 0,
      downvotes: 0,
      createdAt: DateTime.now(),
      postType: _fromPostType(postType),
    );
  }

  // Conversion helpers
  static ContentStatus _toContentStatus(HiveContentStatus status) {
    switch (status) {
      case HiveContentStatus.warning:
        return ContentStatus.warning;
      case HiveContentStatus.blocked:
        return ContentStatus.blocked;
      case HiveContentStatus.normal:
        return ContentStatus.normal;
    }
  }

  static HiveContentStatus _fromContentStatus(ContentStatus status) {
    switch (status) {
      case ContentStatus.warning:
        return HiveContentStatus.warning;
      case ContentStatus.blocked:
        return HiveContentStatus.blocked;
      case ContentStatus.normal:
        return HiveContentStatus.normal;
    }
  }

  static PostType _toPostType(HivePostType type) {
    switch (type) {
      case HivePostType.idea:
        return PostType.idea;
      case HivePostType.issue:
        return PostType.issue;
    }
  }

  static HivePostType _fromPostType(PostType type) {
    switch (type) {
      case PostType.idea:
        return HivePostType.idea;
      case PostType.issue:
        return HivePostType.issue;
    }
  }
}
