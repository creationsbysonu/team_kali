import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/chat/domain/repositories/chat_repository.dart';

/// Use case to send a message via WebSocket.
/// For REST API, use SendChatMessageUseCase instead.
class SendMessageUseCase implements UseCase<void, SendMessageParams> {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SendMessageParams params) async {
    // Validate message
    final message = params.message.trim();
    if (message.isEmpty) {
      return const Left(ValidationFailure(message: 'Message cannot be empty'));
    }

    if (message.length > 1000) {
      return const Left(
        ValidationFailure(
          message: 'Message is too long. Please keep it under 1000 characters.',
        ),
      );
    }

    return repository.sendWebSocketMessage(
      message,
      sessionId: params.sessionId,
    );
  }
}

/// Parameters for sending a message via WebSocket.
class SendMessageParams extends Equatable {
  final String message;
  final String? sessionId;

  const SendMessageParams({required this.message, this.sessionId});

  @override
  List<Object?> get props => [message, sessionId];
}
