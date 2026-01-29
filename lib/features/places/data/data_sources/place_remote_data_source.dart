import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/network/api_client.dart';
import 'package:sewa_web/features/places/data/models/place_model.dart';

/// Abstract data source for place operations
abstract class PlaceRemoteDataSource {
  /// Get all public places
  Future<List<PlaceModel>> getPublicPlaces();

  /// Get place by slug
  Future<PlaceModel> getPlaceBySlug(String slug);

  /// Get all places (admin)
  Future<List<PlaceModel>> getAllPlaces();

  /// Create place
  Future<PlaceModel> createPlace({required String name, required String slug});

  /// Update place
  Future<PlaceModel> updatePlace({
    required String id,
    String? name,
    String? slug,
    bool? isActive,
  });

  /// Delete place
  Future<void> deletePlace(String id);
}

/// Implementation of PlaceRemoteDataSource
class PlaceRemoteDataSourceImpl implements PlaceRemoteDataSource {
  final ApiClient apiClient;

  PlaceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PlaceModel>> getPublicPlaces() async {
    try {
      final response = await apiClient.get(ApiEndpoints.publicPlaces);

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to load places',
        );
      }

      final data = response['data'] as List;
      return data.map((json) => PlaceModel.fromJson(json)).toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<PlaceModel> getPlaceBySlug(String slug) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.publicPlaceBySlug(slug),
      );

      if (response['success'] != true) {
        throw ServerException(message: response['error'] ?? 'Place not found');
      }

      return PlaceModel.fromJson(response['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<PlaceModel>> getAllPlaces() async {
    try {
      final response = await apiClient.get(ApiEndpoints.adminPlaces);

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to load places',
        );
      }

      final data = response['data'] as List;
      return data.map((json) => PlaceModel.fromJson(json)).toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<PlaceModel> createPlace({
    required String name,
    required String slug,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.adminPlaceCreate,
        data: {'name': name, 'slug': slug},
      );

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to create place',
        );
      }

      return PlaceModel.fromJson(response['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<PlaceModel> updatePlace({
    required String id,
    String? name,
    String? slug,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (slug != null) data['slug'] = slug;
      if (isActive != null) data['is_active'] = isActive;

      final response = await apiClient.put(
        ApiEndpoints.adminPlaceDetail(id),
        data: data,
      );

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to update place',
        );
      }

      return PlaceModel.fromJson(response['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deletePlace(String id) async {
    try {
      final response = await apiClient.delete(
        ApiEndpoints.adminPlaceDetail(id),
      );

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to delete place',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
