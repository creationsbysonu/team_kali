import 'package:equatable/equatable.dart';

/// AuthTokens Entity - matches backend spec exactly
/// Fields:
/// - access_token (String) - JWT token for API calls, expires in 15 min
/// - refresh_token (String) - Used to get new access_token, expires in 14 days
/// - token_type (String) - Always "Bearer"
/// - expires_in (int) - Access token lifetime in seconds (900)
/// - refresh_expires_in (int) - Refresh token lifetime in seconds (1209600)
class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final int refreshExpiresIn;

  // Computed expiry times for convenience
  final DateTime accessExpiry;
  final DateTime refreshExpiry;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn = 900,
    this.refreshExpiresIn = 1209600,
    required this.accessExpiry,
    required this.refreshExpiry,
  });

  @override
  List<Object> get props => [
    accessToken,
    refreshToken,
    tokenType,
    expiresIn,
    refreshExpiresIn,
    accessExpiry,
    refreshExpiry,
  ];

  bool get isAccessTokenExpired => DateTime.now().isAfter(accessExpiry);
  bool get isRefreshTokenExpired => DateTime.now().isAfter(refreshExpiry);
  bool get canRefresh => !isRefreshTokenExpired;

  /// Authorization header value
  String get authorizationHeader => '$tokenType $accessToken';

  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    int? expiresIn,
    int? refreshExpiresIn,
    DateTime? accessExpiry,
    DateTime? refreshExpiry,
  }) {
    return AuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresIn: expiresIn ?? this.expiresIn,
      refreshExpiresIn: refreshExpiresIn ?? this.refreshExpiresIn,
      accessExpiry: accessExpiry ?? this.accessExpiry,
      refreshExpiry: refreshExpiry ?? this.refreshExpiry,
    );
  }
}
