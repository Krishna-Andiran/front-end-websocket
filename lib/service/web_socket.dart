import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';

class WebSocketManager {
  final log = Logger();
  late WebSocketChannel _channel;
  bool _isConnected = false;

  Function(String)? onMessageReceived; // Callback for receiving messages

  void connect(String userId) {
    if (_isConnected) {
      log.d("Already connected");
      return;
    }

    _channel = WebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:8000/ws/$userId'),
    );

    // Listen for messages from the server
    _channel.stream.listen(
      (message) {
        log.d('Received message: $message');
        if (onMessageReceived != null) {
          onMessageReceived!(message); // Trigger the callback
        }
      },
      onDone: () {
        log.d('WebSocket connection closed');
        _isConnected = false;
      },
      onError: (error) {
        log.e('WebSocket error:', error: error);
        _isConnected = false;
      },
    );

    _isConnected = true;
    _isConnected
        ? log.d("Connected to WebSocket with user ID: $userId")
        : log.d("Not Connected to WebSocket with user ID: $userId");
  }

  /// Sends a message through the WebSocket connection.
  void sendMessage(String message) {
    if (_isConnected) {
      _channel.sink.add(message);
      log.d("Sent message: $message");
    } else {
      log.e("WebSocket is not connected");
    }
  }

  /// Disconnects the WebSocket connection.
  void disconnect() {
    if (_isConnected) {
      _channel.sink.close();
      _isConnected = false;
      log.d("Disconnected from WebSocket");
    } else {
      log.d("WebSocket is already disconnected");
    }
  }

  /// Check if WebSocket is connected.
  bool get isConnected => _isConnected;
}
