import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sewa_sathi/core/constants/api_endpoints.dart';
import 'package:sewa_sathi/core/errors/exceptions.dart';
import 'package:sewa_sathi/features/community/domain/entities/community_entities.dart';

/// Result from AI content moderation.
class ModerationResult {
  final ContentStatus status;
  final double confidence;
  final String rawClass;

  const ModerationResult({
    required this.status,
    required this.confidence,
    required this.rawClass,
  });

  /// Parse from AI server response.
  /// AI returns: {"class": "NORMAL"|"BLOCKED"|"WARNING", "confidence": 0.99}
  factory ModerationResult.fromJson(Map<String, dynamic> json) {
    final rawClass = json['class'] as String? ?? 'NORMAL';
    final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;

    ContentStatus status;
    switch (rawClass.toUpperCase()) {
      case 'BLOCKED':
        status = ContentStatus.blocked;
        break;
      case 'WARNING':
        status = ContentStatus.warning;
        break;
      case 'NORMAL':
      default:
        status = ContentStatus.normal;
        break;
    }

    return ModerationResult(
      status: status,
      confidence: confidence,
      rawClass: rawClass,
    );
  }

  bool get isNormal => status == ContentStatus.normal;
  bool get isBlocked => status == ContentStatus.blocked;
  bool get isWarning => status == ContentStatus.warning;

  @override
  String toString() =>
      'ModerationResult(status: $status, confidence: ${(confidence * 100).toStringAsFixed(1)}%, class: $rawClass)';
}

/// Service for content moderation via AI.
/// Flow: Flutter → AI Image Server (port 8003) → Response
///
/// Architecture:
/// - Port 8000: Main FastAPI server (issues, ideas, chat gateway)
/// - Port 8003: AI Image Moderation server (separate, direct connection)
abstract class ModerationService {
  /// Moderate an image file and get classification result.
  Future<ModerationResult> moderateImage(File image);
}

/// Implementation of ModerationService using direct connection to AI server.
/// Connects directly to port 8003 (separate from main API on port 8000).
class ModerationServiceImpl implements ModerationService {
  /// Dedicated Dio instance for AI moderation server (port 8003)
  late final Dio _moderationDio;

  ModerationServiceImpl() {
    _moderationDio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.moderationServerUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Accept': 'application/json'},
      ),
    );
  }

  @override
  Future<ModerationResult> moderateImage(File image) async {
    try {
      debugPrint('🔍 Sending image to AI moderation server (port 8003)...');
      debugPrint('📡 URL: ${ApiEndpoints.moderateUrl}');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
      });

      final response = await _moderationDio.post(
        ApiEndpoints.moderateEndpoint,
        data: formData,
      );

      final result = ModerationResult.fromJson(response.data);

      debugPrint('✅ Moderation result: $result');

      return result;
    } on DioException catch (e) {
      debugPrint('❌ Moderation failed: ${e.message}');
      debugPrint('❌ Status: ${e.response?.statusCode}');
      debugPrint('❌ Response: ${e.response?.data}');

      // If AI server is down, default to normal (for hackathon demo)
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        debugPrint('⚠️ AI server unreachable, defaulting to NORMAL');
        return const ModerationResult(
          status: ContentStatus.normal,
          confidence: 0.0,
          rawClass: 'NORMAL_FALLBACK',
        );
      }

      throw ServerException(
        message: 'Failed to moderate image: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Moderation error: $e');
      throw ServerException(message: 'Content moderation failed: $e');
    }
  }
}
