import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/di/injection_container.dart';
import 'package:sewa_web/core/layout/app_layout.dart';
import 'package:sewa_web/core/routes/dashboard_router.dart';
import 'package:sewa_web/core/routes/dashboard_router_observer.dart';
import 'package:sewa_web/core/routes/route_names.dart';
import 'package:sewa_web/core/service/navigation_service.dart';
import 'package:sewa_web/features/ministry/presentation/bloc/staff_service_bloc.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Ministry Admin Shell - Wraps all ministry admin pages with AppLayout
/// and provides navigation for ministry staff services management
class MinistryShell extends StatefulWidget {
  const MinistryShell({super.key});

  @override
  State<MinistryShell> createState() => _MinistryShellState();
}

class _MinistryShellState extends State<MinistryShell> {
  late String _initialRoute;

  @override
  void initState() {
    super.initState();
    // Get current URL path for initial route
    _initialRoute = _getCurrentRoute();
  }

  String _getCurrentRoute() {
    // Get the current URL path directly from browser
    final path = html.window.location.pathname ?? '/';

    debugPrint('MinistryShell: Current browser path: $path');

    // Map URL paths to route names
    if (path.startsWith('/ministry/services') || path == '/ministry/services') {
      debugPrint('MinistryShell: Restoring Services page');
      return RouteNames.ministryServices;
    } else if (path == '/dashboard' || path.startsWith('/dashboard')) {
      debugPrint('MinistryShell: Dashboard path, defaulting to Services');
      return RouteNames.ministryServices;
    }

    // Default to services page
    debugPrint('MinistryShell: Unknown path, defaulting to Services');
    return RouteNames.ministryServices;
  }

  @override
  Widget build(BuildContext context) {
    final NavigationService navigationService = sl<NavigationService>();

    return BlocProvider<StaffServiceBloc>(
      create: (_) => sl<StaffServiceBloc>(),
      child: AppLayout(
        child: Navigator(
          key: navigationService.navigatorKey,
          onGenerateRoute: DashboardRouter.generateRoute,
          initialRoute: _initialRoute,
          observers: [sl<DashboardRouterObserver>()],
        ),
      ),
    );
  }
}
