import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_model.dart';
import '../services/auth_service.dart';

/// Service untuk mengelola koneksi WebSocket untuk chat realtime
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final AuthService _authService = AuthService();

  // Connection state
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Current chat room
  String? _currentOrderId;

  // Stream controllers for events
  final _connectionController = StreamController<bool>.broadcast();
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _readController = StreamController<ReadEvent>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Public streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<TypingEvent> get typingStream => _typingController.stream;
  Stream<ReadEvent> get readStream => _readController.stream;
  Stream<String> get errorStream => _errorController.stream;

  /// Inisialisasi dan koneksi ke WebSocket server
  Future<void> connect({required String baseUrl}) async {
    if (_isConnected && _socket != null) {
      return;
    }

    try {
      // Disconnect existing socket first
      if (_socket != null) {
        _socket!.dispose();
        _socket = null;
      }

      // Get auth token
      final token = await _authService.getToken();
      if (token == null) {
        _errorController.add('Token tidak ditemukan');
        return;
      }

      // Clean up baseUrl - remove trailing slash and /api if present
      String cleanUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      if (cleanUrl.endsWith('/api')) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 4);
      }

      // Create socket connection with token in both auth and query
      _socket = IO.io(
        cleanUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .setQuery({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(5000)
            .setTimeout(10000)
            .build(),
      );

      // Setup event listeners
      _setupEventListeners();

      // Connect
      _socket!.connect();

      // Wait a bit to check connection status
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      _errorController.add('Gagal terhubung: $e');
    }
  }

  /// Setup semua event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _isConnected = true;
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      _connectionController.add(false);
      _errorController.add('Gagal terhubung ke server');
    });

    _socket!.onError((error) {
      _errorController.add('Error: $error');
    });

    // Custom events
    _socket!.on('connected', (data) {
      _isConnected = true;
      _connectionController.add(true);
    });

    _socket!.on('error', (data) {
      if (data is Map && data['message'] != null) {
        _errorController.add(data['message']);
      }
    });

    _socket!.on('joined_chat', (data) {
      // Chat joined successfully
    });

    _socket!.on('left_chat', (data) {
      // Chat left successfully
    });

    // New message event
    _socket!.on('new_message', (data) {
      try {
        if (data is Map && data['message'] != null) {
          final message = ChatMessage.fromJson(
            Map<String, dynamic>.from(data['message']),
          );
          _messageController.add(message);
        }
      } catch (e) {
        // Error parsing message - silently ignore
      }
    });

    // Typing indicator
    _socket!.on('user_typing', (data) {
      if (data is Map) {
        final event = TypingEvent(
          orderId: data['order_id'] ?? '',
          userId: data['user_id'] ?? '',
          isTyping: data['is_typing'] ?? false,
        );
        _typingController.add(event);
      }
    });

    // Messages read
    _socket!.on('messages_read', (data) {
      if (data is Map) {
        final event = ReadEvent(
          orderId: data['order_id'] ?? '',
          readerId: data['reader_id'] ?? '',
        );
        _readController.add(event);
      }
    });
  }

  /// Join chat room untuk order tertentu
  void joinChat(String orderId) {
    if (_socket == null || !_isConnected) {
      return;
    }

    // Leave previous room if any
    if (_currentOrderId != null && _currentOrderId != orderId) {
      leaveChat(_currentOrderId!);
    }

    _currentOrderId = orderId;
    _socket!.emit('join_chat', {'order_id': orderId});
  }

  /// Leave chat room
  void leaveChat(String orderId) {
    if (_socket == null) return;

    _socket!.emit('leave_chat', {'order_id': orderId});
    if (_currentOrderId == orderId) {
      _currentOrderId = null;
    }
  }

  /// Kirim pesan via WebSocket
  void sendMessage(String orderId, String message) {
    if (_socket == null || !_isConnected) {
      _errorController.add('Tidak terhubung ke server');
      return;
    }

    _socket!.emit('send_message', {'order_id': orderId, 'message': message});
  }

  /// Kirim typing indicator
  void sendTyping(String orderId, bool isTyping) {
    if (_socket == null || !_isConnected) return;

    _socket!.emit('typing', {'order_id': orderId, 'is_typing': isTyping});
  }

  /// Mark messages as read
  void markAsRead(String orderId) {
    if (_socket == null || !_isConnected) return;

    _socket!.emit('mark_read', {'order_id': orderId});
  }

  /// Disconnect dari server
  void disconnect() {
    if (_currentOrderId != null) {
      leaveChat(_currentOrderId!);
    }

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Dispose semua resources
  void dispose() {
    disconnect();
    _connectionController.close();
    _messageController.close();
    _typingController.close();
    _readController.close();
    _errorController.close();
  }
}

/// Event untuk typing indicator
class TypingEvent {
  final String orderId;
  final String userId;
  final bool isTyping;

  TypingEvent({
    required this.orderId,
    required this.userId,
    required this.isTyping,
  });
}

/// Event untuk messages read
class ReadEvent {
  final String orderId;
  final String readerId;

  ReadEvent({required this.orderId, required this.readerId});
}
