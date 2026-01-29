import 'package:sewa_web/features/auth/domain/entities/auth_tokens.dart';

/// AuthTokensModel - matches backend spec exactly
/// Parses from API response:
/// {
///   "access_token": "string",
///   "refresh_token": "string",
///   "token_type": "Bearer",
///   "expires_in": 900,
///   "refresh_expires_in": 1209600
/// }
class AuthTokensModel extends AuthTokens {
  const AuthTokensModel({
    required super.accessToken,
    required super.refreshToken,
    super.tokenType,
    super.expiresIn,
    super.refreshExpiresIn,
    required super.accessExpiry,
    required super.refreshExpiry,
  });

  /// Deserializes from the API response
  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    final int accessExpiresIn = json['expires_in'] as int? ?? 900;
    final int refreshExpiresIn = json['refresh_expires_in'] as int? ?? 1209600;

    return AuthTokensModel(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: accessExpiresIn,
      refreshExpiresIn: refreshExpiresIn,
      accessExpiry: DateTime.now().add(Duration(seconds: accessExpiresIn)),
      refreshExpiry: DateTime.now().add(Duration(seconds: refreshExpiresIn)),
    );
  }

  /// Deserializes from local storage (SharedPreferences)
  factory AuthTokensModel.fromStorage(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as int? ?? 900,
      refreshExpiresIn: json['refresh_expires_in'] as int? ?? 1209600,
      accessExpiry:
          DateTime.tryParse(json['access_expiry'] as String? ?? '') ??
          DateTime.now(),
      refreshExpiry:
          DateTime.tryParse(json['refresh_expiry'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Serializes for storing locally
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'refresh_expires_in': refreshExpiresIn,
      'access_expiry': accessExpiry.toIso8601String(),
      'refresh_expiry': refreshExpiry.toIso8601String(),
    };
  }

  factory AuthTokensModel.fromEntity(AuthTokens entity) {
    return AuthTokensModel(
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      tokenType: entity.tokenType,
      expiresIn: entity.expiresIn,
      refreshExpiresIn: entity.refreshExpiresIn,
      accessExpiry: entity.accessExpiry,
      refreshExpiry: entity.refreshExpiry,
    );
  }
}
