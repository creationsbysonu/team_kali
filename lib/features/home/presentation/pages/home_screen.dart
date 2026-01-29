import 'package:flutter/material.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:sewa_sathi/features/home/presentation/widgets/ad_banner_carousel.dart';
import 'package:sewa_sathi/features/home/presentation/widgets/feature_card.dart';
import 'package:sewa_sathi/features/home/presentation/widgets/section_title.dart';
import 'package:sewa_sathi/features/chat/presentation/pages/chat_screen.dart';
import 'package:sewa_sathi/core/routes/route_names.dart';
import 'package:sewa_sathi/core/theme/theme.dart';

/// Main home screen with navigation bar and feature cards.
///
/// Assets required in pubspec.yaml:
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/
///     - assets/ad_banner/
/// ```
///
/// Images needed:
/// - assets/images/app_logo.png
/// - assets/ad_banner/1.png
/// - assets/ad_banner/2.png
/// - assets/ad_banner/3.png
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 16),

              // Ad Banner Carousel
              const AdBannerCarousel(),

              const SizedBox(height: 24),

              // Digital Queue Section
              const SectionTitle(title: 'Digital Queue (लाइन)'),
              _buildDigitalQueueSection(),

              const SizedBox(height: 24),

              // Community Section
              const SectionTitle(title: 'Community (समुदाय)'),
              _buildCommunitySection(),

              const SizedBox(height: 80), // Bottom padding for nav bar
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Header with app logo and greeting.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // App Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.handshake_rounded,
                    color: AppTheme.primary,
                    size: 26,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Namaskar 🙏',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                'Welcome to Sewa Sathi',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Digital Queue section with Get Token and View Tokens cards.
  Widget _buildDigitalQueueSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1,
        children: [
          FeatureCard(
            title: 'Get Token',
            subtitle: 'टोकन लिनुहोस्',
            icon: Icons.confirmation_number_rounded,
            iconColor: Colors.white,
            iconBackgroundColor: const Color(0xFF4CAF50),
            onTap: () {
              // Navigate to ministry list with default place ID
              // TODO: Get actual place ID from user profile
              Navigator.pushNamed(
                context,
                RouteNames.ministryList,
                arguments: 1, // Default place ID
              );
            },
          ),
          FeatureCard(
            title: 'View Tokens',
            subtitle: 'टोकनहरू हेर्नुहोस्',
            icon: Icons.format_list_numbered_rounded,
            iconColor: Colors.white,
            iconBackgroundColor: const Color(0xFF2196F3),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.myTokens);
            },
          ),
        ],
      ),
    );
  }

  /// Community section with Issues and Ideas cards.
  Widget _buildCommunitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1,
        children: [
          FeatureCard(
            title: 'Issues',
            subtitle: 'समस्याहरू',
            icon: Icons.report_problem_rounded,
            iconColor: Colors.white,
            iconBackgroundColor: const Color(0xFF0047AB),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.issues);
            },
          ),
          FeatureCard(
            title: 'Ideas',
            subtitle: 'विचारहरू',
            icon: Icons.lightbulb_rounded,
            iconColor: Colors.white,
            iconBackgroundColor: const Color(0xFF0047AB).withOpacity(0.8),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.ideas);
            },
          ),
        ],
      ),
    );
  }

  /// Bottom navigation bar with snake effect.
  Widget _buildBottomNavigationBar() {
    return SnakeNavigationBar.color(
      backgroundColor: const Color(0xFF0047AB),
      behaviour: SnakeBarBehaviour.floating,
      snakeShape: SnakeShape.circle,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      padding: const EdgeInsets.all(12),
      snakeViewColor: Colors.red,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white,
      showUnselectedLabels: true,
      showSelectedLabels: true,
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        _handleNavigationTap(index);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notices',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  /// Handle navigation bar tap events.
  void _handleNavigationTap(int index) {
    switch (index) {
      case 0:
        // Home - Already on home
        break;
      case 1:
        // Notices - Navigate to notice list screen
        Navigator.pushNamed(context, RouteNames.noticeList).then((_) {
          // Reset to Home when returning
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
      case 2:
        // AI - Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        ).then((_) {
          // Reset to Home when returning
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
      case 3:
        // Profile
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile - Coming Soon')));
        // Reset immediately since there's no navigation
        setState(() {
          _selectedIndex = 0;
        });
        break;
    }
  }
}
