import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/exceptions.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/network/network_info.dart';
import 'package:sewa_sathi/features/chat/data/data_sources/chat_remote_data_source.dart';
import 'package:sewa_sathi/features/chat/data/data_sources/chat_websocket_data_source.dart';
import 'package:sewa_sathi/features/chat/domain/entities/chat_message_entity.dart';
import 'package:sewa_sathi/features/chat/domain/repositories/chat_repository.dart';

/// Implementation of ChatRepository.
/// Supports both REST API and WebSocket communication.
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatWebSocketDataSource webSocketDataSource;
  final NetworkInfo networkInfo;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.webSocketDataSource,
    required this.networkInfo,
  });

  // ============================================
  // REST API Implementation
  // ============================================

  @override
  Future<Either<Failure, ChatMessageEntity>> sendChatMessage(
    String query, {
    String? sessionId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(
          message: 'No internet connection. Please check your network.',
        ),
      );
    }

    try {
      final response = await remoteDataSource.sendMessage(
        query,
        sessionId: sessionId,
      );
      return Right(response);
    } on ServerException catch (e) {
      // Handle specific error messages from backend
      if (e.message.contains('Rate limit')) {
        return const Left(
          ServerFailure(message: 'Too many messages. Please wait a moment.'),
        );
      }
      if (e.message.contains('unavailable') || e.message.contains('timeout')) {
        return const Left(
          ServerFailure(
            message:
                'AI assistant is temporarily unavailable. Please try again.',
          ),
        );
      }
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(
        ServerFailure(message: 'Something went wrong. Please try again.'),
      );
    }
  }

  // ============================================
  // WebSocket Implementation
  // ============================================

  @override
  Future<Either<Failure, void>> connect({String? accessToken}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await webSocketDataSource.connect(accessToken: accessToken);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to connect: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendWebSocketMessage(
    String query, {
    String? sessionId,
  }) async {
    try {
      await webSocketDataSource.sendMessage(query, sessionId: sessionId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to send message: $e'));
    }
  }

  @override
  Stream<ChatMessageEntity> get messages => webSocketDataSource.messages;

  @override
  bool get isConnected => webSocketDataSource.isConnected;

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await webSocketDataSource.disconnect();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to disconnect: $e'));
    }
  }

  @override
  void dispose() {
    webSocketDataSource.dispose();
  }
}
