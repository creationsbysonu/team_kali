part of 'chat_bloc.dart';

/// Base class for all chat states.
abstract class ChatState extends Equatable {
  /// Current list of messages
  final List<ChatMessageEntity> messages;

  const ChatState({required this.messages});

  @override
  List<Object?> get props => [messages];
}

/// State when chat is ready and waiting for user input.
class ChatReady extends ChatState {
  const ChatReady({required super.messages});
}

/// State when a message is being sent/processed.
class ChatLoading extends ChatState {
  const ChatLoading({required super.messages});
}
