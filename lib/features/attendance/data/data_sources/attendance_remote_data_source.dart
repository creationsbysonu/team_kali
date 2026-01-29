import 'package:intl/intl.dart';
import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/network/api_client.dart';
import 'package:sewa_web/features/attendance/data/models/attendance_record_model.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_calendar_data.dart';
import 'package:sewa_web/features/attendance/domain/entities/attendance_record.dart';

abstract class AttendanceRemoteDataSource {
  Future<List<Map<String, String>>> getPersons({
    required String personType,
    String? ministryId,
  });

  Future<AttendanceCalendarData> getAttendanceCalendar({
    required String personType,
    required String personId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<AttendanceRecordModel> markAttendance({
    required String personType,
    required String personId,
    required DateTime date,
    required String status,
    String? reason,
  });

  Future<List<AttendanceRecordModel>> bulkMarkAttendance({
    required List<Map<String, dynamic>> attendanceData,
  });
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
    final persons = data.map<Map<String, String>>((item) {
      String displayName;

      // For STAFF, use staff_name; for OFFICIAL, use name
      if (personType.toUpperCase() == 'STAFF') {
        displayName =
            item['staff_name']?.toString() ??
            item['name']?.toString() ??
            'Unknown';
      } else {
        displayName = item['name']?.toString() ?? 'Unknown';
      }

      final personId = item['id'].toString();

      // Cache the name for later use
      _personNamesCache[personId] = displayName;

      return {'id': personId, 'name': displayName};
    }).toList();

    return persons;
  }

  @override
  Future<AttendanceCalendarData> getAttendanceCalendar({
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
        message: responseData['error'] ?? 'Failed to fetch attendance calendar',
      );
    }

    // Backend returns data as a direct array of records
    final recordsList = responseData['data'] as List;

    final records = recordsList.map<AttendanceRecordModel>((record) {
      // Manually create model with person context since backend doesn't include it
      return AttendanceRecordModel(
        id:
            record['id']?.toString() ??
            '${personId}_${record['date']}_${DateTime.now().millisecondsSinceEpoch}',
        personType: PersonType.fromString(personType),
        personId: personId,
        personName: _getPersonNameFromId(personId),
        personEmail: null,
        date: DateTime.parse(record['date']),
        status: AttendanceStatus.fromString(record['status']),
        reason: record['reason']?.toString().isEmpty == true
            ? null
            : record['reason']?.toString(),
        isSaturday: record['is_saturday'] == true,
        createdAt: record['created_at'] != null
            ? DateTime.parse(record['created_at'])
            : DateTime.now(),
        updatedAt: record['updated_at'] != null
            ? DateTime.parse(record['updated_at'])
            : DateTime.now(),
      );
    }).toList();

    // Calculate statistics from records
    final totalDays = records.length;
    final presentDays = records
        .where((r) => r.status == AttendanceStatus.present)
        .length;
    final absentDays = totalDays - presentDays;
    final attendancePercentage = totalDays > 0
        ? (presentDays / totalDays) * 100
        : 0.0;

    return AttendanceCalendarData(
      personId: personId,
      personName: _getPersonNameFromId(personId), // We'll get this from cache
      personType: PersonType.fromString(personType),
      startDate: startDate,
      endDate: endDate,
      records: records,
      totalDays: totalDays,
      presentDays: presentDays,
      absentDays: absentDays,
      attendancePercentage: attendancePercentage,
    );
  }

  String _getPersonNameFromId(String personId) {
    return _personNamesCache[personId] ?? 'Unknown Person';
  }

  @override
  Future<AttendanceRecordModel> markAttendance({
    required String personType,
    required String personId,
    required DateTime date,
    required String status,
    String? reason,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final responseData = await apiClient.post(
      ApiEndpoints.attendanceMark,
      data: {
        'person_type': personType,
        'person_id': personId,
        'date': dateFormat.format(date),
        'status': status,
        if (reason != null) 'reason': reason,
      },
    );

    if (responseData['success'] != true) {
      throw ServerException(
        message: responseData['error'] ?? 'Failed to mark attendance',
      );
    }

    return AttendanceRecordModel.fromJson(responseData['data']);
  }

  @override
  Future<List<AttendanceRecordModel>> bulkMarkAttendance({
    required List<Map<String, dynamic>> attendanceData,
  }) async {
    final responseData = await apiClient.post(
      ApiEndpoints.attendanceBulkMark,
      data: {'attendance_records': attendanceData},
    );

    if (responseData['success'] != true) {
      throw ServerException(
        message: responseData['error'] ?? 'Failed to bulk mark attendance',
      );
    }

    return (responseData['data'] as List)
        .map((record) => AttendanceRecordModel.fromJson(record))
        .toList();
  }
}
