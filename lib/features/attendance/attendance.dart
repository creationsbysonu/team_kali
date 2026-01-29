// Attendance Management Feature - Barrel Export
// Ministry Admin manages staff and official attendance

// Entities
export 'domain/entities/attendance_record.dart';
export 'domain/entities/attendance_calendar_data.dart'
    show AttendanceCalendarData;

// Repositories
export 'domain/repositories/attendance_repository.dart';

// Use Cases
export 'domain/usecases/get_attendance_calendar_usecase.dart';
export 'domain/usecases/mark_attendance_usecase.dart';
export 'domain/usecases/bulk_mark_attendance_usecase.dart';

// Pages
export 'presentation/pages/attendance_management_page.dart';
export 'presentation/pages/view_attendance_page.dart';
export 'presentation/pages/mark_attendance_page.dart';
