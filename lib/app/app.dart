import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/core/di/injection_container.dart' as di;
import 'package:sewa_sathi/core/routes/dashboard_router.dart';
import 'package:sewa_sathi/core/theme/theme.dart';
import 'package:sewa_sathi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_sathi/features/auth/presentation/pages/email_page.dart';
import 'package:sewa_sathi/features/home/presentation/pages/home_screen.dart';
import 'package:sewa_sathi/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:sewa_sathi/features/profile/presentation/pages/name_input_page.dart';
import 'package:sewa_sathi/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:sewa_sathi/features/notice/presentation/bloc/notice_bloc.dart';

/// Main app widget.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        BlocProvider<ProfileBloc>(create: (context) => di.sl<ProfileBloc>()),
        BlocProvider<ChatBloc>(create: (context) => di.sl<ChatBloc>()),
        BlocProvider<NoticeBloc>(create: (context) => di.sl<NoticeBloc>()),
      ],
      child: MaterialApp(
        title: 'Sewa Sathi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buildThemeData(),
        onGenerateRoute: DashboardRouter.generateRoute,
        home: const _AuthWrapper(),
      ),
    );
  }
}

/// Wrapper to handle authentication state and show appropriate screen.
class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      // Only rebuild for major auth state changes
      buildWhen: (previous, current) {
        // ONLY rebuild when authentication status actually changes:
        // 1. Became authenticated
        if (current is Authenticated) return true;
        // 2. Became unauthenticated (from authenticated or initial check)
        if (current is Unauthenticated && previous is! Unauthenticated) {
          return true;
        }
        // 3. Initial app load (first state)
        if (previous is AuthInitial && current is AuthLoading) return true;
        // 4. Initial check completed (AuthLoading -> Unauthenticated/Authenticated)
        if (previous is AuthLoading &&
            (current is Unauthenticated || current is Authenticated)) {
          return true;
        }
        // DON'T rebuild for:
        // - OtpSent, OtpResent, AuthError (let pages handle)
        // - AuthLoading during OTP flow (would hide EmailPage)
        return false;
      },
      builder: (context, state) {
        // Only show splash during INITIAL app load
        if (state is AuthInitial) {
          return const _SplashScreen();
        }

        // Show profile setup if authenticated but profile incomplete
        if (state is Authenticated) {
          if (!state.isProfileComplete) {
            return const NameInputPage();
          }
          return const HomeScreen();
        }

        // Show email page for all other states
        // (Unauthenticated, OtpSent, OtpResent, AuthError, AuthLoading during OTP flow)
        return const EmailPage();
      },
    );
  }
}

/// Splash screen shown while checking auth status.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                boxShadow: AppTheme.shadowLarge,
              ),
              child: const Icon(
                Icons.handshake_outlined,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            const Text(
              'Sewa Sathi',
              style: TextStyle(
                fontSize: AppTheme.fontSizeDisplay,
                fontWeight: AppTheme.fontWeightBold,
                color: AppTheme.primaryCobalt,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXLarge),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryCobalt,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
