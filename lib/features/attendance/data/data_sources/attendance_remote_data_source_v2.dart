import 'package:intl/intl.dart';
import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/network/api_client.dart';
import 'package:sewa_web/features/attendance/data/models/attendance_record_model.dart';
import 'package:sewa_web/features/attendance/data/models/holiday_model.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_record.dart';
import 'package:sewa_web/features/attendance/domain/entities/holiday.dart';

/// Remote data source for attendance operations
abstract class AttendanceRemoteDataSource {
  /// Get list of persons (staff or officials)
  Future<List<Map<String, String>>> getPersons({
    required String personType,
    String? ministryId,
  });

  /// Get holidays for a specific month
  Future<List<Holiday>> getHolidays({required int year, required int month});

  /// Get absence records for a person in a date range
  Future<List<AttendanceRecordModel>> getAbsenceRecords({
    required String personType,
    required String personId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Mark a single day as absent
  Future<AttendanceRecordModel> markAbsent({
    required String personType,
    required String personId,
    required DateTime date,
    required String reason,
  });

  /// Remove an absence record (returns to present)
  Future<void> removeAbsence({required String recordId});

  /// Get cached person name
  String getPersonName(String personId);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final ApiClient apiClient;
  final Map<String, String> _personNamesCache = {};

  AttendanceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<Map<String, String>>> getPersons({
    required String personType,
    String? ministryId,
  }) async {
    String endpoint;
    if (personType.toUpperCase() == 'STAFF') {
      endpoint = ApiEndpoints.ministryStaffServices;
    } else {
      endpoint = ApiEndpoints.officialsList(
        ministryId: ministryId,
        isActive: true,
      );
    }

    final responseData = await apiClient.get(endpoint);

    if (responseData['success'] != true) {
      throw ServerException(
        message: responseData['error'] ?? 'Failed to fetch persons',
      );
    }

    final data = responseData['data'] as List;
    return data.map<Map<String, String>>((item) {
      String displayName;
      String? imageUrl;

      if (personType.toUpperCase() == 'STAFF') {
        displayName =
            item['staff_name']?.toString() ??
            item['name']?.toString() ??
            'Unknown';
        // Try multiple possible image keys from backend
        imageUrl =
            item['staff_image']?.toString() ??
            item['image_url']?.toString() ??
            item['profile_picture']?.toString() ??
            item['profile_image']?.toString() ??
            item['image']?.toString();
      } else {
        displayName = item['name']?.toString() ?? 'Unknown';
        imageUrl =
            item['image_url']?.toString() ??
            item['profile_picture']?.toString() ??
            item['profile_image']?.toString() ??
            item['image']?.toString();
      }

      final personId = item['id'].toString();
      _personNamesCache[personId] = displayName;

      return {'id': personId, 'name': displayName, 'image': imageUrl ?? ''};
    }).toList();
  }

  @override
  Future<List<Holiday>> getHolidays({
    required int year,
    required int month,
  }) async {
    try {
      // Use correct API endpoint
      final endpoint = ApiEndpoints.holidaysList(year: year, month: month);
      final responseData = await apiClient.get(endpoint);

      if (responseData['success'] != true) {
        // If holidays endpoint fails, return empty list (not critical)
        return [];
      }

      final data = responseData['data'] as List;
      return data.map((json) => HolidayModel.fromJson(json)).toList();
    } catch (e) {
      // Holidays are not critical, return empty list on any error
      return [];
    }
  }

  @override
  Future<List<AttendanceRecordModel>> getAbsenceRecords({
    required String personType,
    required String personId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final responseData = await apiClient.get(
      ApiEndpoints.attendanceCalendar(
        personType: personType,
        personId: personId,
        startDate: dateFormat.format(startDate),
        endDate: dateFormat.format(endDate),
      ),
    );

    if (responseData['success'] != true) {
      throw ServerException(
        message: responseData['error'] ?? 'Failed to fetch attendance',
      );
    }

    // Backend returns only ABSENCE records
    final recordsList = responseData['data'] as List;

    return recordsList
        .where((record) => record['status'] == 'ABSENT')
        .map<AttendanceRecordModel>((record) {
          return AttendanceRecordModel(
            id: record['id']?.toString() ?? DateTime.now().toString(),
            personType: PersonType.fromString(personType),
            personId: personId,
            personName: _personNamesCache[personId] ?? 'Unknown',
            personEmail: null,
            date: DateTime.parse(record['date']),
            status: AttendanceStatus.absent,
            reason: record['reason']?.toString(),
            isSaturday: record['is_saturday'] == true,
            createdAt: record['created_at'] != null
                ? DateTime.parse(record['created_at'])
                : DateTime.now(),
            updatedAt: record['updated_at'] != null
                ? DateTime.parse(record['updated_at'])
                : DateTime.now(),
          );
        })
        .toList();
  }

  @override
  Future<AttendanceRecordModel> markAbsent({
    required String personType,
    required String personId,
    required DateTime date,
    required String reason,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd');

    // Build payload - backend requires person_type AND the specific field
    final Map<String, dynamic> payload = {
      'person_type': personType.toUpperCase(),
      'date': dateFormat.format(date),
      'status': 'ABSENT',
      'reason': reason,
    };

    // Also add the specific ID field based on person type
    if (personType.toUpperCase() == 'STAFF') {
      payload['staff'] = personId;
    } else {
      payload['official'] = personId;
    }

    final responseData = await apiClient.post(
      ApiEndpoints.attendanceMark,
      data: payload,
    );

    if (responseData['success'] != true) {
      throw ServerException(
        message: responseData['error'] ?? 'Failed to mark absent',
      );
    }

    final data = responseData['data'];
    return AttendanceRecordModel(
      id:
          data['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      personType: PersonType.fromString(personType),
      personId: personId,
      personName: _personNamesCache[personId] ?? 'Unknown',
      personEmail: null,
      date: data['date'] != null ? DateTime.parse(data['date']) : date,
      status: AttendanceStatus.absent,
      reason: data['reason']?.toString(),
      isSaturday: data['is_saturday'] == true,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : DateTime.now(),
    );
  }

  @override
  Future<void> removeAbsence({required String recordId}) async {
    // Check if there's a DELETE endpoint for attendance
    final responseData = await apiClient.post(
      '/attendance/delete/$recordId/',
      data: {},
    );

    if (responseData['success'] != true) {
      throw ServerException(
        message: responseData['error'] ?? 'Failed to remove absence',
      );
    }
  }

  /// Helper to get cached person name
  @override
  String getPersonName(String personId) {
    return _personNamesCache[personId] ?? 'Unknown Person';
  }
}
