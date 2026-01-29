import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/chat/domain/repositories/chat_repository.dart';

/// Use case to disconnect from WebSocket chat.
class DisconnectChatUseCase implements UseCase<void, NoParams> {
  final ChatRepository repository;

  DisconnectChatUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return repository.disconnect();
  }
}
