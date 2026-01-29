import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/features/chat/domain/entities/chat_message_entity.dart';

/// Abstract repository for chat operations.
/// Supports both REST API and WebSocket communication modes.
abstract class ChatRepository {
  // ============================================
  // REST API Methods (Recommended for mobile)
  // ============================================

  /// Send a chat query via REST API and get response.
  /// This is the recommended method for mobile apps.
  ///
  /// Returns the AI response message with sources.
  Future<Either<Failure, ChatMessageEntity>> sendChatMessage(
    String query, {
    String? sessionId,
  });

  // ============================================
  // WebSocket Methods (For real-time chat)
  // ============================================

  /// Connect to WebSocket chat server.
  Future<Either<Failure, void>> connect({String? accessToken});

  /// Send a message via WebSocket.
  Future<Either<Failure, void>> sendWebSocketMessage(
    String query, {
    String? sessionId,
  });

  /// Stream of incoming messages from WebSocket.
  Stream<ChatMessageEntity> get messages;

  /// Check if currently connected to WebSocket.
  bool get isConnected;

  /// Disconnect from WebSocket.
  Future<Either<Failure, void>> disconnect();

  /// Dispose resources.
  void dispose();
}
