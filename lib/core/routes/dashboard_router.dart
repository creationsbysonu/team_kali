import 'package:flutter/material.dart';
import 'package:sewa_web/core/routes/route_names.dart';
import 'package:sewa_web/features/attendance/presentation/pages/attendance_calendar_page.dart';
import 'package:sewa_web/features/auth/presentation/pages/login_page.dart';
import 'package:sewa_web/features/holidays/presentation/pages/holidays_page.dart';
import 'package:sewa_web/features/ministry/data/models/staff_service_model.dart';
import 'package:sewa_web/features/ministry/presentation/pages/services/services_list_page.dart';
import 'package:sewa_web/features/notice/presentation/pages/notice_list_page.dart';
import 'package:sewa_web/features/officials/presentation/pages/officials_page.dart';
import 'package:sewa_web/features/queue_management/presentation/pages/queue_config_edit_page.dart';
import 'package:sewa_web/features/queue_management/presentation/pages/queue_configuration_page.dart';
import 'package:sewa_web/features/staff/presentation/pages/staff_login_page.dart';
import 'package:sewa_web/features/staff_queue/presentation/pages/staff_active_tokens_page.dart';
import 'package:sewa_web/features/staff_queue/presentation/pages/staff_all_tokens_page.dart';
import 'package:sewa_web/features/staff_queue/presentation/pages/staff_pending_tokens_page.dart';
import 'package:sewa_web/features/super_admin/presentation/pages/ministries/super_admin_ministries_page.dart';
import 'package:sewa_web/features/super_admin/presentation/pages/places/super_admin_places_page.dart';

class DashboardRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Handle staff routes with URL parameters
    if (settings.name?.startsWith('/staff/services/') ?? false) {
      return _handlePublicServicesRoute(settings);
    }

    if (settings.name?.startsWith('/staff/login/') ?? false) {
      return _handleStaffLoginRoute(settings);
    }

    switch (settings.name) {
      case RouteNames.login:
        return _buildRoute(const LoginPage(), settings);

      // Super Admin routes - Places is the default dashboard
      case RouteNames.dashboard:
      case RouteNames.superAdminPlaces:
        return _buildRoute(const SuperAdminPlacesPage(), settings);
      case RouteNames.superAdminMinistries:
        return _buildRoute(const SuperAdminMinistriesPage(), settings);

      // Ministry Staff routes
      case RouteNames.ministryServices:
        return _buildRoute(const ServicesListPage(), settings);
      case RouteNames.ministryOfficials:
        return _buildRoute(const OfficialsPage(), settings);
      case RouteNames.ministryHolidays:
        return _buildRoute(const HolidaysPage(), settings);
      case RouteNames.ministryAttendance:
      case RouteNames.ministryViewAttendance:
      case RouteNames.ministryMarkAttendance:
        return _buildRoute(const AttendanceCalendarPage(), settings);
      case RouteNames.ministryQueueConfig:
        return _buildRoute(const QueueConfigurationPage(), settings);
      case RouteNames.ministryNotices:
        return _buildRoute(const NoticeListPageWrapper(), settings);
      case RouteNames.ministryQueueConfigEdit:
        final args = settings.arguments as Map<String, dynamic>?;
        final service = args?['service'] as Map<String, dynamic>?;
        final isConfigured = args?['isConfigured'] as bool? ?? false;
        return _buildRoute(
          QueueConfigEditPage(service: service, isConfigured: isConfigured),
          settings,
        );
      case RouteNames.ministryProfile:
        return _buildRoute(_buildPlaceholder('Ministry Profile'), settings);
      case RouteNames.ministryTeam:
        return _buildRoute(_buildPlaceholder('Team Management'), settings);

      // Staff Dashboard routes - 3 separate pages
      case RouteNames.staffActiveTokens:
        return _buildRoute(const StaffActiveTokensPage(), settings);
      case RouteNames.staffAllTokens:
        return _buildRoute(const StaffAllTokensPage(), settings);
      case RouteNames.staffPendingTokens:
        return _buildRoute(const StaffPendingTokensPage(), settings);

      // Staff Dashboard routes - Legacy unified panel (deprecated)
      case RouteNames.staffDashboard:
      case RouteNames.staffQueuePanel:
      case RouteNames.staffQueueDashboard:
      case RouteNames.staffQueueToday:
      case RouteNames.staffProgressWorkbench:
        // Legacy routes redirect to Active Tokens page
        return _buildRoute(const StaffActiveTokensPage(), settings);

      // Staff Notices route
      case RouteNames.staffNotices:
        return _buildRoute(const NoticeListPageWrapper(), settings);

      case RouteNames.profile:
        return _buildRoute(_buildPlaceholder('Profile'), settings);

      default:
        return _buildRoute(
          _buildPlaceholder('Page Not Found: ${settings.name}'),
          settings,
        );
    }
  }

  /// Handle /staff/services/:placeSlug/:ministrySlug route
  static Route<dynamic> _handlePublicServicesRoute(RouteSettings settings) {
    // This route is now handled by app_router.dart with BLoC pattern
    // Redirect to app router
    return _buildRoute(
      _buildPlaceholder('Use main app router for staff services'),
      settings,
    );
  }

  /// Handle /staff/login/:placeSlug/:ministrySlug/:serviceSlug route
  static Route<dynamic> _handleStaffLoginRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');
    final segments = uri.pathSegments;

    // Expected: ['staff', 'login', placeSlug, ministrySlug, serviceSlug]
    if (segments.length >= 5) {
      final args = settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        final service = args['service'] as StaffServiceModel?;
        final placeSlug = args['placeSlug'] as String?;
        final ministrySlug = args['ministrySlug'] as String?;
        final ministryName = args['ministryName'] as String?;

        if (service != null &&
            placeSlug != null &&
            ministrySlug != null &&
            ministryName != null) {
          return _buildRoute(
            StaffLoginPage(
              service: service,
              placeSlug: placeSlug,
              ministrySlug: ministrySlug,
              ministryName: ministryName,
            ),
            settings,
          );
        }
      }
    }

    return _buildRoute(_buildPlaceholder('Invalid Login Route'), settings);
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  static Widget _buildPlaceholder(String title) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This page is under construction',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
