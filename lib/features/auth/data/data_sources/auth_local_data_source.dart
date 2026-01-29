// Define constants for storage keys
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/features/auth/data/models/auth_tokens_model.dart';
import 'package:sewa_web/features/auth/data/models/user_model.dart';

const CACHED_TOKENS_KEY = 'CACHED_TOKENS';
const CACHED_USER_KEY = 'CACHED_USER';

abstract class AuthLocalDataSource {
  Future<void> cacheTokens(AuthTokensModel tokens);
  Future<AuthTokensModel> getTokens();
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getUser();
  Future<String?> getMinistryId();
  Future<void> clearAuthData();
  Future<bool> hasTokes();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheTokens(AuthTokensModel tokens) async {
    final jsonString = json.encode(tokens.toJson());
    await sharedPreferences.setString(CACHED_TOKENS_KEY, jsonString);
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    final jsonString = json.encode(user.toStorageJson());
    await sharedPreferences.setString(CACHED_USER_KEY, jsonString);
  }

  @override
  Future<void> clearAuthData() async {
    await sharedPreferences.remove(CACHED_TOKENS_KEY);
    await sharedPreferences.remove(CACHED_USER_KEY);
  }

  @override
  Future<AuthTokensModel> getTokens() async {
    final jsonString = sharedPreferences.getString(CACHED_TOKENS_KEY);
    if (jsonString != null) {
      return AuthTokensModel.fromStorage(json.decode(jsonString));
    } else {
      throw CacheException();
    }
  }

  @override
  Future<bool> hasTokes() async {
    final jsonString = sharedPreferences.getString(CACHED_TOKENS_KEY);
    if (jsonString == null) return false;
    try {
      final tokens = AuthTokensModel.fromStorage(json.decode(jsonString));
      return tokens.accessToken.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<UserModel?> getUser() async {
    final jsonString = sharedPreferences.getString(CACHED_USER_KEY);
    if (jsonString != null) {
      return UserModel.fromStorageJson(json.decode(jsonString));
    } else {
      return null;
    }
  }

  @override
  Future<String?> getMinistryId() async {
    try {
      final user = await getUser();
      return user?.ministry?.id;
    } catch (e) {
      return null;
    }
  }
}
