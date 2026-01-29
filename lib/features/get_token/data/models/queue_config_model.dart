import 'package:sewa_sathi/features/get_token/domain/entities/queue_config_entity.dart';

/// Queue Config model with JSON serialization.
class QueueConfigModel extends QueueConfigEntity {
  const QueueConfigModel({
    required super.id,
    required super.serviceName,
    super.serviceLogoUrl,
    required super.staffName,
    super.staffImageUrl,
    required super.ministryName,
    required super.officeHours,
    required super.officeStartTime,
    required super.officeEndTime,
    super.lunchBreak,
    super.lunchStartTime,
    super.lunchEndTime,
    required super.averageServiceTimeMinutes,
    required super.averageServiceTimeDisplay,
    required super.dailyCapacity,
    required super.documentsRequired,
    required super.prebookingAllowed,
    super.prebookingInfo,
    required super.emergencyAllowed,
    super.emergencyInfo,
    required super.progressTrackingEnabled,
    required super.progressSteps,
    required super.officials,
    required super.isAvailableToday,
    required super.availabilityStatus,
    required super.tokensAvailableToday,
    required super.tokensBookedToday,
    super.currentToken,
    required super.estimatedWaitTime,
    required super.active,
  });

  /// Create from JSON response.
  factory QueueConfigModel.fromJson(Map<String, dynamic> json) {
    // Parse booking_options from API response
    final bookingOptions = json['booking_options'] as Map<String, dynamic>?;
    final prebookOptions = bookingOptions?['prebook'] as Map<String, dynamic>?;
    final emergencyOptions =
        bookingOptions?['emergency'] as Map<String, dynamic>?;

    // Parse average service time - could be string like "20 minutes" or int
    final avgServiceTime =
        json['avg_service_time'] ?? json['average_service_time_display'] ?? '';
    int avgServiceMinutes = json['average_service_time_minutes'] ?? 15;
    if (avgServiceTime is String && avgServiceTime.isNotEmpty) {
      // Try to extract number from string like "20 minutes"
      final match = RegExp(r'(\d+)').firstMatch(avgServiceTime);
      if (match != null) {
        avgServiceMinutes = int.tryParse(match.group(1)!) ?? 15;
      }
    }

    // Parse office hours - could be combined string "10:00 AM - 05:00 PM" or separate fields
    final officeHoursStr = json['office_hours'] as String? ?? '';
    String officeStartTime = json['office_start_time'] ?? '';
    String officeEndTime = json['office_end_time'] ?? '';

    // If separate times not provided, parse from combined office_hours string
    if ((officeStartTime.isEmpty || officeEndTime.isEmpty) &&
        officeHoursStr.contains(' - ')) {
      final parts = officeHoursStr.split(' - ');
      if (parts.length == 2) {
        officeStartTime = parts[0].trim();
        officeEndTime = parts[1].trim();
      }
    }

    // Parse lunch break similarly
    final lunchBreakStr = json['lunch_break'] as String?;
    String? lunchStartTime = json['lunch_start_time'];
    String? lunchEndTime = json['lunch_end_time'];

    if (lunchBreakStr != null &&
        lunchBreakStr.contains(' - ') &&
        (lunchStartTime == null || lunchEndTime == null)) {
      final parts = lunchBreakStr.split(' - ');
      if (parts.length == 2) {
        lunchStartTime = parts[0].trim();
        lunchEndTime = parts[1].trim();
      }
    }

    return QueueConfigModel(
      id: json['id']?.toString() ?? '',
      serviceName: json['service_name'] ?? '',
      serviceLogoUrl: json['service_logo_url'],
      staffName: json['staff_name'] ?? '',
      staffImageUrl: json['staff_image_url'],
      ministryName: json['ministry_name'] ?? '',
      officeHours: officeHoursStr,
      officeStartTime: officeStartTime,
      officeEndTime: officeEndTime,
      lunchBreak: lunchBreakStr,
      lunchStartTime: lunchStartTime,
      lunchEndTime: lunchEndTime,
      averageServiceTimeMinutes: avgServiceMinutes,
      averageServiceTimeDisplay: avgServiceTime is String
          ? avgServiceTime
          : '$avgServiceMinutes minutes',
      dailyCapacity: json['daily_capacity'] ?? 0,
      // Support both 'documents' and 'documents_required' keys
      documentsRequired: _parseDocuments(
        json['documents'] ?? json['documents_required'],
      ),
      // Parse prebooking from booking_options.prebook
      prebookingAllowed:
          prebookOptions?['enabled'] ?? json['prebooking_allowed'] ?? false,
      prebookingInfo: prebookOptions != null
          ? _parsePrebookingInfoFromOptions(prebookOptions)
          : (json['prebooking_info'] != null
                ? _parsePrebookingInfo(json['prebooking_info'])
                : null),
      // Parse emergency from booking_options.emergency
      emergencyAllowed:
          emergencyOptions?['enabled'] ?? json['emergency_allowed'] ?? false,
      emergencyInfo: emergencyOptions != null
          ? _parseEmergencyInfoFromOptions(emergencyOptions)
          : (json['emergency_info'] != null
                ? _parseEmergencyInfo(json['emergency_info'])
                : null),
      progressTrackingEnabled: json['progress_tracking_enabled'] ?? false,
      progressSteps: _parseProgressSteps(json['progress_steps']),
      officials: _parseOfficials(json['officials']),
      isAvailableToday: json['is_available_today'] ?? false,
      availabilityStatus: _parseAvailabilityStatus(json['availability_status']),
      tokensAvailableToday: json['tokens_available_today'] ?? 0,
      tokensBookedToday: json['tokens_booked_today'] ?? 0,
      currentToken: json['current_token'],
      estimatedWaitTime: json['estimated_wait_time'] ?? '',
      active: json['active'] ?? false,
    );
  }

  /// Parse documents list.
  static List<DocumentRequired> _parseDocuments(dynamic json) {
    if (json == null || json is! List) return [];
    return json
        .map(
          (e) => DocumentRequired(
            name: e['name'] ?? '',
            sampleImageUrl: e['sample_image_url'],
          ),
        )
        .toList();
  }

  /// Parse prebooking info.
  static PrebookingInfo _parsePrebookingInfo(Map<String, dynamic> json) {
    return PrebookingInfo(
      allowed: json['allowed'] ?? false,
      leadHours: json['lead_hours'],
      quotaPerDay: json['quota_per_day'],
      message: json['message'] ?? '',
    );
  }

  /// Parse prebooking info from booking_options.prebook format.
  static PrebookingInfo _parsePrebookingInfoFromOptions(
    Map<String, dynamic> json,
  ) {
    return PrebookingInfo(
      allowed: json['enabled'] ?? false,
      leadHours: json['lead_hours'],
      quotaPerDay: json['quota'],
      message: json['message'] ?? 'Prebooking available',
    );
  }

  /// Parse emergency info from booking_options.emergency format.
  static EmergencyInfo _parseEmergencyInfoFromOptions(
    Map<String, dynamic> json,
  ) {
    return EmergencyInfo(
      allowed: json['enabled'] ?? false,
      fee: json['fee']?.toString(),
      quotaPerDay: json['quota'],
      message: json['message'] ?? 'Emergency booking available',
    );
  }

  /// Parse emergency info.
  static EmergencyInfo _parseEmergencyInfo(Map<String, dynamic> json) {
    return EmergencyInfo(
      allowed: json['allowed'] ?? false,
      fee: json['fee']?.toString(),
      quotaPerDay: json['quota_per_day'],
      message: json['message'] ?? '',
    );
  }

  /// Parse progress steps list.
  static List<ConfigProgressStep> _parseProgressSteps(dynamic json) {
    if (json == null || json is! List) return [];
    return json
        .map(
          (e) => ConfigProgressStep(
            id: e['id']?.toString() ?? '',
            stepOrder: e['step_order'] ?? 0,
            title: e['title'] ?? '',
          ),
        )
        .toList();
  }

  /// Parse officials list.
  static List<Official> _parseOfficials(dynamic json) {
    if (json == null || json is! List) return [];
    return json
        .map(
          (e) => Official(
            id: e['id']?.toString() ?? '',
            name: e['name'] ?? '',
            role: e['role'] ?? '',
            attendanceStatus: e['attendance_status'] ?? '',
            isPresentToday: e['is_present_today'] ?? false,
          ),
        )
        .toList();
  }

  /// Parse availability status.
  static AvailabilityStatus _parseAvailabilityStatus(dynamic json) {
    if (json == null) {
      return const AvailabilityStatus(
        available: false,
        reason: 'Unknown',
        reasonCode: 'UNKNOWN',
      );
    }
    return AvailabilityStatus(
      available: json['available'] ?? false,
      reason: json['reason'] ?? '',
      reasonCode: json['reason_code'] ?? '',
    );
  }
}
