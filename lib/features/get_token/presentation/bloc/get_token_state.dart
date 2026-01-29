part of 'get_token_bloc.dart';

/// Base state for GetToken feature.
abstract class GetTokenState extends Equatable {
  const GetTokenState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class GetTokenInitial extends GetTokenState {}

/// Loading state.
class GetTokenLoading extends GetTokenState {
  final String? message;

  const GetTokenLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Ministries loaded state with pagination support.
class MinistriesLoaded extends GetTokenState {
  final List<MinistryEntity> ministries;
  final String placeId;
  final PlaceInfo? placeInfo;
  final String? nextCursor;
  final bool hasMore;
  final int? totalEstimate;
  final bool isLoadingMore;

  const MinistriesLoaded({
    required this.ministries,
    required this.placeId,
    this.placeInfo,
    this.nextCursor,
    this.hasMore = false,
    this.totalEstimate,
    this.isLoadingMore = false,
  });

  MinistriesLoaded copyWith({
    List<MinistryEntity>? ministries,
    String? placeId,
    PlaceInfo? placeInfo,
    String? nextCursor,
    bool? hasMore,
    int? totalEstimate,
    bool? isLoadingMore,
  }) {
    return MinistriesLoaded(
      ministries: ministries ?? this.ministries,
      placeId: placeId ?? this.placeId,
      placeInfo: placeInfo ?? this.placeInfo,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      totalEstimate: totalEstimate ?? this.totalEstimate,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    ministries,
    placeId,
    placeInfo,
    nextCursor,
    hasMore,
    totalEstimate,
    isLoadingMore,
  ];
}

/// Services loaded state with pagination support.
class ServicesLoaded extends GetTokenState {
  final List<StaffServiceEntity> services;
  final String ministryId;
  final String ministryName;
  final MinistryInfo? ministryInfo;
  final String? nextCursor;
  final bool hasMore;
  final int? totalEstimate;
  final bool isLoadingMore;

  const ServicesLoaded({
    required this.services,
    required this.ministryId,
    required this.ministryName,
    this.ministryInfo,
    this.nextCursor,
    this.hasMore = false,
    this.totalEstimate,
    this.isLoadingMore = false,
  });

  ServicesLoaded copyWith({
    List<StaffServiceEntity>? services,
    String? ministryId,
    String? ministryName,
    MinistryInfo? ministryInfo,
    String? nextCursor,
    bool? hasMore,
    int? totalEstimate,
    bool? isLoadingMore,
  }) {
    return ServicesLoaded(
      services: services ?? this.services,
      ministryId: ministryId ?? this.ministryId,
      ministryName: ministryName ?? this.ministryName,
      ministryInfo: ministryInfo ?? this.ministryInfo,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      totalEstimate: totalEstimate ?? this.totalEstimate,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    services,
    ministryId,
    ministryName,
    ministryInfo,
    nextCursor,
    hasMore,
    totalEstimate,
    isLoadingMore,
  ];
}

/// Service details loaded state.
class ServiceDetailsLoaded extends GetTokenState {
  final QueueConfigEntity details;

  const ServiceDetailsLoaded({required this.details});

  /// Alias for details to support both naming conventions
  QueueConfigEntity get config => details;

  @override
  List<Object?> get props => [details];
}

/// Token booked successfully state.
class TokenBooked extends GetTokenState {
  final QueueTokenEntity token;

  const TokenBooked({required this.token});

  @override
  List<Object?> get props => [token];
}

/// My tokens loaded state with pagination support.
class MyTokensLoaded extends GetTokenState {
  final List<QueueTokenEntity> tokens;
  final String? statusFilter;
  final String? nextCursor;
  final bool hasMore;
  final int? totalEstimate;
  final bool isLoadingMore;

  const MyTokensLoaded({
    required this.tokens,
    this.statusFilter,
    this.nextCursor,
    this.hasMore = false,
    this.totalEstimate,
    this.isLoadingMore = false,
  });

  MyTokensLoaded copyWith({
    List<QueueTokenEntity>? tokens,
    String? statusFilter,
    String? nextCursor,
    bool? hasMore,
    int? totalEstimate,
    bool? isLoadingMore,
  }) {
    return MyTokensLoaded(
      tokens: tokens ?? this.tokens,
      statusFilter: statusFilter ?? this.statusFilter,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      totalEstimate: totalEstimate ?? this.totalEstimate,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    tokens,
    statusFilter,
    nextCursor,
    hasMore,
    totalEstimate,
    isLoadingMore,
  ];
}

/// Token cancelled state.
class TokenCancelled extends GetTokenState {
  final String tokenId;

  const TokenCancelled({required this.tokenId});

  @override
  List<Object?> get props => [tokenId];
}

/// Error state.
class GetTokenError extends GetTokenState {
  final String message;

  const GetTokenError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Booking in progress state.
class BookingInProgress extends GetTokenState {
  final String message;
  final QueueConfigEntity config;

  const BookingInProgress({
    this.message = 'Booking token...',
    required this.config,
  });

  @override
  List<Object?> get props => [message, config];
}
