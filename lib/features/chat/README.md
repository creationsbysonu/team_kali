# AI Chat Feature

## Overview
The AI Chat feature provides a WebSocket-based real-time chat interface for users to interact with an AI assistant powered by RAG (Retrieval-Augmented Generation). The AI can answer questions about notices and provides source references with deep linking capabilities.

## Architecture

The feature follows Clean Architecture with three layers:

### Domain Layer
- **Entities**:
  - `SourceEntity`: Represents a notice reference (noticeId, title, excerpt)
  - `ChatMessageEntity`: Chat message with text, isUser flag, sources list, and timestamp

- **Repository**: `ChatRepository` (abstract interface)
  - `connect()`: Establish WebSocket connection
  - `sendMessage(query)`: Send user query
  - `messages`: Stream of incoming messages
  - `isConnected`: Connection status getter
  - `disconnect()`: Close connection
  - `dispose()`: Cleanup resources

- **Use Cases**:
  - `ConnectChatUseCase`: Establishes WebSocket connection
  - `SendMessageUseCase`: Validates and sends user messages
  - `DisconnectChatUseCase`: Closes WebSocket connection

### Data Layer
- **Models**:
  - `SourceModel`: JSON serialization for SourceEntity
  - `ChatMessageModel`: JSON serialization for ChatMessageEntity
    - Handles both user messages and AI responses
    - Maps `response` field from backend to `text` field
    - Deserializes nested sources array

- **Data Sources**:
  - `ChatWebSocketDataSource`: Abstract interface
  - `ChatWebSocketDataSourceImpl`: WebSocket implementation using web_socket_channel
    - Connects to `ws://YOUR_SERVER/ws/chat/`
    - Sends: `{"query": "user question"}`
    - Receives: `{"response": "AI answer", "sources": [...]}`
    - Streams messages via BroadcastStreamController

- **Repository Implementation**: `ChatRepositoryImpl`
  - Delegates to WebSocket data source
  - Returns domain entities

### Presentation Layer
- **BLoC**: `ChatBloc`
  - Events:
    - `ConnectChatEvent`: Initiate connection
    - `SendMessageEvent`: Send user message
    - `MessageReceivedEvent`: Handle incoming AI response
    - `DisconnectChatEvent`: Close connection
  
  - States:
    - `ChatInitial`: Before connection
    - `ChatConnecting`: Establishing connection
    - `ChatConnected`: Active chat session with message list
    - `ChatError`: Error state with message
    - `ChatDisconnected`: Connection closed
  
  - Features:
    - Maintains message history
    - Optimistically adds user messages
    - Listens to WebSocket stream for AI responses
    - Auto-scrolls to bottom on new messages

- **Pages**:
  - `ChatScreen`: Main chat interface
    - Header with AI branding
    - Message list view with auto-scroll
    - Empty state with suggested questions
    - Message input with send button
    - Loading and error states

- **Widgets**:
  - `MessageBubble`: Displays single chat message
    - User vs AI styling (right vs left alignment)
    - Avatar icons
    - Source chips below AI messages
  
  - `SourceChip`: Clickable chip for notice references
    - Shows notice title or truncated ID
    - Opens notice detail screen on tap
    - Visual indicator with icon

## WebSocket Protocol

### Connection
```
ws://YOUR_SERVER/ws/chat/
```

### Send Message
```json
{
  "query": "What are the latest notices?"
}
```

### Receive Response
```json
{
  "response": "Here are the latest notices...",
  "sources": [
    {
      "notice_id": "uuid-string",
      "title": "Notice Title",
      "excerpt": "Brief excerpt from notice..."
    }
  ]
}
```

## Navigation Flow

1. User taps "AI" tab in bottom navigation (HomeScreen)
2. Navigate to ChatScreen
3. ChatScreen auto-connects to WebSocket on init
4. User types query and taps send
5. User message appears immediately
6. AI response streams in with source chips
7. User taps source chip → Navigate to NoticeDetailScreen (TODO)
8. User navigates back → Chat connection maintained

## Dependency Injection

Registered in `injection_container.dart`:
```dart
void _initChat() {
  // Data sources
  sl.registerLazySingleton<ChatWebSocketDataSource>(
    () => ChatWebSocketDataSourceImpl(),
  );

  // Repository
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(webSocketDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => ConnectChatUseCase(sl<ChatRepository>()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl<ChatRepository>()));
  sl.registerLazySingleton(() => DisconnectChatUseCase(sl<ChatRepository>()));

  // BLoC
  sl.registerLazySingleton<ChatBloc>(
    () => ChatBloc(
      connectChat: sl<ConnectChatUseCase>(),
      sendMessage: sl<SendMessageUseCase>(),
      disconnectChat: sl<DisconnectChatUseCase>(),
    ),
  );
}
```

## Configuration

### API Endpoint
Update base URL in `lib/core/constants/api_endpoints.dart`:
```dart
static const String baseUrl = 'http://YOUR_SERVER:8000';
```

WebSocket URL is auto-generated from baseUrl (http → ws, https → wss).

### Deep Linking
Currently shows a snackbar when source chip is tapped. To implement navigation:

1. Create NoticeDetailScreen
2. Add route in router
3. Update `_handleSourceTap()` in ChatScreen:
```dart
void _handleSourceTap(SourceEntity source) {
  Navigator.pushNamed(
    context,
    RouteNames.noticeDetails,
    arguments: source.noticeId,
  );
}
```

## Testing

### Manual Testing
1. Start Django backend with WebSocket support
2. Run Flutter app
3. Tap "AI" tab
4. Verify connection (check for "Connected" state)
5. Type "What are the latest notices?" and send
6. Verify user message appears
7. Verify AI response appears with sources
8. Tap source chip, verify navigation/snackbar

### Backend Requirements
- Django Channels for WebSocket support
- `/ws/chat/` endpoint accepting connections
- RAG-powered AI responding with sources
- Notice database with UUID primary keys

## Error Handling

- **Connection Failure**: Shows error screen with retry button
- **Send Message Failure**: Removes optimistic user message, shows error snackbar
- **Empty Message**: Validated in use case, returns ValidationFailure
- **Network Issues**: Caught and converted to appropriate failure types

## Future Enhancements

1. Message persistence (local storage)
2. Chat history across sessions
3. Typing indicators
4. Message timestamps in UI
5. Copy message text functionality
6. Share chat functionality
7. Voice input support
8. Image attachments
9. Markdown rendering in messages
10. Search within chat history

## Files Created

### Domain
- `lib/features/chat/domain/entities/source_entity.dart`
- `lib/features/chat/domain/entities/chat_message_entity.dart`
- `lib/features/chat/domain/repositories/chat_repository.dart`
- `lib/features/chat/domain/usecases/connect_chat_usecase.dart`
- `lib/features/chat/domain/usecases/send_message_usecase.dart`
- `lib/features/chat/domain/usecases/disconnect_chat_usecase.dart`
- `lib/features/chat/domain/usecases/chat_usecases.dart` (barrel)

### Data
- `lib/features/chat/data/models/source_model.dart`
- `lib/features/chat/data/models/chat_message_model.dart`
- `lib/features/chat/data/data_sources/chat_websocket_data_source.dart`
- `lib/features/chat/data/repositories/chat_repository_impl.dart`

### Presentation
- `lib/features/chat/presentation/bloc/chat_bloc.dart`
- `lib/features/chat/presentation/bloc/chat_event.dart`
- `lib/features/chat/presentation/bloc/chat_state.dart`
- `lib/features/chat/presentation/pages/chat_screen.dart`
- `lib/features/chat/presentation/widgets/message_bubble.dart`
- `lib/features/chat/presentation/widgets/chat_widgets.dart` (barrel)

### Core Updates
- `lib/core/theme/theme.dart` - Added fontSizeBody and backgroundGradient constants
- `lib/core/di/injection_container.dart` - Added chat feature DI setup
- `lib/app/app.dart` - Added ChatBloc provider
- `lib/features/home/presentation/pages/home_screen.dart` - Added navigation to ChatScreen
