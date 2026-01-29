class RouteNames {
  // Auth routes
  static const String login = '/login';

  // Default dashboard route (redirects based on user role)
  static const String dashboard = '/dashboard';

  // Super Admin routes
  static const String superAdminDashboard =
      '/super-admin/places'; // Places is default
  static const String superAdminPlaces = '/super-admin/places';
  static const String superAdminMinistries = '/super-admin/ministries';
  static const String superAdminMinistryCreate =
      '/super-admin/ministries/create';
  static const String superAdminMinistryDetail = '/super-admin/ministries/:id';
  static const String superAdminMinistryEdit =
      '/super-admin/ministries/:id/edit';
  static const String superAdminMinistryStaff =
      '/super-admin/ministries/:id/staff';

  // Ministry Staff routes
  static const String ministryServices = '/ministry/services';
  static const String ministryServiceCreate = '/ministry/services/create';
  static const String ministryServiceEdit = '/ministry/services/:id/edit';
  static const String ministryOfficials = '/ministry/officials';
  static const String ministryHolidays = '/ministry/holidays';
  static const String ministryAttendance = '/ministry/attendance';
  static const String ministryViewAttendance = '/ministry/attendance/view';
  static const String ministryMarkAttendance = '/ministry/attendance/mark';
  static const String ministryQueueConfig = '/ministry/queue-config';
  static const String ministryQueueConfigEdit = '/ministry/queue-config/edit';
  static const String ministryNotices = '/ministry/notices';
  static const String ministryProfile = '/ministry/profile';
  static const String ministrySettings = '/ministry/settings';
  static const String ministryTeam = '/ministry/team';
  static const String ministryInvitations = '/ministry/invitations';

  // Staff Public routes (No auth required)
  static String publicServicesByMinistry(
    String placeSlug,
    String ministrySlug,
  ) => '/staff/services/$placeSlug/$ministrySlug';

  static String staffLogin(
    String placeSlug,
    String ministrySlug,
    String serviceSlug,
  ) => '/staff/login/$placeSlug/$ministrySlug/$serviceSlug';

  // Staff Dashboard routes (Auth required)
  static const String staffDashboard = '/staff/dashboard';
  static const String staffQueuePanel =
      '/staff/queue-panel'; // Legacy unified panel (deprecated)
  static const String staffNotices = '/staff/notices';

  // Staff Queue Management - 3 separate pages
  static const String staffActiveTokens = '/staff/active-tokens';
  static const String staffAllTokens = '/staff/all-tokens';
  static const String staffPendingTokens = '/staff/pending-tokens';

  // Legacy routes (deprecated - use individual pages instead)
  static const String staffQueueDashboard = '/staff/queue';
  static const String staffQueueToday = '/staff/queue/today';
  static const String staffProgressWorkbench = '/staff/queue/progress';

  // Common routes
  static const String profile = '/profile';
  static const String settings = '/settings';
}
