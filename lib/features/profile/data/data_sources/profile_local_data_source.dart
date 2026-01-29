import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sewa_sathi/features/profile/data/models/profile_model.dart';

/// Abstract local data source for profile caching.
abstract class ProfileLocalDataSource {
  /// Get cached profile.
  Future<ProfileModel?> getCachedProfile();

  /// Cache profile data.
  Future<void> cacheProfile(ProfileModel profile);

  /// Clear cached profile.
  Future<void> clearCachedProfile();
}

/// Implementation of ProfileLocalDataSource using FlutterSecureStorage.
class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  final FlutterSecureStorage secureStorage;
  static const String _profileKey = 'CACHED_PROFILE';

  ProfileLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<ProfileModel?> getCachedProfile() async {
    try {
      final jsonString = await secureStorage.read(key: _profileKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return ProfileModel.fromJson(json);
      }
      return null;
    } catch (e) {
      // If there's any error reading/parsing, return null
      return null;
    }
  }

  @override
  Future<void> cacheProfile(ProfileModel profile) async {
    try {
      final jsonString = jsonEncode(profile.toJson());
      await secureStorage.write(key: _profileKey, value: jsonString);
    } catch (e) {
      // Silently fail cache write to avoid blocking user flow
    }
  }

  @override
  Future<void> clearCachedProfile() async {
    try {
      await secureStorage.delete(key: _profileKey);
    } catch (e) {
      // Silently fail cache clear
    }
  }
}
