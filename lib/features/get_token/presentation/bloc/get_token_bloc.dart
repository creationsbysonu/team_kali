import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/get_token_entities.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/paginated_response.dart';
import 'package:sewa_sathi/features/get_token/domain/usecases/get_token_usecases.dart';

part 'get_token_event.dart';
part 'get_token_state.dart';

/// BLoC for managing Get Token feature state.
/// Supports cursor-based pagination following Citizen API v1.
class GetTokenBloc extends Bloc<GetTokenEvent, GetTokenState> {
  final GetMinistriesUseCase getMinistriesUseCase;
  final GetServicesUseCase getServicesUseCase;
  final GetServiceDetailsUseCase getServiceDetailsUseCase;
  final BookTokenUseCase bookTokenUseCase;
  final GetMyTokensUseCase getMyTokensUseCase;
  final CancelTokenUseCase cancelTokenUseCase;

  /// Store current config for booking
  QueueConfigEntity? _currentConfig;

  /// Pagination state tracking
  String? _ministriesCursor;
  bool _ministriesHasMore = false;
  String? _currentPlaceId;
  int _ministriesPageSize = 20;

  String? _servicesCursor;
  bool _servicesHasMore = false;
  String? _currentMinistryId;
  int _servicesPageSize = 20;

  String? _tokensCursor;
  bool _tokensHasMore = false;
  String? _currentTokensStatus;
  int _tokensPageSize = 20;

  GetTokenBloc({
    required this.getMinistriesUseCase,
    required this.getServicesUseCase,
    required this.getServiceDetailsUseCase,
    required this.bookTokenUseCase,
    required this.getMyTokensUseCase,
    required this.cancelTokenUseCase,
  }) : super(GetTokenInitial()) {
    on<LoadMinistriesEvent>(_onLoadMinistries);
    on<LoadMoreMinistriesEvent>(_onLoadMoreMinistries);
    on<LoadServicesEvent>(_onLoadServices);
    on<LoadMoreServicesEvent>(_onLoadMoreServices);
    on<LoadServiceDetailsEvent>(_onLoadServiceDetails);
    on<BookTokenEvent>(_onBookToken);
    on<LoadMyTokensEvent>(_onLoadMyTokens);
    on<LoadMoreMyTokensEvent>(_onLoadMoreMyTokens);
    on<CancelTokenEvent>(_onCancelToken);
    on<ResetGetTokenEvent>(_onReset);
  }

  Future<void> _onLoadMinistries(
    LoadMinistriesEvent event,
    Emitter<GetTokenState> emit,
  ) async {
    emit(const GetTokenLoading(message: 'Loading ministries...'));

    // Reset pagination state for new load
    _currentPlaceId = event.placeId;
    _ministriesPageSize = event.pageSize;
    _ministriesCursor = null;

    final result = await getMinistriesUseCase(
      GetMinistriesParams(placeId: event.placeId, pageSize: event.pageSize),
    );

    result.fold((failure) => emit(GetTokenError(message: failure.message)), (
      response,
    ) {
      _ministriesCursor = response.nextCursor;
      _ministriesHasMore = response.hasMore;
      emit(
        MinistriesLoaded(
          ministries: response.items,
          placeId: event.placeId,
          placeInfo: response.place,
          nextCursor: response.nextCursor,
          hasMore: response.hasMore,
          totalEstimate: response.totalEstimate,
        ),
      );
    });
  }

  Future<void> _onLoadMoreMinistries(
    LoadMoreMinistriesEvent event,
    Emitter<GetTokenState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MinistriesLoaded ||
        !_ministriesHasMore ||
        currentState.isLoadingMore ||
        _currentPlaceId == null) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await getMinistriesUseCase(
      GetMinistriesParams(
        placeId: _currentPlaceId!,
        cursor: _ministriesCursor,
        pageSize: _ministriesPageSize,
      ),
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
        debugPrint('❌ Failed to load more ministries: ${failure.message}');
      },
      (response) {
        _ministriesCursor = response.nextCursor;
        _ministriesHasMore = response.hasMore;
        emit(
          currentState.copyWith(
            ministries: [...currentState.ministries, ...response.items],
            nextCursor: response.nextCursor,
            hasMore: response.hasMore,
            totalEstimate: response.totalEstimate,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  Future<void> _onLoadServices(
    LoadServicesEvent event,
    Emitter<GetTokenState> emit,
  ) async {
    emit(const GetTokenLoading(message: 'Loading services...'));

    // Reset pagination state for new load
    _currentMinistryId = event.ministryId;
    _servicesPageSize = event.pageSize;
    _servicesCursor = null;

    final result = await getServicesUseCase(
      GetServicesParams(ministryId: event.ministryId, pageSize: event.pageSize),
    );

    result.fold((failure) => emit(GetTokenError(message: failure.message)), (
      response,
    ) {
      _servicesCursor = response.nextCursor;
      _servicesHasMore = response.hasMore;
      emit(
        ServicesLoaded(
          services: response.items,
          ministryId: event.ministryId,
          ministryName: event.ministryName,
          ministryInfo: response.ministry,
          nextCursor: response.nextCursor,
          hasMore: response.hasMore,
          totalEstimate: response.totalEstimate,
        ),
      );
    });
  }

  Future<void> _onLoadMoreServices(
    LoadMoreServicesEvent event,
    Emitter<GetTokenState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ServicesLoaded ||
        !_servicesHasMore ||
        currentState.isLoadingMore ||
        _currentMinistryId == null) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await getServicesUseCase(
      GetServicesParams(
        ministryId: _currentMinistryId!,
        cursor: _servicesCursor,
        pageSize: _servicesPageSize,
      ),
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
        debugPrint('❌ Failed to load more services: ${failure.message}');
      },
      (response) {
        _servicesCursor = response.nextCursor;
        _servicesHasMore = response.hasMore;
        emit(
          currentState.copyWith(
            services: [...currentState.services, ...response.items],
            nextCursor: response.nextCursor,
            hasMore: response.hasMore,
            totalEstimate: response.totalEstimate,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  Future<void> _onLoadServiceDetails(
    LoadServiceDetailsEvent event,
    Emitter<GetTokenState> emit,
  ) async {
    emit(const GetTokenLoading(message: 'Loading service details...'));

    final result = await getServiceDetailsUseCase(
      GetServiceDetailsParams(serviceId: event.serviceId),
    );

    result.fold((failure) => emit(GetTokenError(message: failure.message)), (
      details,
    ) {
      _currentConfig = details;
      emit(ServiceDetailsLoaded(details: details));
    });
  }

  Future<void> _onBookToken(
    BookTokenEvent event,
    Emitter<GetTokenState> emit,
  ) async {
    if (_currentConfig == null) {
      emit(const GetTokenError(message: 'Service details not loaded'));
      return;
    }

    emit(
      BookingInProgress(
        message: 'Booking your token...',
        config: _currentConfig!,
      ),
    );

    final result = await bookTokenUseCase(
      BookTokenParams(
        serviceId: event.serviceId,
        bookingType: event.bookingType,
        bookingDate: event.bookingDate,
      ),
    );

    result.fold((failure) => emit(GetTokenError(message: failure.message)), (
      token,
    ) {
      debugPrint('✅ Token booked: #${token.tokenNumber}');
      emit(TokenBooked(token: token));
    });
  }

  Future<void> _onLoadMyTokens(
    LoadMyTokensEvent event,
    Emitter<GetTokenState> emit,
  ) async {
    emit(const GetTokenLoading(message: 'Loading your tokens...'));

    // Reset pagination state for new load
    _currentTokensStatus = event.status;
    _tokensPageSize = event.pageSize;
    _tokensCursor = null;

    final result = await getMyTokensUseCase(
      GetMyTokensParams(status: event.status, pageSize: event.pageSize),
    );

    result.fold((failure) => emit(GetTokenError(message: failure.message)), (
      response,
    ) {
      _tokensCursor = response.nextCursor;
      _tokensHasMore = response.hasMore;
      emit(
        MyTokensLoaded(
          tokens: response.items,
          statusFilter: event.status,
          nextCursor: response.nextCursor,
          hasMore: response.hasMore,
          totalEstimate: response.totalEstimate,
        ),
      );
    });
  }

  Future<void> _onLoadMoreMyTokens(
    LoadMoreMyTokensEvent event,
    Emitter<GetTokenState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MyTokensLoaded ||
        !_tokensHasMore ||
        currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await getMyTokensUseCase(
      GetMyTokensParams(
        status: _currentTokensStatus,
        cursor: _tokensCursor,
        pageSize: _tokensPageSize,
      ),
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
        debugPrint('❌ Failed to load more tokens: ${failure.message}');
      },
      (response) {
        _tokensCursor = response.nextCursor;
        _tokensHasMore = response.hasMore;
        emit(
          currentState.copyWith(
            tokens: [...currentState.tokens, ...response.items],
            nextCursor: response.nextCursor,
            hasMore: response.hasMore,
            totalEstimate: response.totalEstimate,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  Future<void> _onCancelToken(
    CancelTokenEvent event,
    Emitter<GetTokenState> emit,
  ) async {
    emit(const GetTokenLoading(message: 'Cancelling token...'));

    final result = await cancelTokenUseCase(
      CancelTokenParams(tokenId: event.tokenId),
    );

    result.fold(
      (failure) => emit(GetTokenError(message: failure.message)),
      (_) => emit(TokenCancelled(tokenId: event.tokenId)),
    );
  }

  void _onReset(ResetGetTokenEvent event, Emitter<GetTokenState> emit) {
    // Reset all pagination state
    _ministriesCursor = null;
    _ministriesHasMore = false;
    _currentPlaceId = null;
    _servicesCursor = null;
    _servicesHasMore = false;
    _currentMinistryId = null;
    _tokensCursor = null;
    _tokensHasMore = false;
    _currentTokensStatus = null;
    emit(GetTokenInitial());
  }
}
