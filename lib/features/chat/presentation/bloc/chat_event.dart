part of 'chat_bloc.dart';

/// Base class for all chat events.
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Event to send a message via REST API.
class SendMessageEvent extends ChatEvent {
  final String query;

  const SendMessageEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Event to clear chat history.
class ClearChatEvent extends ChatEvent {
  const ClearChatEvent();
}

/// Event to retry a failed message.
class RetryMessageEvent extends ChatEvent {
  final String query;

  const RetryMessageEvent({required this.query});

  @override
  List<Object?> get props => [query];
}
