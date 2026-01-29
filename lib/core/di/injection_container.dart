import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:sewa_sathi/core/auth/token_manager.dart';
import 'package:sewa_sathi/core/network/api_client.dart';
import 'package:sewa_sathi/core/network/network_info.dart';
import 'package:sewa_sathi/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:sewa_sathi/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:sewa_sathi/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sewa_sathi/features/auth/domain/repositories/auth_repository.dart';
import 'package:sewa_sathi/features/auth/domain/usecases/auth_usecases.dart';
import 'package:sewa_sathi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_sathi/features/profile/data/data_sources/profile_local_data_source.dart';
import 'package:sewa_sathi/features/profile/data/data_sources/profile_remote_data_source.dart';
import 'package:sewa_sathi/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:sewa_sathi/features/profile/domain/repositories/profile_repository.dart';
import 'package:sewa_sathi/features/profile/domain/usecases/profile_usecases.dart';
import 'package:sewa_sathi/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:sewa_sathi/features/chat/data/data_sources/chat_remote_data_source.dart';
import 'package:sewa_sathi/features/chat/data/data_sources/chat_websocket_data_source.dart';
import 'package:sewa_sathi/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:sewa_sathi/features/chat/domain/repositories/chat_repository.dart';
import 'package:sewa_sathi/features/chat/domain/usecases/chat_usecases.dart';
import 'package:sewa_sathi/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:sewa_sathi/features/notice/data/data_sources/notice_remote_data_source.dart';
import 'package:sewa_sathi/features/notice/data/repositories/notice_repository_impl.dart';
import 'package:sewa_sathi/features/notice/domain/repositories/notice_repository.dart';
import 'package:sewa_sathi/features/notice/domain/usecases/notice_usecases.dart';
import 'package:sewa_sathi/features/notice/presentation/bloc/notice_bloc.dart';
import 'package:sewa_sathi/features/notice/presentation/bloc/notice_detail_bloc.dart';
import 'package:sewa_sathi/features/community/data/data_sources/community_local_data_source.dart';
import 'package:sewa_sathi/features/community/data/repositories/community_repository_impl.dart';
import 'package:sewa_sathi/features/community/data/services/moderation_service.dart';
import 'package:sewa_sathi/features/community/domain/repositories/community_repository.dart';
import 'package:sewa_sathi/features/community/domain/usecases/community_usecases.dart';
import 'package:sewa_sathi/features/community/presentation/bloc/feed_bloc.dart';
import 'package:sewa_sathi/features/community/presentation/bloc/create_post_bloc.dart';
import 'package:sewa_sathi/features/get_token/data/data_sources/get_token_remote_data_source.dart';
import 'package:sewa_sathi/features/get_token/data/repositories/get_token_repository_impl.dart';
import 'package:sewa_sathi/features/get_token/domain/repositories/get_token_repository.dart';
import 'package:sewa_sathi/features/get_token/domain/usecases/get_token_usecases.dart';
import 'package:sewa_sathi/features/get_token/presentation/bloc/get_token_bloc.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Initialize all dependencies.
Future<void> init() async {
  // Initialize in order of dependencies
  await _initCoreServices();
  await _initAuth(); // Sets up API client first
  _initProfile(); // Now can use API client
  _initChat();
  _initNotice();
  await _initCommunity(); // Initialize Hive for local storage
  _initGetToken();
}

/// Initialize core services.
Future<void> _initCoreServices() async {
  // External dependencies
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => Connectivity());

  // Network info
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
}

/// Initialize auth feature.
Future<void> _initAuth() async {
  // Data sources
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );

  // Token manager (needs to be created after local data source)
  final tokenManager = TokenManager(localDataSource: sl<AuthLocalDataSource>());
  sl.registerSingleton<TokenManager>(tokenManager);

  // API Client
  final apiClient = ApiClient(
    dio: sl<Dio>(),
    tokenManager: tokenManager,
    onAuthenticationFailed: () {
      // Clear tokens and trigger logout
      sl<AuthLocalDataSource>().clearAll();
    },
  );
  sl.registerSingleton<ApiClient>(apiClient);

  // Remote data source (needs API client)
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  // Set token refresh callback
  tokenManager.setRefreshCallback((refreshToken) async {
    try {
      final tokens = await sl<AuthRemoteDataSource>().refreshTokens(
        refreshToken,
      );
      return tokens;
    } catch (e) {
      return null;
    }
  });

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => RequestOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ResendOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl<AuthRepository>()));

  // BLoC - Registered as factory to create fresh instance
  // Note: CheckProfileStatusUseCase will be resolved when AuthBloc is first accessed
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      requestOtp: sl<RequestOtpUseCase>(),
      verifyOtp: sl<VerifyOtpUseCase>(),
      resendOtp: sl<ResendOtpUseCase>(),
      getProfile: sl<GetProfileUseCase>(),
      logout: sl<LogoutUseCase>(),
      checkAuthStatus: sl<CheckAuthStatusUseCase>(),
      checkProfileStatus: sl<CheckProfileStatusUseCase>(),
    ),
  );
}

/// Initialize profile feature.
void _initProfile() {
  // Data sources
  sl.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(secureStorage: sl()),
  );

  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: sl<ProfileRemoteDataSource>(),
      localDataSource: sl<ProfileLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(
    () => CheckProfileStatusUseCase(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton(() => GetPlacesUseCase(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => SetupProfileUseCase(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl<ProfileRepository>()));

  // BLoC
  sl.registerLazySingleton<ProfileBloc>(
    () => ProfileBloc(
      checkProfileStatus: sl<CheckProfileStatusUseCase>(),
      getPlaces: sl<GetPlacesUseCase>(),
      setupProfile: sl<SetupProfileUseCase>(),
      updateProfile: sl<UpdateProfileUseCase>(),
    ),
  );
}

/// Initialize chat feature.
void _initChat() {
  // Data sources - REST API (recommended for mobile)
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  // Data sources - WebSocket (optional for real-time)
  sl.registerLazySingleton<ChatWebSocketDataSource>(
    () => ChatWebSocketDataSourceImpl(),
  );

  // Repository - supports both REST and WebSocket
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      remoteDataSource: sl<ChatRemoteDataSource>(),
      webSocketDataSource: sl<ChatWebSocketDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SendChatMessageUseCase(sl<ChatRepository>()));
  sl.registerLazySingleton(() => ConnectChatUseCase(sl<ChatRepository>()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl<ChatRepository>()));
  sl.registerLazySingleton(() => DisconnectChatUseCase(sl<ChatRepository>()));

  // BLoC - uses REST API by default
  sl.registerFactory<ChatBloc>(
    () => ChatBloc(sendChatMessage: sl<SendChatMessageUseCase>()),
  );
}

/// Initialize notice feature.
void _initNotice() {
  // Data sources
  sl.registerLazySingleton<NoticeRemoteDataSource>(
    () => NoticeRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<NoticeRepository>(
    () => NoticeRepositoryImpl(
      remoteDataSource: sl<NoticeRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetNoticesUseCase(sl<NoticeRepository>()));
  sl.registerLazySingleton(
    () => GetNoticeDetailUseCase(sl<NoticeRepository>()),
  );
  sl.registerLazySingleton(
    () => GetFilterOptionsUseCase(sl<NoticeRepository>()),
  );

  // BLoC - NoticeBloc for list/filters
  sl.registerLazySingleton<NoticeBloc>(
    () => NoticeBloc(
      getNotices: sl<GetNoticesUseCase>(),
      getFilterOptions: sl<GetFilterOptionsUseCase>(),
    ),
  );

  // BLoC - NoticeDetailBloc for detail screen (factory for new instance each navigation)
  sl.registerFactory<NoticeDetailBloc>(
    () => NoticeDetailBloc(getNoticeDetail: sl<GetNoticeDetailUseCase>()),
  );
}

/// Initialize community feature (Issues & Ideas).
///
/// Hackathon MVP Architecture:
/// - All posts stored locally on device using Hive
/// - Only AI moderation server (port 8003) is used for image classification
/// - No backend API for CRUD operations
Future<void> _initCommunity() async {
  // Local data source (Hive) - must be initialized before use
  final localDataSource = CommunityLocalDataSourceImpl();
  await localDataSource.init();
  sl.registerLazySingleton<CommunityLocalDataSource>(() => localDataSource);

  // Services
  // ModerationService connects directly to AI server on port 8003
  sl.registerLazySingleton<ModerationService>(() => ModerationServiceImpl());

  // Repository (uses local storage, no network needed)
  sl.registerLazySingleton<CommunityRepository>(
    () => CommunityRepositoryImpl(
      localDataSource: sl<CommunityLocalDataSource>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetIssuesUseCase(sl<CommunityRepository>()));
  sl.registerLazySingleton(() => GetIdeasUseCase(sl<CommunityRepository>()));
  sl.registerLazySingleton(() => CreatePostUseCase(sl<CommunityRepository>()));
  sl.registerLazySingleton(() => VotePostUseCase(sl<CommunityRepository>()));

  // BLoCs
  sl.registerFactory<FeedBloc>(
    () => FeedBloc(
      getIssues: sl<GetIssuesUseCase>(),
      getIdeas: sl<GetIdeasUseCase>(),
      votePost: sl<VotePostUseCase>(),
    ),
  );

  sl.registerFactory<CreatePostBloc>(
    () => CreatePostBloc(
      createPost: sl<CreatePostUseCase>(),
      moderationService: sl<ModerationService>(),
    ),
  );
}

/// Initialize get token feature.
void _initGetToken() {
  // Data sources
  sl.registerLazySingleton<GetTokenRemoteDataSource>(
    () => GetTokenRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  // Repository
  sl.registerLazySingleton<GetTokenRepository>(
    () => GetTokenRepositoryImpl(
      remoteDataSource: sl<GetTokenRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(
    () => GetMinistriesUseCase(sl<GetTokenRepository>()),
  );
  sl.registerLazySingleton(() => GetServicesUseCase(sl<GetTokenRepository>()));
  sl.registerLazySingleton(
    () => GetServiceDetailsUseCase(sl<GetTokenRepository>()),
  );
  sl.registerLazySingleton(() => BookTokenUseCase(sl<GetTokenRepository>()));
  sl.registerLazySingleton(() => GetMyTokensUseCase(sl<GetTokenRepository>()));
  sl.registerLazySingleton(() => CancelTokenUseCase(sl<GetTokenRepository>()));

  // BLoC - factory to create fresh instance for each screen
  sl.registerFactory<GetTokenBloc>(
    () => GetTokenBloc(
      getMinistriesUseCase: sl<GetMinistriesUseCase>(),
      getServicesUseCase: sl<GetServicesUseCase>(),
      getServiceDetailsUseCase: sl<GetServiceDetailsUseCase>(),
      bookTokenUseCase: sl<BookTokenUseCase>(),
      getMyTokensUseCase: sl<GetMyTokensUseCase>(),
      cancelTokenUseCase: sl<CancelTokenUseCase>(),
    ),
  );
}
