import 'package:sewa_sathi/core/constants/api_endpoints.dart';
import 'package:sewa_sathi/core/errors/exceptions.dart';
import 'package:sewa_sathi/core/network/api_client.dart';
import 'package:sewa_sathi/features/profile/data/models/place_model.dart';
import 'package:sewa_sathi/features/profile/data/models/profile_model.dart';

/// Abstract remote data source for profile operations.
abstract class ProfileRemoteDataSource {
  /// Check profile status.
  /// Returns profile data if complete, null if incomplete.
  Future<ProfileModel?> checkProfileStatus();

  /// Get list of available places.
  Future<List<PlaceModel>> getPlaces();

  /// Setup a new profile.
  Future<ProfileModel> setupProfile({
    required String fullName,
    required String placeId,
  });

  /// Update existing profile.
  Future<ProfileModel> updateProfile({String? fullName, String? placeId});
}

/// Implementation of ProfileRemoteDataSource using ApiClient.
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient apiClient;

  ProfileRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ProfileModel?> checkProfileStatus() async {
    try {
      final responseData = await apiClient.get(ApiEndpoints.profileStatus);

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to check profile status',
        );
      }

      final data = responseData['data'];
      final isComplete = data['is_profile_complete'] as bool? ?? false;

      // Return null if profile is incomplete or doesn't exist
      if (!isComplete || data['profile'] == null) {
        return null;
      }

      return ProfileModel.fromJson(data['profile'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to check profile status: $e');
    }
  }

  @override
  Future<List<PlaceModel>> getPlaces() async {
    try {
      final responseData = await apiClient.get(ApiEndpoints.places);

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to fetch places',
        );
      }

      final placesData = responseData['data'] as List<dynamic>;
      return placesData
          .map((json) => PlaceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to fetch places: $e');
    }
  }

  @override
  Future<ProfileModel> setupProfile({
    required String fullName,
    required String placeId,
  }) async {
    try {
      final responseData = await apiClient.post(
        ApiEndpoints.profileSetup,
        data: {'full_name': fullName, 'place_id': placeId},
      );

      if (responseData['success'] != true) {
        // Handle validation errors
        if (responseData['error'] is Map) {
          final errors = responseData['error'] as Map<String, dynamic>;
          final errorMessages = errors.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(', ');
          throw ServerException(message: errorMessages);
        }
        throw ServerException(
          message:
              responseData['error']?.toString() ?? 'Failed to setup profile',
        );
      }

      return ProfileModel.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to setup profile: $e');
    }
  }

  @override
  Future<ProfileModel> updateProfile({
    String? fullName,
    String? placeId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (placeId != null) data['place_id'] = placeId;

      final responseData = await apiClient.patch(
        ApiEndpoints.profileUpdate,
        data: data,
      );

      if (responseData['success'] != true) {
        // Handle validation errors
        if (responseData['error'] is Map) {
          final errors = responseData['error'] as Map<String, dynamic>;
          final errorMessages = errors.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(', ');
          throw ServerException(message: errorMessages);
        }
        throw ServerException(
          message:
              responseData['error']?.toString() ?? 'Failed to update profile',
        );
      }

      return ProfileModel.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to update profile: $e');
    }
  }
}
