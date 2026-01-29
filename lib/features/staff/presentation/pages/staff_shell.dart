import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/di/injection_container.dart';
import 'package:sewa_web/core/layout/app_layout.dart';
import 'package:sewa_web/core/routes/dashboard_router.dart';
import 'package:sewa_web/core/routes/dashboard_router_observer.dart';
import 'package:sewa_web/core/routes/route_names.dart';
import 'package:sewa_web/core/service/navigation_service.dart';
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_web/features/staff_queue/presentation/bloc/staff_panel_bloc.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Staff Admin Shell - Container for staff admin pages with sidebar navigation
/// Provides BLoC for queue management and handles routing to:
/// - Active Tokens page
/// - All Tokens page
/// - Pending Tokens page
/// - Notices page
class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  late String _initialRoute;

  @override
  void initState() {
    super.initState();
    _initialRoute = _getCurrentRoute();
  }

  String _getCurrentRoute() {
    // Get the current URL path directly from browser
    final path = html.window.location.pathname ?? '/';

    debugPrint('StaffShell: Current browser path: $path');

    // Map URL paths to route names
    if (path.startsWith('/staff/all-tokens') || path == '/staff/all-tokens') {
      debugPrint('StaffShell: Restoring All Tokens page');
      return RouteNames.staffAllTokens;
    } else if (path.startsWith('/staff/pending-tokens') ||
        path == '/staff/pending-tokens') {
      debugPrint('StaffShell: Restoring Pending Tokens page');
      return RouteNames.staffPendingTokens;
    } else if (path.startsWith('/staff/notices') || path == '/staff/notices') {
      debugPrint('StaffShell: Restoring Notices page');
      return RouteNames.staffNotices;
    }

    // Default to active tokens page
    debugPrint('StaffShell: Defaulting to Active Tokens page');
    return RouteNames.staffActiveTokens;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Get staff service info from auth state
        String staffServiceId = '';
        String serviceName = '';

        if (authState is Authenticated) {
          staffServiceId = authState.user.service?.id ?? '';
          serviceName = authState.user.service?.name ?? 'Queue Management';
        }

        // If no service info, show error
        if (staffServiceId.isEmpty) {
          return AppLayout(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Service Assigned',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your account is not associated with any service.\nPlease contact your administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(LogoutEvent());
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }

        // Provide the StaffPanelBloc to all child pages
        return BlocProvider(
          create: (context) => sl<StaffPanelBloc>()
            ..add(
              InitializeStaffPanel(
                staffServiceId: staffServiceId,
                serviceName: serviceName,
              ),
            ),
          child: _StaffShellContent(initialRoute: _initialRoute),
        );
      },
    );
  }
}

class _StaffShellContent extends StatelessWidget {
  final String initialRoute;

  const _StaffShellContent({required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final NavigationService navigationService = sl<NavigationService>();

    return AppLayout(
      child: Navigator(
        key: navigationService.navigatorKey,
        onGenerateRoute: DashboardRouter.generateRoute,
        initialRoute: initialRoute,
        observers: [sl<DashboardRouterObserver>()],
      ),
    );
  }
}
