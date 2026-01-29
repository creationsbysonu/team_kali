import 'package:flutter/material.dart';
import 'package:sewa_web/core/theme/theme.dart';

/// Role Selection Screen - Landing Page (/)
/// Simple choice: Super Admin Portal OR Select Place
class RoleSelectionPage extends StatelessWidget {
  final VoidCallback onSuperAdminSelected;
  final VoidCallback onSelectPlaceSelected;

  const RoleSelectionPage({
    super.key,
    required this.onSuperAdminSelected,
    required this.onSelectPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCobaltDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                'Sewa Sathi',
                style: AppTheme.headingLarge().copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Admin Portal',
                style: AppTheme.bodyLarge().copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 48),

              // Super Admin Card
              _PortalCard(
                title: 'Super Admin',
                subtitle: 'Manage all places and ministries',
                icon: Icons.admin_panel_settings,
                color: AppTheme.accentRed,
                onTap: onSuperAdminSelected,
              ),
              const SizedBox(height: 16),

              // Select Place Card
              _PortalCard(
                title: 'Select Place',
                subtitle: 'Login as ministry admin or staff',
                icon: Icons.location_city,
                color: AppTheme.accentBlue,
                onTap: onSelectPlaceSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PortalCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.headingSmall().copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.bodySmall().copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
