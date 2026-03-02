import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ecommerce_app/core/constants.dart';

/// WebSocket service for real-time updates from the backend.
/// Listens for user type changes and triggers UI refresh.
class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;
  Timer? _pingTimer;
  bool _isConnected = false;
  int _userId = 0;
  String _token = '';

  /// Stream of WebSocket events.
  Stream<Map<String, dynamic>>? get stream => _controller?.stream;

  bool get isConnected => _isConnected;

  /// Connect to WebSocket server.
  void connect(int userId, String token) {
    _userId = userId;
    _token = token;

    _controller = StreamController<Map<String, dynamic>>.broadcast();

    try {
      final uri = Uri.parse('${AppConstants.wsBaseUrl}/$userId?token=$token');
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String);
            _controller?.add(message);
          } catch (e) {
            // Ignore non-JSON messages
          }
        },
        onError: (error) {
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _scheduleReconnect();
        },
      );

      // Send ping every 30 seconds to keep connection alive
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_isConnected) {
          _channel?.sink.add('ping');
        }
      });
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  /// Request current user type from server via WebSocket.
  void requestUserType() {
    if (_isConnected) {
      _channel?.sink.add('request_type');
    }
  }

  /// Schedule reconnection after disconnect.
  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected && _userId > 0) {
        connect(_userId, _token);
      }
    });
  }

  /// Disconnect from WebSocket.
  void disconnect() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _controller?.close();
    _isConnected = false;
  }
}
