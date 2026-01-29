class ApiEndpoints {
  // ============================================
  // BASE CONFIGURATION
  // ============================================
  // Development URL (local)
  static const String baseUrl = "http://127.0.0.1:8000";
  // Production URL (uncomment for production deployment)
  // static const String baseUrl = "https://api.sewasathi.gov.np";

  // ============================================
  // AUTH ENDPOINTS
  // ============================================
  static const String login = "/auth/login/";
  static const String logout = "/auth/logout/";
  static const String tokenRefresh = "/auth/token/refresh/";
  static const String tokenValidate = "/auth/token/validate/";

  // ============================================
  // PUBLIC ENDPOINTS (No Auth Required)
  // ============================================

  /// List all active places
  static const String publicPlaces = "/places/public/";

  /// Get place by slug
  static String publicPlaceBySlug(String slug) => "/places/public/$slug/";

  /// List ministries in a place
  static String publicMinistriesByPlace(String placeSlug) =>
      "/ministry/public/$placeSlug/ministries/";

  /// Get ministry detail in a place
  static String publicMinistryDetail(String placeSlug, String ministrySlug) =>
      "/ministry/public/$placeSlug/ministries/$ministrySlug/";

  /// List services in a ministry
  static String publicServicesByMinistry(
    String placeSlug,
    String ministrySlug,
  ) => "/ministry/public/$placeSlug/ministries/$ministrySlug/services/";

  /// Ministry login endpoint
  static String ministryLogin(String placeSlug, String ministrySlug) =>
      "/ministry/public/$placeSlug/$ministrySlug/login/";

  /// Staff login endpoint
  static String staffLogin(String placeSlug, String ministrySlug) =>
      "/ministry/public/$placeSlug/ministries/$ministrySlug/staff/login/";

  /// List all public ministries (deprecated, use publicMinistriesByPlace)
  static const String publicMinistries = "/ministry/public/";

  /// Get ministry by slug (deprecated, use publicMinistryDetail)
  static String publicMinistryBySlug(String slug) => "/ministry/public/$slug/";

  // ============================================
  // SUPER ADMIN ENDPOINTS - PLACE MANAGEMENT
  // ============================================

  /// List all places (Super Admin)
  static const String adminPlaces = "/places/admin/";

  /// Create place
  static const String adminPlaceCreate = "/places/admin/";

  /// Get/Update/Delete place by ID
  static String adminPlaceDetail(String id) => "/places/admin/$id/";

  // ============================================
  // SUPER ADMIN ENDPOINTS - MINISTRY MANAGEMENT
  // ============================================

  /// Get places for filter dropdown
  static const String ministriesPlacesFilter = "/ministry/admin/places/";

  /// List all ministries (across all places)
  static const String adminMinistries = "/ministry/admin/";

  /// List all ministries (alias for compatibility)
  static const String adminMinistriesList = "/ministry/admin/";

  /// Create ministry
  static const String adminMinistryCreate = "/ministry/admin/";

  /// Get ministry by ID
  static String adminMinistryDetail(String id) => "/ministry/admin/$id/";

  /// Update ministry
  static String adminMinistryUpdate(String id) => "/ministry/admin/$id/";

  /// Delete ministry (soft)
  static String adminMinistryDelete(String id) => "/ministry/admin/$id/";

  /// Activate ministry
  static String adminMinistryActivate(String id) =>
      "/ministry/admin/$id/activate/";

  /// Suspend ministry
  static String adminMinistrySuspend(String id) =>
      "/ministry/admin/$id/suspend/";

  /// List deleted ministries
  static const String adminMinistriesDeleted = "/ministry/admin/deleted/";

  /// Restore deleted ministry
  static String adminMinistryRestore(String id) =>
      "/ministry/admin/$id/restore/";

  /// Hard delete ministry
  static String adminMinistryHardDelete(String id) =>
      "/ministry/admin/$id/hard-delete/";

  /// Reset ministry admin password
  static String adminMinistryResetPassword(String id) =>
      "/ministry/admin/$id/reset-password/";

  /// List ministry users
  static String adminMinistryUsers(String ministryId) =>
      "/ministry/admin/$ministryId/users/";

  /// Add staff to ministry
  static String adminMinistryAddStaff(String ministryId) =>
      "/ministry/admin/$ministryId/add-staff/";

  /// Get/Update/Delete ministry user
  static String adminMinistryUserDetail(String ministryId, String userId) =>
      "/ministry/admin/$ministryId/users/$userId/";

  // ============================================
  // MINISTRY ADMIN ENDPOINTS (Requires X-Ministry-ID header)
  // ============================================

  /// Get own ministry details
  static const String ministryMe = "/ministry/me/";

  /// Get my ministry (alias for compatibility)
  static const String myMinistry = "/ministry/me/";

  // ============================================
  // MINISTRY MANAGEMENT - STAFF SERVICES (Ministry Admin)
  // ============================================

  /// List all staff-services in ministry
  static const String ministryStaffServices =
      "/ministry/management/staff-services/";

  /// Create staff-service
  static const String ministryStaffServicesCreate =
      "/ministry/management/staff-services/";

  /// Get/Update/Delete staff-service
  static String ministryStaffServiceDetail(String id) =>
      "/ministry/management/staff-services/$id/";

  /// Reset staff-service password
  static String ministryStaffServiceResetPassword(String id) =>
      "/ministry/management/staff-services/$id/reset-password/";

  /// Toggle staff-service status
  static String ministryStaffServiceToggleStatus(String id) =>
      "/ministry/management/staff-services/$id/toggle-status/";

  // ============================================
  // STAFF MANAGEMENT (Ministry Admin - Requires X-Ministry-ID header)
  // ============================================

  /// List all staff in ministry
  static const String staffList = "/staff/";

  /// Create staff
  static const String staffCreate = "/staff/";

  /// Get/Update/Delete staff
  static String staffDetail(String id) => "/staff/$id/";

  /// Reset staff password
  static String staffResetPassword(String id) => "/staff/$id/reset-password/";

  // ============================================
  // SERVICE MANAGEMENT (Ministry Admin - Requires X-Ministry-ID header)
  // ============================================

  /// List all services in ministry
  static const String serviceList = "/services/";

  /// Create service
  static const String serviceCreate = "/services/";

  /// Get/Update/Delete service
  static String serviceDetail(String id) => "/services/$id/";

  // ============================================
  // QUEUE CONFIGURATION (Ministry Admin)
  // ============================================

  /// Get queue config by staff service ID
  static String queueConfigByService(String staffServiceId) =>
      "/queue/config/?staff_service=$staffServiceId";

  /// Create queue configuration
  static const String queueConfigCreate = "/queue/config/";

  /// Get/Update/Delete queue config
  static String queueConfigDetail(String id) => "/queue/config/$id/";

  // ============================================
  // OFFICIALS MANAGEMENT (Ministry Admin)
  // ============================================

  /// List officials (with optional filters)
  /// Note: isActive defaults to true to show active officials by default
  static String officialsList({String? ministryId, bool isActive = true}) {
    String endpoint = "/officials/";
    List<String> params = [];
    if (ministryId != null) params.add("ministry_id=$ministryId");
    // Django expects "True" or "False" (capitalized) for boolean values
    params.add("is_active=${isActive ? 'True' : 'False'}");
    if (params.isNotEmpty) endpoint += "?${params.join('&')}";
    return endpoint;
  }

  /// Create official
  static const String officialCreate = "/officials/create/";

  /// Get/Update/Delete official
  static String officialDetail(String id) => "/officials/$id/";

  // ============================================
  // ATTENDANCE MANAGEMENT (Ministry Admin)
  // ============================================

  /// Get attendance calendar
  static String attendanceCalendar({
    required String personType,
    required String personId,
    required String startDate,
    required String endDate,
  }) =>
      "/attendance/calendar/?person_type=$personType&person_id=$personId&start_date=$startDate&end_date=$endDate";

  /// Mark attendance
  static const String attendanceMark = "/attendance/mark/";

  /// Bulk mark attendance
  static const String attendanceBulkMark = "/attendance/bulk-mark/";

  // ============================================
  // HOLIDAYS MANAGEMENT (Ministry Admin)
  // ============================================

  /// List holidays (with optional filters)
  static String holidaysList({int? year, int? month}) {
    String endpoint = "/holidays/list/";
    List<String> params = [];
    if (year != null) params.add("year=$year");
    if (month != null) params.add("month=$month");
    if (params.isNotEmpty) endpoint += "?${params.join('&')}";
    return endpoint;
  }

  /// Get holiday calendar view
  static String holidayCalendar({int? year, int? month}) {
    String endpoint = "/holidays/calendar/";
    List<String> params = [];
    if (year != null) params.add("year=$year");
    if (month != null) params.add("month=$month");
    if (params.isNotEmpty) endpoint += "?${params.join('&')}";
    return endpoint;
  }

  /// Create holiday
  static const String holidayCreate = "/holidays/create/";

  /// Update holiday
  static String holidayUpdate(String id) => "/holidays/update/$id/";

  /// Delete holiday
  static String holidayDelete(String id) => "/holidays/delete/$id/";

  // ============================================
  // QUEUE AVAILABILITY (Public/Citizen)
  // ============================================

  /// Check queue availability for a service on a date
  static String queueAvailability({
    required String staffServiceId,
    required String date,
  }) => "/queue/availability/?staff_service=$staffServiceId&date=$date";

  // ============================================
  // TOKEN BOOKING (Citizen)
  // ============================================

  /// Book a token
  static const String tokenBook = "/queue/book/";

  /// Get citizen's tokens
  static const String citizenTokens = "/queue/my-tokens/";

  /// Cancel token
  static String tokenCancel(String tokenId) => "/queue/tokens/$tokenId/cancel/";

  // ============================================
  // STAFF QUEUE MANAGEMENT (New System)
  // ============================================

  /// Get active tokens (WAITING, IN_SERVICE)
  static String staffActiveTokens(String staffServiceId) =>
      "/api/queue/staff/active-tokens/?staff_service_id=$staffServiceId";

  /// Get all tokens (complete history)
  static String staffAllTokens(String staffServiceId) =>
      "/api/queue/staff/all-tokens/?staff_service_id=$staffServiceId";

  /// Get pending tokens (government fault)
  static String staffPendingTokens(String staffServiceId) =>
      "/api/queue/staff/pending-tokens/?staff_service_id=$staffServiceId";

  /// Start token service (begins countdown)
  static String staffStartService(String tokenId) =>
      "/api/queue/staff/token/$tokenId/start-service/";

  /// Mark token as no-show
  static const String staffMarkNoShow = "/api/queue/staff/no-show/";

  /// Mark token as pending (government fault)
  static String staffMarkPending(String tokenId) =>
      "/api/queue/staff/token/$tokenId/mark-pending/";

  /// Send pending email notification
  static String staffSendPendingEmail(String tokenId) =>
      "/api/queue/staff/token/$tokenId/send-pending-email/";

  /// Mark pending token as served
  static String staffMarkPendingServed(String tokenId) =>
      "/api/queue/staff/token/$tokenId/mark-pending-served/";

  // ============================================
  // NOTICE PORTAL (Ministry Admin / Staff Admin)
  // ============================================

  /// List all notices (admin panel)
  static const String adminNotices = "/api/admin/notices/";

  /// Get/Update/Delete notice by ID
  static String adminNoticeDetail(String noticeId) =>
      "/api/admin/notices/$noticeId/";

  /// Get notice statistics
  static const String adminNoticeStats = "/api/admin/notices/stats/";

  /// Retry failed ingestion
  static String adminNoticeRetryIngestion(String noticeId) =>
      "/api/admin/notices/$noticeId/retry-ingestion/";

  /// Get available services for notice categorization
  static const String adminNoticeServices = "/api/admin/notices/services/";

  /// Public notices list (read-only)
  static const String publicNotices = "/api/notices/";

  /// Get public notice by ID
  static String publicNoticeDetail(String noticeId) =>
      "/api/notices/$noticeId/";

  // ============================================
  // UTILITY METHODS
  // ============================================

  /// Construct full API URL from endpoint
  static String getFullUrl(String endpoint) => '$baseUrl$endpoint';

  /// Handle image URLs from API
  static String getImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    return url;
  }

  /// Default placeholder for missing logos
  static const String defaultLogoPlaceholder =
      'assets/images/default_ministry_logo.png';
}
