import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/di/injection_container.dart';
import 'package:sewa_web/core/layout/app_layout.dart';
import 'package:sewa_web/core/routes/dashboard_router.dart';
import 'package:sewa_web/core/routes/dashboard_router_observer.dart';
import 'package:sewa_web/core/routes/route_names.dart';
import 'package:sewa_web/core/service/navigation_service.dart';
import 'package:sewa_web/features/super_admin/presentation/bloc/ministry_bloc.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
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

    debugPrint('DashboardShell: Current browser path: $path');

    // Map URL paths to route names
    if (path.startsWith('/super-admin/ministries') ||
        path == '/super-admin/ministries') {
      debugPrint('DashboardShell: Restoring Ministries page');
      return RouteNames.superAdminMinistries;
    } else if (path.startsWith('/super-admin/places') ||
        path == '/super-admin/places') {
      debugPrint('DashboardShell: Restoring Places page');
      return RouteNames.superAdminPlaces;
    } else if (path == '/dashboard' || path.startsWith('/dashboard')) {
      debugPrint('DashboardShell: Dashboard path, defaulting to Places');
      return RouteNames.superAdminPlaces;
    }

    // Default to places page
    debugPrint('DashboardShell: Unknown path, defaulting to Places');
    return RouteNames.superAdminPlaces;
  }

  @override
  Widget build(BuildContext context) {
    final NavigationService navigationService = sl<NavigationService>();
    return BlocProvider<MinistryBloc>.value(
      value: sl<MinistryBloc>(),
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
