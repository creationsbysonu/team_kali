import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sewa_web/core/auth/token_manager.dart';
import 'package:sewa_web/core/network/api_client.dart';
import 'package:sewa_web/core/network/network_info.dart';
import 'package:sewa_web/core/routes/dashboard_router_observer.dart';
import 'package:sewa_web/core/service/navigation_service.dart';
import 'package:sewa_web/core/widget/dashboard_side_bar.dart';
import 'package:sewa_web/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:sewa_web/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:sewa_web/features/auth/data/data_sources/public_ministry_data_source.dart';
import 'package:sewa_web/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sewa_web/features/auth/data/repositories/public_ministry_repository_impl.dart';
import 'package:sewa_web/features/auth/domain/repositories/auth_repository.dart';
import 'package:sewa_web/features/auth/domain/repositories/public_ministry_repository.dart';
import 'package:sewa_web/features/auth/domain/usecase/get_current_user_usecase.dart';
import 'package:sewa_web/features/auth/domain/usecase/get_public_ministries_usecase.dart';
import 'package:sewa_web/features/auth/domain/usecase/login_usecase.dart';
import 'package:sewa_web/features/auth/domain/usecase/logout_usecase.dart';
import 'package:sewa_web/features/auth/domain/usecase/validate_token_usecase.dart';
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_web/features/auth/presentation/bloc/ministry_list_bloc.dart';
import 'package:sewa_web/features/ministry/data/data_sources/staff_service_remote_data_source.dart';
import 'package:sewa_web/features/ministry/data/repositories/staff_service_repository_impl.dart';
import 'package:sewa_web/features/ministry/domain/repositories/staff_service_repository.dart';
import 'package:sewa_web/features/ministry/domain/usecases/create_staff_service_usecase.dart';
import 'package:sewa_web/features/ministry/domain/usecases/delete_staff_service_usecase.dart';
import 'package:sewa_web/features/ministry/domain/usecases/get_staff_services_usecase.dart';
import 'package:sewa_web/features/ministry/domain/usecases/reset_staff_password_usecase.dart';
import 'package:sewa_web/features/ministry/domain/usecases/toggle_staff_service_status_usecase.dart';
import 'package:sewa_web/features/ministry/domain/usecases/update_staff_service_usecase.dart';
import 'package:sewa_web/features/ministry/presentation/bloc/staff_service_bloc.dart';
import 'package:sewa_web/features/places/places.dart';
import 'package:sewa_web/features/staff/presentation/bloc/staff_dashboard_bloc.dart';
import 'package:sewa_web/features/staff/presentation/bloc/staff_services_bloc.dart';
import 'package:sewa_web/features/super_admin/super_admin.dart';
// Officials feature
import 'package:sewa_web/features/officials/data/data_sources/officials_remote_data_source.dart';
import 'package:sewa_web/features/officials/data/repositories/officials_repository_impl.dart';
import 'package:sewa_web/features/officials/domain/repositories/officials_repository.dart';
import 'package:sewa_web/features/officials/domain/usecases/officials_usecases.dart';
import 'package:sewa_web/features/officials/presentation/bloc/officials_bloc.dart';
// Holidays feature
import 'package:sewa_web/features/holidays/data/data_sources/holidays_remote_data_source.dart';
import 'package:sewa_web/features/holidays/data/repositories/holidays_repository_impl.dart';
import 'package:sewa_web/features/holidays/domain/repositories/holidays_repository.dart';
import 'package:sewa_web/features/holidays/domain/usecases/holidays_usecases.dart';
// Attendance Calendar feature
import 'package:sewa_web/features/attendance/data/data_sources/attendance_remote_data_source_v2.dart'
    as v2;
import 'package:sewa_web/features/attendance/presentation/bloc/attendance_calendar_bloc.dart';
import 'package:sewa_web/features/holidays/presentation/bloc/holidays_bloc.dart';
// Queue Management feature
import 'package:sewa_web/features/queue_management/data/data_sources/queue_config_remote_data_source.dart';
import 'package:sewa_web/features/queue_management/data/repositories/queue_config_repository_impl.dart';
import 'package:sewa_web/features/queue_management/domain/repositories/queue_config_repository.dart';
import 'package:sewa_web/features/queue_management/domain/usecases/queue_config_usecases.dart';
import 'package:sewa_web/features/queue_management/presentation/bloc/queue_config_bloc.dart';
// Attendance feature
import 'package:sewa_web/features/attendance/data/data_sources/attendance_remote_data_source.dart';
import 'package:sewa_web/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:sewa_web/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:sewa_web/features/attendance/domain/usecases/attendance_usecases.dart';
import 'package:sewa_web/features/attendance/presentation/bloc/attendance_bloc.dart';
// Staff Queue feature (New System)
import 'package:sewa_web/features/staff_queue/data/data_sources/staff_queue_data_source.dart';
import 'package:sewa_web/features/staff_queue/data/repositories/staff_queue_repository_impl.dart';
import 'package:sewa_web/features/staff_queue/domain/repositories/staff_queue_repository.dart';
import 'package:sewa_web/features/staff_queue/domain/usecases/new_queue_usecases.dart';
import 'package:sewa_web/features/staff_queue/presentation/bloc/staff_panel_bloc.dart';
// Notice feature
import 'package:sewa_web/features/notice/notice.dart';

final sl = GetIt.instance;
final navigatorKey = GlobalKey<NavigatorState>();

/// Initialize all dependencies for the Sewa Sathi Government Web Admin
Future<void> init() async {
  // Core services that don't depend on other services
  await _initCoreServices();
  // Auth components
  await _initAuth();
  // Places feature
  _initPlacesFeature();
  // Ministry management feature
  _initMinistryFeature();
  // Officials feature
  _initOfficialsFeature();
  // Holidays feature
  _initHolidaysFeature();
  // Queue Management feature
  _initQueueManagementFeature();
  // Attendance feature
  _initAttendanceFeature();
  // Staff Queue feature
  _initStaffQueueFeature();
  // Notice feature
  _initNoticeFeature();
}

Future<void> _initCoreServices() async {
  // Navigator key for global navigation
  sl.registerLazySingleton<GlobalKey<NavigatorState>>(
    () => GlobalKey<NavigatorState>(),
  );
  sl.registerLazySingleton(() => NavigationController());
  sl.registerLazySingleton(() => NavigationService());
  sl.registerLazySingleton(() => DashboardRouterObserver(sl()));

  // Shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Dio HTTP client
  sl.registerLazySingleton(() => Dio());

  // Connectivity
  sl.registerLazySingleton(() => Connectivity());

  // Network info
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Auth local data source (needed by TokenManager)
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Token Manager
  final tokenManager = TokenManager(localDataSource: sl<AuthLocalDataSource>());
  sl.registerSingleton<TokenManager>(tokenManager);

  // API Client
  final apiClient = ApiClient(
    dio: sl(),
    tokenManager: tokenManager,
    getMinistryId: () => sl<AuthLocalDataSource>().getMinistryId(),
    onAuthenticationFailed: () {
      // Trigger logout event through BLoC
      if (sl.isRegistered<AuthBloc>()) {
        sl<AuthBloc>().add(LogoutEvent());
      }
    },
  );
  sl.registerSingleton<ApiClient>(apiClient);
}

Future<void> _initAuth() async {
  // Remote data source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl(), tokenManager: sl()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      tokenManager: sl(),
    ),
  );

  // Use Cases - register each individually
  sl.registerLazySingleton(() => GetCurrentUserUsecase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => ValidateTokenUseCase(sl()));

  // Public Ministry Data Source (NO AUTH - for login dropdown)
  sl.registerLazySingleton<PublicMinistryDataSource>(
    () => PublicMinistryDataSourceImpl(),
  );

  // Public Ministry Repository
  sl.registerLazySingleton<PublicMinistryRepository>(
    () => PublicMinistryRepositoryImpl(publicMinistryDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetPublicMinistriesUseCase(sl()));

  // Auth BLoC
  sl.registerFactory(
    () => AuthBloc(
      getCurrentUser: sl(),
      login: sl(),
      logout: sl(),
      validateToken: sl(),
      tokenManager: sl(),
    ),
  );

  // Ministry List BLoC (for ministry selection in login flow)
  sl.registerFactory(() => MinistryListBloc(publicMinistryRepository: sl()));

  // Staff Services BLoC (for service selection in staff login flow)
  sl.registerFactory(
    () => StaffServicesBloc(apiClient: sl(), networkInfo: sl()),
  );
}

/// Initialize Ministry feature dependencies
void _initMinistryFeature() {
  // Data sources
  sl.registerLazySingleton<MinistryRemoteDataSource>(
    () => MinistryRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<MinistryRepository>(
    () => MinistryRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases - Super Admin Ministry Management
  sl.registerLazySingleton(() => GetAdminMinistriesUseCase(sl()));
  sl.registerLazySingleton(() => GetDeletedMinistriesUseCase(sl()));
  sl.registerLazySingleton(() => GetPlacesForFilterUseCase(sl()));
  sl.registerLazySingleton(() => GetMinistryByIdUseCase(sl()));
  sl.registerLazySingleton(() => CreateMinistryUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMinistryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMinistryUseCase(sl()));
  sl.registerLazySingleton(() => ActivateMinistryUseCase(sl()));
  sl.registerLazySingleton(() => SuspendMinistryUseCase(sl()));
  sl.registerLazySingleton(() => RestoreMinistryUseCase(sl()));
  sl.registerLazySingleton(() => HardDeleteMinistryUseCase(sl()));
  sl.registerLazySingleton(() => ResetMinistryPasswordUseCase(sl()));

  // Use Cases - Ministry Self Management
  sl.registerLazySingleton(() => GetMyMinistryUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMyMinistryUseCase(sl()));

  // BLoC - Ministry Management (Singleton to prevent multiple API calls)
  sl.registerLazySingleton(
    () => MinistryBloc(
      getAdminMinistries: sl(),
      getDeletedMinistries: sl(),
      getPlacesForFilter: sl(),
      createMinistry: sl(),
      updateMinistry: sl(),
      activateMinistry: sl(),
      suspendMinistry: sl(),
      deleteMinistry: sl(),
      restoreMinistry: sl(),
      hardDeleteMinistry: sl(),
      resetMinistryPassword: sl(),
    ),
  );

  // === Staff Service (Ministry Admin) ===
  // Data sources
  sl.registerLazySingleton<StaffServiceRemoteDataSource>(
    () => StaffServiceRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<StaffServiceRepository>(
    () => StaffServiceRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetStaffServicesUseCase(sl()));
  sl.registerLazySingleton(() => CreateStaffServiceUseCase(sl()));
  sl.registerLazySingleton(() => UpdateStaffServiceUseCase(sl()));
  sl.registerLazySingleton(() => DeleteStaffServiceUseCase(sl()));
  sl.registerLazySingleton(() => ResetStaffPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ToggleStaffServiceStatusUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => StaffServiceBloc(
      getStaffServices: sl(),
      createStaffService: sl(),
      updateStaffService: sl(),
      deleteStaffService: sl(),
      resetStaffPassword: sl(),
      toggleStaffServiceStatus: sl(),
    ),
  );

  // === Staff Dashboard (Staff Admin) ===
  // BLoC
  sl.registerFactory(() => StaffDashboardBloc());
}

/// Initialize Places feature dependencies
void _initPlacesFeature() {
  // Data sources
  sl.registerLazySingleton<PlaceRemoteDataSource>(
    () => PlaceRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<PlaceRepository>(
    () => PlaceRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetPublicPlacesUseCase(sl()));
  sl.registerLazySingleton(() => GetPlaceBySlugUseCase(sl()));
  sl.registerLazySingleton(() => GetAllPlacesUseCase(sl()));
  sl.registerLazySingleton(() => CreatePlaceUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePlaceUseCase(sl()));
  sl.registerLazySingleton(() => DeletePlaceUseCase(sl()));

  // BLoC - Place Management (Singleton to prevent multiple API calls)
  sl.registerLazySingleton(
    () => PlaceBloc(
      getPublicPlaces: sl(),
      getAllPlaces: sl(),
      createPlace: sl(),
      updatePlace: sl(),
      deletePlace: sl(),
    ),
  );
}

/// Initialize Officials feature dependencies
void _initOfficialsFeature() {
  // Data sources
  sl.registerLazySingleton<OfficialsRemoteDataSource>(
    () => OfficialsRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<OfficialsRepository>(
    () => OfficialsRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetOfficialsUseCase(sl()));
  sl.registerLazySingleton(() => GetOfficialByIdUseCase(sl()));
  sl.registerLazySingleton(() => CreateOfficialUseCase(sl()));
  sl.registerLazySingleton(() => UpdateOfficialUseCase(sl()));
  sl.registerLazySingleton(() => DeleteOfficialUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => OfficialsBloc(
      getOfficials: sl(),
      getOfficialById: sl(),
      createOfficial: sl(),
      updateOfficial: sl(),
      deleteOfficial: sl(),
    ),
  );
}

/// Initialize Holidays feature dependencies
void _initHolidaysFeature() {
  // Data sources
  sl.registerLazySingleton<HolidaysRemoteDataSource>(
    () => HolidaysRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<HolidaysRepository>(
    () => HolidaysRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetHolidaysUseCase(sl()));
  sl.registerLazySingleton(() => CreateHolidayUseCase(sl()));
  sl.registerLazySingleton(() => UpdateHolidayUseCase(sl()));
  sl.registerLazySingleton(() => DeleteHolidayUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => HolidaysBloc(
      getHolidays: sl(),
      createHoliday: sl(),
      updateHoliday: sl(),
      deleteHoliday: sl(),
    ),
  );
}

/// Initialize Queue Management feature dependencies
void _initQueueManagementFeature() {
  // Data sources
  sl.registerLazySingleton<QueueConfigRemoteDataSource>(
    () => QueueConfigRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<QueueConfigRepository>(
    () => QueueConfigRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetAllServicesWithConfigsUseCase(sl()));
  sl.registerLazySingleton(() => GetConfigByServiceUseCase(sl()));
  sl.registerLazySingleton(() => CreateQueueConfigUseCase(sl()));
  sl.registerLazySingleton(() => UpdateQueueConfigUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => QueueConfigBloc(
      getAllServicesWithConfigs: sl(),
      getConfigByService: sl(),
      createConfig: sl(),
      updateConfig: sl(),
    ),
  );
}

/// Initialize Attendance feature dependencies
void _initAttendanceFeature() {
  // Data sources
  sl.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetPersonsUseCase(sl()));
  sl.registerLazySingleton(() => GetAttendanceCalendarUseCase(sl()));
  sl.registerLazySingleton(() => MarkAttendanceUseCase(sl()));
  sl.registerLazySingleton(() => BulkMarkAttendanceUseCase(sl()));

  // BLoC (Old - Keep for backward compatibility)
  sl.registerFactory(
    () => AttendanceBloc(
      getPersons: sl(),
      getAttendanceCalendar: sl(),
      markAttendance: sl(),
      bulkMarkAttendance: sl(),
    ),
  );

  // New Attendance Calendar BLoC
  sl.registerLazySingleton<v2.AttendanceRemoteDataSource>(
    () => v2.AttendanceRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerFactory(
    () => AttendanceCalendarBloc(
      remoteDataSource: sl<v2.AttendanceRemoteDataSource>(),
    ),
  );
}

/// Initialize Staff Queue feature dependencies (New Queue System)
void _initStaffQueueFeature() {
  // Data sources
  sl.registerLazySingleton<StaffQueueRemoteDataSource>(
    () => StaffQueueRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<StaffQueueRepository>(
    () => StaffQueueRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases (New Queue System)
  sl.registerLazySingleton(() => GetActiveTokensUseCase(sl()));
  sl.registerLazySingleton(() => GetAllTokensUseCase(sl()));
  sl.registerLazySingleton(() => GetPendingTokensUseCase(sl()));
  sl.registerLazySingleton(() => StartServiceUseCase(sl()));
  sl.registerLazySingleton(() => MarkNoShowUseCase(sl()));
  sl.registerLazySingleton(() => MarkPendingUseCase(sl()));
  sl.registerLazySingleton(() => SendPendingEmailUseCase(sl()));
  sl.registerLazySingleton(() => MarkPendingServedUseCase(sl()));

  // BLoC - Staff Panel (New Queue System with 3 tabs)
  sl.registerFactory(
    () => StaffPanelBloc(
      getActiveTokens: sl(),
      getAllTokens: sl(),
      getPendingTokens: sl(),
      startService: sl(),
      markNoShow: sl(),
      markPending: sl(),
      sendPendingEmail: sl(),
      markPendingServed: sl(),
    ),
  );
}

/// Initialize Notice feature dependencies
void _initNoticeFeature() {
  // Data sources
  sl.registerLazySingleton<NoticeRemoteDataSource>(
    () => NoticeRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<NoticeRepository>(
    () => NoticeRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetNoticesUseCase(sl()));
  sl.registerLazySingleton(() => GetNoticeByIdUseCase(sl()));
  sl.registerLazySingleton(() => UploadNoticeUseCase(sl()));
  sl.registerLazySingleton(() => UpdateNoticeUseCase(sl()));
  sl.registerLazySingleton(() => DeleteNoticeUseCase(sl()));
  sl.registerLazySingleton(() => GetNoticeStatsUseCase(sl()));
  sl.registerLazySingleton(() => RetryIngestionUseCase(sl()));
  sl.registerLazySingleton(() => GetNoticeServicesUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => NoticeBloc(
      getNotices: sl(),
      getNoticeById: sl(),
      uploadNotice: sl(),
      updateNotice: sl(),
      deleteNotice: sl(),
      getNoticeStats: sl(),
      retryIngestion: sl(),
      getNoticeServices: sl(),
    ),
  );
}
