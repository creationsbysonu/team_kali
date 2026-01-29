import 'package:equatable/equatable.dart';

/// Booking type enum
enum BookingType {
  regular('REGULAR'),
  prebooked('PREBOOKED'),
  emergency('EMERGENCY');

  final String value;
  const BookingType(this.value);

  static BookingType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'REGULAR':
        return BookingType.regular;
      case 'PREBOOKED':
        return BookingType.prebooked;
      case 'EMERGENCY':
        return BookingType.emergency;
      default:
        return BookingType.regular;
    }
  }
}

/// Token status enum
enum TokenStatus {
  active('ACTIVE'),
  served('SERVED'),
  noShow('NO_SHOW'),
  cancelled('CANCELLED');

  final String value;
  const TokenStatus(this.value);

  static TokenStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVE':
        return TokenStatus.active;
      case 'SERVED':
        return TokenStatus.served;
      case 'NO_SHOW':
        return TokenStatus.noShow;
      case 'CANCELLED':
        return TokenStatus.cancelled;
      default:
        return TokenStatus.active;
    }
  }
}

/// Queue Token entity
class QueueToken extends Equatable {
  final String id;
  final int tokenNumber;
  final BookingType bookingType;
  final TokenStatus status;
  final DateTime date;
  final String? expectedServiceTime;
  final double? emergencyFeePaid;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final String staffServiceId;
  final String staffServiceName;
  final String citizenId;
  final String citizenName;
  final String? citizenPhone;

  const QueueToken({
    required this.id,
    required this.tokenNumber,
    required this.bookingType,
    required this.status,
    required this.date,
    this.expectedServiceTime,
    this.emergencyFeePaid,
    required this.createdAt,
    required this.updatedAt,
    required this.staffServiceId,
    required this.staffServiceName,
    required this.citizenId,
    required this.citizenName,
    this.citizenPhone,
  });

  @override
  List<Object?> get props => [
    id,
    tokenNumber,
    bookingType,
    status,
    date,
    expectedServiceTime,
    emergencyFeePaid,
    createdAt,
    updatedAt,
    staffServiceId,
    staffServiceName,
    citizenId,
    citizenName,
    citizenPhone,
  ];

  /// Check if token is active
  bool get isActive => status == TokenStatus.active;

  /// Check if token is served
  bool get isServed => status == TokenStatus.served;

  /// Check if token is no-show
  bool get isNoShow => status == TokenStatus.noShow;

  /// Check if token is cancelled
  bool get isCancelled => status == TokenStatus.cancelled;

  /// Check if token is emergency
  bool get isEmergency => bookingType == BookingType.emergency;

  /// Check if token is prebooked
  bool get isPrebooked => bookingType == BookingType.prebooked;

  QueueToken copyWith({
    String? id,
    int? tokenNumber,
    BookingType? bookingType,
    TokenStatus? status,
    DateTime? date,
    String? expectedServiceTime,
    double? emergencyFeePaid,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? staffServiceId,
    String? staffServiceName,
    String? citizenId,
    String? citizenName,
    String? citizenPhone,
  }) {
    return QueueToken(
      id: id ?? this.id,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      bookingType: bookingType ?? this.bookingType,
      status: status ?? this.status,
      date: date ?? this.date,
      expectedServiceTime: expectedServiceTime ?? this.expectedServiceTime,
      emergencyFeePaid: emergencyFeePaid ?? this.emergencyFeePaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      staffServiceId: staffServiceId ?? this.staffServiceId,
      staffServiceName: staffServiceName ?? this.staffServiceName,
      citizenId: citizenId ?? this.citizenId,
      citizenName: citizenName ?? this.citizenName,
      citizenPhone: citizenPhone ?? this.citizenPhone,
    );
  }
}
