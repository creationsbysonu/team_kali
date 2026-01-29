import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/core/utils/responsive_helper.dart';
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_web/features/auth/presentation/widgets/profile_dropdown.dart';

/// Clean, minimal header for dashboard - no search bar
class DashboardHeader extends StatelessWidget {
  final VoidCallback? onMenuPressed;

  const DashboardHeader({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        if (previous is Authenticated && current is Authenticated) {
          return previous.user != current.user;
        }
        return previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        if (state is Authenticated) {
          final user = state.user;
          return Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Mobile menu button
                if (ResponsiveHelper.isMobile(context) && onMenuPressed != null)
                  IconButton(
                    onPressed: onMenuPressed,
                    icon: const Icon(Icons.menu, color: AppTheme.textPrimary),
                    tooltip: 'Menu',
                  ),

                // Spacer to push actions to the right
                const Spacer(),

                // Notification bell
                _NotificationButton(
                  count: 0,
                  onPressed: () {
                    // TODO: Implement notifications
                  },
                ),

                const SizedBox(width: 8),

                // Profile dropdown
                ProfileDropdown(user: user),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Notification button with badge
class _NotificationButton extends StatefulWidget {
  final int count;
  final VoidCallback onPressed;

  const _NotificationButton({required this.count, required this.onPressed});

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.backgroundLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_outlined,
                color: _isHovered
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                size: 22,
              ),
              if (widget.count > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.count > 9 ? '9+' : widget.count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
