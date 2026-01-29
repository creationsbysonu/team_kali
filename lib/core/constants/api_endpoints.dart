/// API endpoint constants for the Sewa Sathi backend.
class ApiEndpoints {
  // Base URL - Update for production
  // For physical device: use your computer's local IP
  // For emulator: use 10.0.2.2
  static const String baseUrl = 'http://192.168.185.111:8000';

  // AI Image Moderation Server (separate from main API)
  // Runs on port 8003 for image classification
  // This is the ONLY server needed for community feature (hackathon MVP)
  static const String moderationServerUrl = 'http://192.168.1.87:8003';

  // Auth Endpoints
  static const String authBase = '/auth';
  static const String otpRequest = '$authBase/otp/request/';
  static const String otpVerify = '$authBase/otp/verify/';
  static const String otpResend = '$authBase/otp/resend/';
  static const String profile = '$authBase/profile/';
  static const String tokenRefresh = '$authBase/token/refresh/';
  static const String logout = '$authBase/logout/';

  // Mobile Profile Endpoints
  static const String mobileBase = '/api/mobile';
  static const String profileStatus = '$mobileBase/profile/status/';
  static const String profileSetup = '$mobileBase/profile/setup/';
  static const String profileUpdate = '$mobileBase/profile/update/';
  static const String places = '$mobileBase/places/';

  // Notice Endpoints (Public)
  static const String notices = '/api/public/notices/';
  static String noticeDetail(String id) => '/api/public/notices/$id/';
  static const String noticeFilters = '/api/public/notices/filters/';

  // Chat Endpoint (AI Assistant)
  static const String chat = '/api/chat/';

  // ============ Citizen API v1 - Queue Management ============
  // Base URL for Citizen API following backend team guidelines
  static const String citizenApiBase = '/api/citizen/v1';

  // Ministries by place (Public) - GET /places/{place_identifier}/ministries/
  static String ministriesByPlace(String placeId) =>
      '$citizenApiBase/places/$placeId/ministries/';

  // Services by ministry (Public) - GET /ministries/{ministry_identifier}/services/
  static String servicesByMinistry(String ministryId) =>
      '$citizenApiBase/ministries/$ministryId/services/';

  // Service details (Public) - GET /services/{service_id}/
  static String serviceDetails(String serviceId) =>
      '$citizenApiBase/services/$serviceId/';

  // Service availability check (Public) - GET /services/{service_id}/availability/
  static String serviceAvailability(String serviceId) =>
      '$citizenApiBase/services/$serviceId/availability/';

  // My tokens (Authenticated) - GET /tokens/
  static const String myTokens = '$citizenApiBase/tokens/';

  // Token details (Authenticated) - GET /tokens/{token_id}/
  static String tokenDetails(String tokenId) =>
      '$citizenApiBase/tokens/$tokenId/';

  // Book token (Authenticated) - POST /tokens/book/
  static const String bookToken = '$citizenApiBase/tokens/book/';

  // Cancel token (Authenticated)
  static String cancelToken(String tokenId) =>
      '$citizenApiBase/tokens/$tokenId/cancel/';

  // ============ AI Image Moderation (Port 8003) ============
  // Community posts are stored LOCALLY using Hive.
  // Only this endpoint is used to classify images before saving.
  static const String moderateEndpoint = '/v1/inference';
  static String get moderateUrl => '$moderationServerUrl$moderateEndpoint';

  // WebSocket URL for real-time chat (optional)
  static String get webSocketUrl =>
      baseUrl.replaceAll('http://', 'ws://').replaceAll('https://', 'wss://');
  static String get webSocketChat => '$webSocketUrl/ws/chat/';
}
