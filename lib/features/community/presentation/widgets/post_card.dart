import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sewa_sathi/features/community/domain/entities/community_entities.dart';
import 'package:sewa_sathi/features/community/domain/usecases/community_usecases.dart';
import 'package:sewa_sathi/features/community/presentation/bloc/feed_bloc.dart';

/// Post card widget with 3 content states:
/// - normal: Display content normally
/// - warning: Blur with "See sensitive content" button
/// - blocked: Show "18+ content can't be displayed" message
class PostCard extends StatefulWidget {
  final PostEntity post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showSensitiveContent = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with post type and timestamp
          _buildHeader(),

          // Content based on status
          _buildContent(),

          // Action buttons (only if not blocked)
          if (!widget.post.isBlocked) _buildActionButtons(),
        ],
      ),
    );
  }

  /// Header with post type badge and timestamp.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Post type icon
          _buildTypeIcon(),
          const SizedBox(width: 10),

          // Post type and timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTypeBadge(),
                    if (widget.post.isSensitive || widget.post.isBlocked) ...[
                      const SizedBox(width: 8),
                      _buildWarningBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(widget.post.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Net votes indicator
          _buildNetVotes(),
        ],
      ),
    );
  }

  Widget _buildTypeIcon() {
    final isIssue = widget.post.postType == PostType.issue;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isIssue
            ? const Color(0xFF0047AB).withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isIssue ? Icons.report_problem_outlined : Icons.lightbulb_outline,
        color: isIssue ? const Color(0xFF0047AB) : Colors.green,
        size: 20,
      ),
    );
  }

  Widget _buildTypeBadge() {
    final isIssue = widget.post.postType == PostType.issue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isIssue
            ? const Color(0xFF0047AB).withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isIssue ? 'Issue' : 'Idea',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isIssue ? const Color(0xFF0047AB) : Colors.green,
        ),
      ),
    );
  }

  Widget _buildWarningBadge() {
    final isBlocked = widget.post.isBlocked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isBlocked
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBlocked ? Icons.block : Icons.warning_amber_rounded,
            size: 12,
            color: isBlocked ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isBlocked ? '18+' : 'Sensitive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isBlocked ? Colors.red : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetVotes() {
    final netVotes = widget.post.netVotes;
    final isPositive = netVotes >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: isPositive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            '${netVotes.abs()}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  /// Build content based on content status.
  Widget _buildContent() {
    // BLOCKED: Show 18+ message
    if (widget.post.isBlocked) {
      return _buildBlockedContent();
    }

    // WARNING: Show blurred with reveal option
    if (widget.post.isSensitive && !_showSensitiveContent) {
      return _buildSensitiveContent();
    }

    // NORMAL: Show content normally
    return _buildNormalContent();
  }

  /// Blocked content - 18+ can't be displayed.
  Widget _buildBlockedContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.block, size: 32, color: Colors.red),
          ),
          const SizedBox(height: 16),
          const Text(
            "18+ Content",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This content contains adult material and can't be displayed.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// Sensitive content - blurred with reveal button.
  Widget _buildSensitiveContent() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSensitiveContent = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Stack(
          children: [
            // Blurred content preview
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blurred caption
                    if (widget.post.caption.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          widget.post.caption,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1A1A2E),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Blurred image
                    if (widget.post.hasImage)
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: widget.post.imageUrl != null
                              ? _buildBlurredImage(widget.post.imageUrl!)
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Overlay with reveal button
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.visibility_off,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'See Sensitive Content',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to view',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Normal content - display normally.
  Widget _buildNormalContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Caption
        if (widget.post.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              widget.post.caption,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1A1A2E),
                height: 1.4,
              ),
            ),
          ),

        // Image
        if (widget.post.hasImage) _buildImage(),
      ],
    );
  }

  Widget _buildImage() {
    final imagePath = widget.post.imageUrl!;
    final isLocalFile = !imagePath.startsWith('http');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isLocalFile
                ? _buildLocalImage(imagePath)
                : _buildNetworkImage(imagePath),
          ),
        ),
      ),
    );
  }

  /// Build image from local file path.
  Widget _buildLocalImage(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return _buildImageError();
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildImageError(),
    );
  }

  /// Build image from network URL.
  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0047AB),
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildImageError(),
    );
  }

  /// Build error placeholder for images.
  Widget _buildImageError() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_not_supported,
        size: 48,
        color: Colors.grey.shade400,
      ),
    );
  }

  /// Build blurred image for sensitive content preview.
  Widget _buildBlurredImage(String imagePath) {
    final isLocalFile = !imagePath.startsWith('http');
    if (isLocalFile) {
      final file = File(imagePath);
      if (!file.existsSync()) return const SizedBox();
      return Image.file(file, fit: BoxFit.cover);
    }
    return Image.network(imagePath, fit: BoxFit.cover);
  }

  /// Action buttons row (upvote, downvote, share).
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Row(
        children: [
          // Upvote button
          _VoteButton(
            icon: Icons.arrow_upward_rounded,
            count: widget.post.upvotes,
            activeColor: const Color(0xFF0047AB),
            onTap: () => _onVote(VoteType.upvote),
          ),

          // Downvote button
          _VoteButton(
            icon: Icons.arrow_downward_rounded,
            count: widget.post.downvotes,
            activeColor: Colors.red,
            onTap: () => _onVote(VoteType.downvote),
          ),

          const Spacer(),

          // Share button
          IconButton(
            onPressed: () {
              // TODO: Implement share
            },
            icon: Icon(
              Icons.share_outlined,
              color: Colors.grey.shade600,
              size: 20,
            ),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  void _onVote(VoteType voteType) {
    context.read<FeedBloc>().add(
      VotePostEvent(
        postId: widget.post.id,
        postType: widget.post.postType,
        voteType: voteType,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}

/// Simple vote button widget.
class _VoteButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color activeColor;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.count,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
