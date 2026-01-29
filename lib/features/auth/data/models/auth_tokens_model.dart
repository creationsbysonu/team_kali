import 'package:sewa_sathi/features/auth/domain/entities/auth_tokens.dart';

/// Model class for AuthTokens with JSON serialization.
class AuthTokensModel extends AuthTokens {
  const AuthTokensModel({
    required super.accessToken,
    required super.refreshToken,
    super.tokenType,
    super.expiresIn,
    super.refreshExpiresIn,
  });

  /// Create AuthTokensModel from JSON response.
  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      expiresIn: json['expires_in'] ?? 900,
      refreshExpiresIn: json['refresh_expires_in'] ?? 1209600,
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'refresh_expires_in': refreshExpiresIn,
    };
  }

  /// Create AuthTokensModel from AuthTokens entity.
  factory AuthTokensModel.fromEntity(AuthTokens entity) {
    return AuthTokensModel(
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      tokenType: entity.tokenType,
      expiresIn: entity.expiresIn,
      refreshExpiresIn: entity.refreshExpiresIn,
    );
  }
}
