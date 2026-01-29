import 'package:sewa_sathi/core/constants/api_endpoints.dart';
import 'package:sewa_sathi/core/errors/exceptions.dart';
import 'package:sewa_sathi/core/network/api_client.dart';
import 'package:sewa_sathi/features/chat/data/models/chat_message_model.dart';
import 'package:sewa_sathi/features/chat/data/models/source_model.dart';

/// Abstract data source for chat REST API operations.
abstract class ChatRemoteDataSource {
  /// Send a chat query via REST API.
  ///
  /// POST /api/chat/
  /// Request: { "query": "...", "session_id": "..." }
  /// Response: { "success": true, "response": "...", "sources": [...] }
  Future<ChatMessageModel> sendMessage(String query, {String? sessionId});
}

/// Implementation of ChatRemoteDataSource using ApiClient.
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;

  ChatRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ChatMessageModel> sendMessage(
    String query, {
    String? sessionId,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.chat,
        data: {'query': query, if (sessionId != null) 'session_id': sessionId},
      );

      // Check if response is successful
      if (response['success'] != true) {
        final error = response['error'] as String? ?? 'Chat request failed';
        throw ServerException(message: error);
      }

      // Parse sources
      final List<SourceModel> sources = [];
      if (response['sources'] != null) {
        for (final source in response['sources'] as List) {
          sources.add(SourceModel.fromJson(source as Map<String, dynamic>));
        }
      }

      // Create AI response message
      return ChatMessageModel.aiResponse(
        text: response['response'] as String? ?? '',
        sources: sources,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to send message: $e');
    }
  }
}
