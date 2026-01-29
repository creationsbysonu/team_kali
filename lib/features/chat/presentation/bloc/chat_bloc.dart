import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/features/chat/data/models/chat_message_model.dart';
import 'package:sewa_sathi/features/chat/domain/entities/chat_message_entity.dart';
import 'package:sewa_sathi/features/chat/domain/usecases/chat_usecases.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// BLoC for managing chat functionality.
/// Uses REST API for sending messages (recommended for mobile).
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendChatMessageUseCase sendChatMessage;

  final List<ChatMessageEntity> _messages = [];
  String? _sessionId;

  ChatBloc({required this.sendChatMessage})
    : super(const ChatReady(messages: [])) {
    on<SendMessageEvent>(_onSendMessage);
    on<ClearChatEvent>(_onClearChat);
    on<RetryMessageEvent>(_onRetryMessage);
  }

  /// Handle sending a new message
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) return;

    // Add user message immediately
    final userMessage = ChatMessageModel.userMessage(query);
    _messages.add(userMessage);

    // Add loading message
    final loadingMessage = ChatMessageModel.loading();
    _messages.add(loadingMessage);

    // Emit loading state
    emit(ChatLoading(messages: List.from(_messages)));

    // Send message via REST API
    final result = await sendChatMessage(
      SendChatMessageParams(query: query, sessionId: _sessionId),
    );

    // Remove loading message
    _messages.removeWhere((m) => m.isLoading);

    result.fold(
      (failure) {
        // Add error message
        final errorMessage = ChatMessageModel.error(failure.message);
        _messages.add(errorMessage);
        emit(ChatReady(messages: List.from(_messages)));
      },
      (aiResponse) {
        // Add AI response
        _messages.add(aiResponse);
        emit(ChatReady(messages: List.from(_messages)));
      },
    );
  }

  /// Handle clearing chat history
  void _onClearChat(ClearChatEvent event, Emitter<ChatState> emit) {
    _messages.clear();
    _sessionId = null;
    emit(const ChatReady(messages: []));
  }

  /// Handle retrying a failed message
  Future<void> _onRetryMessage(
    RetryMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Remove error message if present
    _messages.removeWhere((m) => m.hasError);
    emit(ChatReady(messages: List.from(_messages)));

    // Retry sending the message
    add(SendMessageEvent(query: event.query));
  }

  @override
  Future<void> close() {
    _messages.clear();
    return super.close();
  }
}
