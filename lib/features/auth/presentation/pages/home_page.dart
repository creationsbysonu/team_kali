import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/core/theme/theme.dart';
import 'package:sewa_sathi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_sathi/features/auth/presentation/pages/email_page.dart';

/// Home page displayed after successful authentication.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const EmailPage()),
            (route) => false,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is Authenticated ? state.user : null;
          final isNewUser = state is Authenticated && state.isNewUser;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: AppTheme.primaryCobalt,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Sewa Sathi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: AppTheme.fontWeightSemiBold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _handleLogout(context),
                  tooltip: 'Logout',
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome banner
                    if (isNewUser)
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        margin: const EdgeInsets.only(
                          bottom: AppTheme.spacingLarge,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.celebration,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: AppTheme.spacingMedium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome to Sewa Sathi!',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeLarge,
                                      fontWeight: AppTheme.fontWeightBold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppTheme.spacingXSmall,
                                  ),
                                  Text(
                                    'Your account has been created successfully.',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeSmall,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Success card
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingLarge),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        boxShadow: AppTheme.shadowMedium,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 50,
                              color: AppTheme.success,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMedium),
                          Text(
                            isNewUser ? 'Welcome!' : 'Welcome Back!',
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeTitle,
                              fontWeight: AppTheme.fontWeightBold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSmall),
                          const Text(
                            'You have successfully logged in.',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeMedium,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),

                    // User info card
                    if (user != null)
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCobaltPale.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Profile',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: AppTheme.fontWeightSemiBold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Divider(height: AppTheme.spacingLarge),
                            _buildInfoRow(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: user.email,
                            ),
                            const SizedBox(height: AppTheme.spacingMedium),
                            _buildInfoRow(
                              icon: Icons.person_outline,
                              label: 'User Type',
                              value: user.userType.toUpperCase(),
                            ),
                            const SizedBox(height: AppTheme.spacingMedium),
                            _buildInfoRow(
                              icon: Icons.verified_user_outlined,
                              label: 'Status',
                              value: user.isVerified
                                  ? 'Verified'
                                  : 'Unverified',
                              valueColor: user.isVerified
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppTheme.spacingXLarge),

                    // Quick actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: AppTheme.fontWeightSemiBold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppTheme.spacingMedium,
                      crossAxisSpacing: AppTheme.spacingMedium,
                      childAspectRatio: 1.3,
                      children: [
                        _buildQuickAction(
                          icon: Icons.article_outlined,
                          label: 'My Applications',
                          color: AppTheme.primaryCobalt,
                          onTap: () {},
                        ),
                        _buildQuickAction(
                          icon: Icons.support_agent_outlined,
                          label: 'Support',
                          color: AppTheme.accentGreen,
                          onTap: () {},
                        ),
                        _buildQuickAction(
                          icon: Icons.history_outlined,
                          label: 'History',
                          color: AppTheme.accentPurple,
                          onTap: () {},
                        ),
                        _buildQuickAction(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          color: AppTheme.textSecondary,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryCobalt),
        const SizedBox(width: AppTheme.spacingSmall),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: AppTheme.fontSizeMedium,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: AppTheme.fontWeightSemiBold,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: AppTheme.fontWeightMedium,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
