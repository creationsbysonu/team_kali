import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sewa_sathi/core/constants/api_endpoints.dart';
import 'package:sewa_sathi/core/errors/exceptions.dart';
import 'package:sewa_sathi/features/chat/data/models/chat_message_model.dart';
import 'package:sewa_sathi/features/chat/data/models/source_model.dart';

/// Connection states for WebSocket
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  error,
  failed,
}

/// Abstract data source for chat WebSocket operations.
abstract class ChatWebSocketDataSource {
  /// Connect to WebSocket.
  Future<void> connect({String? accessToken});

  /// Send query message.
  Future<void> sendMessage(String query, {String? sessionId});

  /// Stream of incoming messages.
  Stream<ChatMessageModel> get messages;

  /// Stream of connection state changes.
  Stream<WebSocketConnectionState> get connectionState;

  /// Check if connected.
  bool get isConnected;

  /// Disconnect from WebSocket.
  Future<void> disconnect();

  /// Dispose resources.
  void dispose();
}

/// Implementation of ChatWebSocketDataSource using web_socket_channel.
/// Supports ping/pong keep-alive and automatic reconnection.
class ChatWebSocketDataSourceImpl implements ChatWebSocketDataSource {
  WebSocketChannel? _channel;
  final StreamController<ChatMessageModel> _messageController =
      StreamController<ChatMessageModel>.broadcast();
  final StreamController<WebSocketConnectionState> _connectionStateController =
      StreamController<WebSocketConnectionState>.broadcast();

  bool _isConnected = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  String? _accessToken;

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<ChatMessageModel> get messages => _messageController.stream;

  @override
  Stream<WebSocketConnectionState> get connectionState =>
      _connectionStateController.stream;

  @override
  Future<void> connect({String? accessToken}) async {
    if (_isConnected) {
      return; // Already connected
    }

    _accessToken = accessToken;
    _connectionStateController.add(WebSocketConnectionState.connecting);

    try {
      // Build WebSocket URL
      final wsUrl = ApiEndpoints.baseUrl
          .replaceAll('http://', 'ws://')
          .replaceAll('https://', 'wss://');

      String url = '$wsUrl/ws/chat/';

      // Add token if authenticated
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        url = '$url?token=$_accessToken';
      }

      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Listen to incoming messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStateController.add(WebSocketConnectionState.connected);

      // Start ping timer to keep connection alive
      _startPingTimer();
    } catch (e) {
      _isConnected = false;
      _connectionStateController.add(WebSocketConnectionState.error);
      _scheduleReconnect();
      throw ServerException(message: 'Failed to connect to chat: $e');
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final type = json['type'] as String?;

      switch (type) {
        case 'connected':
          // Connection acknowledgment
          _messageController.add(
            ChatMessageModel(
              id: 'system-${DateTime.now().millisecondsSinceEpoch}',
              text: json['message'] as String? ?? 'Connected to AI Assistant',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          break;

        case 'pong':
          // Ping response - connection is alive, no action needed
          break;

        case 'typing':
          // Server is processing - could show typing indicator
          break;

        case 'error':
          final errorMessage = json['error'] as String? ?? 'Unknown error';
          _messageController.add(ChatMessageModel.error(errorMessage));
          break;

        case 'response':
        default:
          // Parse AI response
          final List<SourceModel> sources = [];
          if (json['sources'] != null) {
            for (final source in json['sources'] as List) {
              sources.add(SourceModel.fromJson(source as Map<String, dynamic>));
            }
          }

          _messageController.add(
            ChatMessageModel.aiResponse(
              text: json['response'] as String? ?? '',
              sources: sources,
            ),
          );
          break;
      }
    } catch (e) {
      _messageController.add(
        ChatMessageModel.error('Failed to parse response'),
      );
    }
  }

  void _handleError(dynamic error) {
    _isConnected = false;
    _connectionStateController.add(WebSocketConnectionState.error);
    _messageController.add(ChatMessageModel.error('Connection error'));
    _scheduleReconnect();
  }

  void _handleDone() {
    _isConnected = false;
    _connectionStateController.add(WebSocketConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    // Send ping every 25 seconds to keep connection alive
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _sendPing();
    });
  }

  void _sendPing() {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode({'type': 'ping'}));
      } catch (e) {
        // Ping failed, connection might be dead
        _handleDone();
      }
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _connectionStateController.add(WebSocketConnectionState.failed);
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    final delay = Duration(seconds: 1 << _reconnectAttempts);

    _reconnectTimer = Timer(delay, () {
      connect(accessToken: _accessToken);
    });
  }

  @override
  Future<void> sendMessage(String query, {String? sessionId}) async {
    if (!_isConnected || _channel == null) {
      throw ServerException(message: 'Not connected to chat server');
    }

    try {
      final message = jsonEncode({
        'query': query,
        if (sessionId != null) 'session_id': sessionId,
      });
      _channel!.sink.add(message);
    } catch (e) {
      throw ServerException(message: 'Failed to send message: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();

    try {
      await _channel?.sink.close();
      _isConnected = false;
      _connectionStateController.add(WebSocketConnectionState.disconnected);
    } catch (e) {
      throw ServerException(message: 'Failed to disconnect: $e');
    }
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    _connectionStateController.close();
    _isConnected = false;
  }
}
