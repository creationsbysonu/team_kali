import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/features/chat/domain/entities/source_entity.dart';

/// Message status for UI rendering
enum MessageStatus { sending, sent, error }

/// Represents a chat message entity.
class ChatMessageEntity extends Equatable {
  /// Unique identifier for the message
  final String id;

  /// Message text content
  final String text;

  /// Whether this message is from the user (true) or AI (false)
  final bool isUser;

  /// Source references for AI responses
  final List<SourceEntity>? sources;

  /// When the message was created
  final DateTime timestamp;

  /// Loading state for AI responses
  final bool isLoading;

  /// Error message if request failed
  final String? error;

  /// Message status
  final MessageStatus status;

  const ChatMessageEntity({
    required this.id,
    required this.text,
    required this.isUser,
    this.sources,
    required this.timestamp,
    this.isLoading = false,
    this.error,
    this.status = MessageStatus.sent,
  });

  /// Check if this is an error message
  bool get hasError => error != null;

  @override
  List<Object?> get props => [
    id,
    text,
    isUser,
    sources,
    timestamp,
    isLoading,
    error,
    status,
  ];

  ChatMessageEntity copyWith({
    String? id,
    String? text,
    bool? isUser,
    List<SourceEntity>? sources,
    DateTime? timestamp,
    bool? isLoading,
    String? error,
    MessageStatus? status,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      sources: sources ?? this.sources,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      status: status ?? this.status,
    );
  }

  @override
  String toString() =>
      'ChatMessageEntity(id: $id, isUser: $isUser, sources: ${sources?.length ?? 0}, status: $status)';
}
