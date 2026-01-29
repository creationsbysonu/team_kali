import 'package:flutter/material.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/core/widget/loading_overlay.dart';
import 'package:sewa_web/features/auth/domain/entities/user_entity.dart';
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileDropdown extends StatelessWidget {
  final UserEntity user;
  const ProfileDropdown({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Hide loading overlay when logout completes or errors
        if (state is UnAuthenticated || state is AuthError) {
          LoadingOverlay.hide();
        }
      },
      child: PopupMenuButton<String>(
        onSelected: (String value) {
          if (value == 'logout') {
            // Show loading overlay before logout
            LoadingOverlay.show(context, message: 'Logging out...');
            context.read<AuthBloc>().add(LogoutEvent());
          }
        },
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        ),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'logout',
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.negative),
              title: Text(
                'Log Out',
                style: AppTheme.bodyMedium().copyWith(color: AppTheme.negative),
              ),
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium - 4,
            vertical: AppTheme.spacingSmall,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            border: Border.all(
              color: AppTheme.borderColor.withAlpha((0.2 * 255).round()),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: user.profilePictureUrl != null
                    ? NetworkImage(user.profilePictureUrl!)
                    : null,
                backgroundColor: user.profilePictureUrl == null
                    ? AppTheme.accentBlue
                    : null,
                onBackgroundImageError: user.profilePictureUrl != null
                    ? (exception, stackTrace) {
                        debugPrint('Error loading profile image : $exception');
                      }
                    : null,
                child: user.profilePictureUrl == null
                    ? Text(
                        ((user.fullName?.isNotEmpty == true)
                            ? user.fullName![0]
                            : user.email[0].toUpperCase()),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                user.fullName ?? user.email,
                style: AppTheme.bodyMedium().copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: AppTheme.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
