import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/features/auth/domain/entities/auth_tokens.dart';
import 'package:sewa_sathi/features/auth/domain/entities/user_entity.dart';

/// Response entity for successful OTP verification.
class AuthResponse extends Equatable {
  final UserEntity user;
  final AuthTokens tokens;
  final bool isNewUser;

  const AuthResponse({
    required this.user,
    required this.tokens,
    required this.isNewUser,
  });

  @override
  List<Object?> get props => [user, tokens, isNewUser];
}
