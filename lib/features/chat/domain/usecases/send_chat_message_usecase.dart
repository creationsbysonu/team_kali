import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/chat/domain/entities/chat_message_entity.dart';
import 'package:sewa_sathi/features/chat/domain/repositories/chat_repository.dart';

/// Use case to send a chat message via REST API.
/// This is the recommended way to interact with the AI assistant.
class SendChatMessageUseCase
    implements UseCase<ChatMessageEntity, SendChatMessageParams> {
  final ChatRepository repository;

  SendChatMessageUseCase(this.repository);

  @override
  Future<Either<Failure, ChatMessageEntity>> call(
    SendChatMessageParams params,
  ) async {
    // Validate query
    final query = params.query.trim();

    if (query.isEmpty) {
      return const Left(ValidationFailure(message: 'Please enter a message'));
    }

    if (query.length > 1000) {
      return const Left(
        ValidationFailure(
          message: 'Message is too long. Please keep it under 1000 characters.',
        ),
      );
    }

    return repository.sendChatMessage(query, sessionId: params.sessionId);
  }
}

/// Parameters for sending a chat message.
class SendChatMessageParams extends Equatable {
  /// The user's query/question
  final String query;

  /// Optional session ID for conversation context
  final String? sessionId;

  const SendChatMessageParams({required this.query, this.sessionId});

  @override
  List<Object?> get props => [query, sessionId];
}
