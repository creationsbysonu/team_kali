import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/features/community/domain/entities/community_entities.dart';
import 'package:sewa_sathi/features/community/presentation/bloc/feed_bloc.dart';
import 'package:sewa_sathi/features/community/presentation/pages/create_post_screen.dart';
import 'package:sewa_sathi/features/community/presentation/widgets/post_card.dart';

/// Issues screen - displays community reported issues.
class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  @override
  void initState() {
    super.initState();
    // Load issues on screen init
    context.read<FeedBloc>().add(LoadIssuesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: BlocBuilder<FeedBloc, FeedState>(
        builder: (context, state) {
          if (state is FeedLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0047AB)),
            );
          }

          if (state is FeedError) {
            return _buildErrorView(state.message);
          }

          if (state is FeedLoaded) {
            if (state.issues.isEmpty) {
              return _buildEmptyView();
            }
            return _buildIssuesList(state.issues);
          }

          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0047AB)),
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0047AB),
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Row(
        children: [
          Icon(Icons.report_problem_rounded, size: 24, color: Colors.white),
          SizedBox(width: 10),
          Text(
            'Issues',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<FeedBloc>().add(LoadIssuesEvent());
          },
        ),
      ],
    );
  }

  Widget _buildIssuesList(List<PostEntity> issues) {
    return RefreshIndicator(
      color: const Color(0xFF0047AB),
      onRefresh: () async {
        context.read<FeedBloc>().add(LoadIssuesEvent());
      },
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: issues.length,
        itemBuilder: (context, index) {
          final issue = issues[index];
          return PostCard(post: issue);
        },
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<FeedBloc>().add(LoadIssuesEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0047AB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_problem_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No issues reported yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to report an issue\nin your community',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreatePost(),
            icon: const Icon(Icons.add),
            label: const Text('Report Issue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0047AB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToCreatePost(),
      backgroundColor: const Color(0xFF0047AB),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Report Issue'),
    );
  }

  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreatePostScreen(initialPostType: PostType.issue),
      ),
    ).then((result) {
      if (result == true && mounted) {
        // Refresh issues after creating a new post
        context.read<FeedBloc>().add(LoadIssuesEvent());
      }
    });
  }
}
