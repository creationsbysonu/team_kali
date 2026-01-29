import 'package:sewa_sathi/features/auth/data/models/auth_tokens_model.dart';
import 'package:sewa_sathi/features/auth/data/models/user_model.dart';
import 'package:sewa_sathi/features/auth/domain/entities/auth_response.dart';

/// Model class for AuthResponse with JSON serialization.
class AuthResponseModel extends AuthResponse {
  const AuthResponseModel({
    required UserModel user,
    required AuthTokensModel tokens,
    required super.isNewUser,
  }) : super(user: user, tokens: tokens);

  /// Create AuthResponseModel from JSON response.
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json['user']),
      tokens: AuthTokensModel.fromJson(json['tokens']),
      isNewUser: json['is_new_user'] ?? false,
    );
  }

  /// Get user as UserModel.
  UserModel get userModel => user as UserModel;

  /// Get tokens as AuthTokensModel.
  AuthTokensModel get tokensModel => tokens as AuthTokensModel;
}
