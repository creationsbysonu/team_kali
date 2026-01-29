import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/chat/domain/repositories/chat_repository.dart';

/// Use case to connect to chat WebSocket.
/// Optional - only needed for WebSocket mode.
class ConnectChatUseCase implements UseCase<void, ConnectChatParams> {
  final ChatRepository repository;

  ConnectChatUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ConnectChatParams params) async {
    return repository.connect(accessToken: params.accessToken);
  }
}

/// Parameters for connecting to WebSocket.
class ConnectChatParams extends Equatable {
  /// Optional JWT access token for authenticated connections
  final String? accessToken;

  const ConnectChatParams({this.accessToken});

  @override
  List<Object?> get props => [accessToken];
}
