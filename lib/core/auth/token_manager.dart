import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sewa_sathi/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:sewa_sathi/features/auth/data/models/auth_tokens_model.dart';
import 'package:sewa_sathi/features/auth/domain/entities/auth_tokens.dart';

/// Manages authentication tokens with refresh logic.
class TokenManager {
  final AuthLocalDataSource _localDataSource;

  bool _isRefreshing = false;
  Completer<AuthTokens?>? _refreshCompleter;

  // Callback for refreshing tokens from remote
  Future<AuthTokens?> Function(String refreshToken)? _refreshCallback;

  TokenManager({required AuthLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  /// Set the refresh callback.
  void setRefreshCallback(
    Future<AuthTokens?> Function(String refreshToken) callback,
  ) {
    _refreshCallback = callback;
  }

  /// Get the current access token.
  Future<String?> getAccessToken() async {
    try {
      final hasTokens = await _localDataSource.hasTokens();
      if (!hasTokens) {
        return null;
      }

      final tokens = await _localDataSource.getTokens();
      return tokens?.accessToken;
    } catch (e) {
      debugPrint('TokenManager: Error getting access token - $e');
      return null;
    }
  }

  /// Store tokens.
  Future<void> storeTokens(AuthTokensModel tokens) async {
    await _localDataSource.cacheTokens(tokens);
  }

  /// Refresh tokens.
  Future<AuthTokens?> refreshTokens() async {
    if (_isRefreshing) {
      return _refreshCompleter?.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<AuthTokens?>();

    try {
      final currentTokens = await _localDataSource.getTokens();
      if (currentTokens == null) {
        _refreshCompleter!.complete(null);
        return null;
      }

      if (_refreshCallback == null) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final newTokens = await _refreshCallback!(currentTokens.refreshToken);
      if (newTokens != null) {
        final tokensModel = AuthTokensModel.fromEntity(newTokens);
        await storeTokens(tokensModel);
        _refreshCompleter!.complete(newTokens);
        return newTokens;
      } else {
        _refreshCompleter!.complete(null);
        return null;
      }
    } catch (e) {
      debugPrint('TokenManager: Token refresh error - $e');
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Clear all tokens.
  Future<void> clearTokens() async {
    await _localDataSource.clearTokens();
  }

  /// Check if tokens exist.
  Future<bool> hasTokens() async {
    return _localDataSource.hasTokens();
  }
}
