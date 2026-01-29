import 'package:flutter/material.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/places/domain/entities/place.dart';

/// Page shown after place is selected
/// Offers choice between Ministry Login and Staff Login
class PlaceSelectionPage extends StatelessWidget {
  final Place place;
  final VoidCallback onMinistryLoginSelected;
  final VoidCallback onStaffLoginSelected;
  final VoidCallback onBack;

  const PlaceSelectionPage({
    super.key,
    required this.place,
    required this.onMinistryLoginSelected,
    required this.onStaffLoginSelected,
    required this.onBack,
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
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onBack,
                ),
              ),
              const SizedBox(height: 16),

              // Place info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_city,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      place.name,
                      style: AppTheme.headingMedium().copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select Login Type',
                style: AppTheme.bodyLarge().copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 48),

              // Ministry Login Card
              _LoginOptionCard(
                title: 'Ministry Admin',
                subtitle: 'Login as ministry administrator',
                icon: Icons.account_balance,
                color: AppTheme.accentBlue,
                onTap: onMinistryLoginSelected,
              ),
              const SizedBox(height: 16),

              // Staff Login Card
              _LoginOptionCard(
                title: 'Staff Login',
                subtitle: 'Login as ministry staff',
                icon: Icons.person,
                color: AppTheme.accentGreen,
                onTap: onStaffLoginSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LoginOptionCard({
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.headingSmall().copyWith(
                          color: AppTheme.primaryCobaltDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.bodyMedium().copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
