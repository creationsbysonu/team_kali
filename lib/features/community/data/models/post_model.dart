import 'package:sewa_sathi/features/community/domain/entities/community_entities.dart';

/// Post model extending PostEntity with JSON serialization.
/// Simplified for hackathon MVP - no auth, no comments.
class PostModel extends PostEntity {
  const PostModel({
    required super.id,
    required super.caption,
    super.imageUrl,
    required super.contentStatus,
    required super.upvotes,
    required super.downvotes,
    required super.createdAt,
    required super.postType,
  });

  /// Factory constructor for Issue from JSON.
  factory PostModel.issueFromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['issue_id'] as int? ?? json['id'] as int? ?? 0,
      caption: json['caption'] as String? ?? json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? json['file_url'] as String?,
      contentStatus: _parseContentStatus(json['content_status']),
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      postType: PostType.issue,
    );
  }

  /// Factory constructor for Idea from JSON.
  factory PostModel.ideaFromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['idea_id'] as int? ?? json['id'] as int? ?? 0,
      caption: json['caption'] as String? ?? json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? json['file_url'] as String?,
      contentStatus: _parseContentStatus(json['content_status']),
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      postType: PostType.idea,
    );
  }

  /// Parse content status from API response.
  /// API returns: "normal", "warning", or "blocked"
  static ContentStatus _parseContentStatus(dynamic value) {
    if (value == null) return ContentStatus.normal;
    final status = value.toString().toLowerCase();
    switch (status) {
      case 'warning':
        return ContentStatus.warning;
      case 'blocked':
        return ContentStatus.blocked;
      default:
        return ContentStatus.normal;
    }
  }

  /// Convert content status to string for API.
  static String _contentStatusToString(ContentStatus status) {
    switch (status) {
      case ContentStatus.warning:
        return 'warning';
      case ContentStatus.blocked:
        return 'blocked';
      case ContentStatus.normal:
        return 'normal';
    }
  }

  /// Convert to JSON for API requests.
  Map<String, dynamic> toJson() {
    final idKey = postType == PostType.issue ? 'issue_id' : 'idea_id';
    return {
      idKey: id,
      'caption': caption,
      'image_url': imageUrl,
      'content_status': _contentStatusToString(contentStatus),
      'upvotes': upvotes,
      'downvotes': downvotes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from entity (for optimistic updates).
  factory PostModel.fromEntity(PostEntity entity) {
    return PostModel(
      id: entity.id,
      caption: entity.caption,
      imageUrl: entity.imageUrl,
      contentStatus: entity.contentStatus,
      upvotes: entity.upvotes,
      downvotes: entity.downvotes,
      createdAt: entity.createdAt,
      postType: entity.postType,
    );
  }
}
