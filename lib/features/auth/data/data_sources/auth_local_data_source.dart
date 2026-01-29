import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sewa_sathi/core/errors/exceptions.dart';
import 'package:sewa_sathi/features/auth/data/models/auth_tokens_model.dart';
import 'package:sewa_sathi/features/auth/data/models/user_model.dart';

/// Abstract interface for auth local data source.
abstract class AuthLocalDataSource {
  /// Get cached user.
  Future<UserModel?> getUser();

  /// Cache user data.
  Future<void> cacheUser(UserModel user);

  /// Clear cached user.
  Future<void> clearUser();

  /// Get cached tokens.
  Future<AuthTokensModel?> getTokens();

  /// Cache tokens.
  Future<void> cacheTokens(AuthTokensModel tokens);

  /// Clear cached tokens.
  Future<void> clearTokens();

  /// Check if tokens exist.
  Future<bool> hasTokens();

  /// Clear all cached auth data.
  Future<void> clearAll();
}

/// Implementation using FlutterSecureStorage.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  static const String _userKey = 'CACHED_USER';
  static const String _tokensKey = 'CACHED_TOKENS';

  AuthLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<UserModel?> getUser() async {
    try {
      final jsonString = await secureStorage.read(key: _userKey);
      if (jsonString != null) {
        return UserModel.fromJson(json.decode(jsonString));
      }
      return null;
    } catch (e) {
      throw CacheException(message: 'Failed to get cached user');
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await secureStorage.write(
        key: _userKey,
        value: json.encode(user.toJson()),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to cache user');
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      await secureStorage.delete(key: _userKey);
    } catch (e) {
      throw CacheException(message: 'Failed to clear user cache');
    }
  }

  @override
  Future<AuthTokensModel?> getTokens() async {
    try {
      final jsonString = await secureStorage.read(key: _tokensKey);
      if (jsonString != null) {
        return AuthTokensModel.fromJson(json.decode(jsonString));
      }
      return null;
    } catch (e) {
      throw CacheException(message: 'Failed to get cached tokens');
    }
  }

  @override
  Future<void> cacheTokens(AuthTokensModel tokens) async {
    try {
      await secureStorage.write(
        key: _tokensKey,
        value: json.encode(tokens.toJson()),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to cache tokens');
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await secureStorage.delete(key: _tokensKey);
    } catch (e) {
      throw CacheException(message: 'Failed to clear tokens cache');
    }
  }

  @override
  Future<bool> hasTokens() async {
    try {
      final tokens = await secureStorage.read(key: _tokensKey);
      return tokens != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> clearAll() async {
    await clearUser();
    await clearTokens();
  }
}
