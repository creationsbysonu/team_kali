part of 'get_token_bloc.dart';

/// Base event for GetToken feature.
abstract class GetTokenEvent extends Equatable {
  const GetTokenEvent();

  @override
  List<Object?> get props => [];
}

/// Load ministries for a place (initial load or refresh).
class LoadMinistriesEvent extends GetTokenEvent {
  final String placeId;
  final int pageSize;

  const LoadMinistriesEvent({required this.placeId, this.pageSize = 20});

  @override
  List<Object?> get props => [placeId, pageSize];
}

/// Load more ministries (pagination).
class LoadMoreMinistriesEvent extends GetTokenEvent {
  const LoadMoreMinistriesEvent();
}

/// Load services for a ministry (initial load or refresh).
class LoadServicesEvent extends GetTokenEvent {
  final String ministryId;
  final String ministryName;
  final int pageSize;

  const LoadServicesEvent({
    required this.ministryId,
    required this.ministryName,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [ministryId, ministryName, pageSize];
}

/// Load more services (pagination).
class LoadMoreServicesEvent extends GetTokenEvent {
  const LoadMoreServicesEvent();
}

/// Load service details.
class LoadServiceDetailsEvent extends GetTokenEvent {
  final String serviceId;

  const LoadServiceDetailsEvent({required this.serviceId});

  @override
  List<Object?> get props => [serviceId];
}

/// Book a token.
class BookTokenEvent extends GetTokenEvent {
  final String serviceId;
  final String bookingType;
  final String? bookingDate;

  const BookTokenEvent({
    required this.serviceId,
    this.bookingType = 'REGULAR',
    this.bookingDate,
  });

  @override
  List<Object?> get props => [serviceId, bookingType, bookingDate];
}

/// Load user's tokens (initial load or refresh).
class LoadMyTokensEvent extends GetTokenEvent {
  /// Status filter: ACTIVE, COMPLETED, CANCELLED
  final String? status;
  final int pageSize;

  const LoadMyTokensEvent({this.status, this.pageSize = 20});

  @override
  List<Object?> get props => [status, pageSize];
}

/// Load more user tokens (pagination).
class LoadMoreMyTokensEvent extends GetTokenEvent {
  const LoadMoreMyTokensEvent();
}

/// Cancel a token.
class CancelTokenEvent extends GetTokenEvent {
  final String tokenId;

  const CancelTokenEvent({required this.tokenId});

  @override
  List<Object?> get props => [tokenId];
}

/// Reset state to initial.
class ResetGetTokenEvent extends GetTokenEvent {}

/// Go back to previous state.
class GoBackEvent extends GetTokenEvent {}
