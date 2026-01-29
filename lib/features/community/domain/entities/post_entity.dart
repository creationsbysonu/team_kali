import 'package:equatable/equatable.dart';

/// Content status from AI moderation.
/// - normal: Safe to display
/// - warning: Sensitive content, show blurred with reveal option
/// - blocked: 18+ content, cannot be displayed
enum ContentStatus { normal, warning, blocked }

/// Post type enum to distinguish between issues and ideas.
enum PostType { issue, idea }

/// Simple post entity for hackathon MVP.
class PostEntity extends Equatable {
  final int id;
  final String caption;
  final String? imageUrl;
  final ContentStatus contentStatus;
  final int upvotes;
  final int downvotes;
  final DateTime createdAt;
  final PostType postType;

  const PostEntity({
    required this.id,
    required this.caption,
    this.imageUrl,
    this.contentStatus = ContentStatus.normal,
    this.upvotes = 0,
    this.downvotes = 0,
    required this.createdAt,
    required this.postType,
  });

  @override
  List<Object?> get props => [
    id,
    caption,
    imageUrl,
    contentStatus,
    upvotes,
    downvotes,
    createdAt,
    postType,
  ];

  /// Check if content is blocked (18+).
  bool get isBlocked => contentStatus == ContentStatus.blocked;

  /// Check if content is sensitive and should be blurred.
  bool get isSensitive => contentStatus == ContentStatus.warning;

  /// Check if content is safe to display.
  bool get isNormal => contentStatus == ContentStatus.normal;

  /// Check if post has image.
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Net votes (upvotes - downvotes).
  int get netVotes => upvotes - downvotes;

  /// Copy with method for optimistic updates.
  PostEntity copyWith({
    int? id,
    String? caption,
    String? imageUrl,
    ContentStatus? contentStatus,
    int? upvotes,
    int? downvotes,
    DateTime? createdAt,
    PostType? postType,
  }) {
    return PostEntity(
      id: id ?? this.id,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      contentStatus: contentStatus ?? this.contentStatus,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      createdAt: createdAt ?? this.createdAt,
      postType: postType ?? this.postType,
    );
  }
}
