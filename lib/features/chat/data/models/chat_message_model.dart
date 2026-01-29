import 'package:sewa_sathi/features/chat/data/models/source_model.dart';
import 'package:sewa_sathi/features/chat/domain/entities/chat_message_entity.dart';

/// Model class for ChatMessage with JSON serialization.
class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.text,
    required super.isUser,
    super.sources,
    required super.timestamp,
    super.isLoading,
    super.error,
    super.status,
  });

  /// Create ChatMessageModel from API JSON response.
  ///
  /// Backend format:
  /// ```json
  /// {
  ///   "success": true,
  ///   "response": "AI generated text...",
  ///   "sources": [...]
  /// }
  /// ```
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final List<SourceModel>? sources = json['sources'] != null
        ? (json['sources'] as List)
              .map((s) => SourceModel.fromJson(s as Map<String, dynamic>))
              .toList()
        : null;

    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['response']?.toString() ?? json['text']?.toString() ?? '',
      isUser: json['is_user'] as bool? ?? false,
      sources: sources,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  /// Convert ChatMessageModel to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      if (sources != null)
        'sources': sources!
            .map((s) => SourceModel.fromEntity(s).toJson())
            .toList(),
    };
  }

  /// Create ChatMessageModel from entity.
  factory ChatMessageModel.fromEntity(ChatMessageEntity entity) {
    return ChatMessageModel(
      id: entity.id,
      text: entity.text,
      isUser: entity.isUser,
      sources: entity.sources,
      timestamp: entity.timestamp,
      isLoading: entity.isLoading,
      error: entity.error,
      status: entity.status,
    );
  }

  /// Create a user message.
  factory ChatMessageModel.userMessage(String text) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
  }

  /// Create a loading placeholder message.
  factory ChatMessageModel.loading() {
    return ChatMessageModel(
      id: 'loading-${DateTime.now().millisecondsSinceEpoch}',
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }

  /// Create an error message.
  factory ChatMessageModel.error(String errorMessage) {
    return ChatMessageModel(
      id: 'error-${DateTime.now().millisecondsSinceEpoch}',
      text: errorMessage,
      isUser: false,
      timestamp: DateTime.now(),
      error: errorMessage,
      status: MessageStatus.error,
    );
  }

  /// Create AI response message from API response.
  factory ChatMessageModel.aiResponse({
    required String text,
    required List<SourceModel> sources,
  }) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      sources: sources,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
  }
}
