import 'dart:async';
import 'package:flutter/foundation.dart';
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
      debugPrint('SocketService: Already connected');
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

      debugPrint('SocketService: Connecting to $cleanUrl');
      debugPrint('SocketService: Token length: ${token.length}');

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
      debugPrint('SocketService: Connection status after delay: $_isConnected');
    } catch (e) {
      debugPrint('SocketService: Connection error - $e');
      _errorController.add('Gagal terhubung: $e');
    }
  }

  /// Setup semua event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      debugPrint('SocketService: ✅ Connected successfully!');
      _isConnected = true;
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      debugPrint('SocketService: ❌ Disconnected');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onConnectError((error) {
      debugPrint('SocketService: ⚠️ Connect error - $error');
      _isConnected = false;
      _connectionController.add(false);
      _errorController.add('Gagal terhubung ke server');
    });

    _socket!.onError((error) {
      debugPrint('SocketService: ⚠️ Socket error - $error');
      _errorController.add('Error: $error');
    });

    // Custom events
    _socket!.on('connected', (data) {
      debugPrint('SocketService: ✅ Server confirmed connection - $data');
      _isConnected = true;
      _connectionController.add(true);
    });

    _socket!.on('error', (data) {
      debugPrint('SocketService: Server error - $data');
      if (data is Map && data['message'] != null) {
        _errorController.add(data['message']);
      }
    });

    _socket!.on('joined_chat', (data) {
      debugPrint('SocketService: Joined chat - $data');
    });

    _socket!.on('left_chat', (data) {
      debugPrint('SocketService: Left chat - $data');
    });

    // New message event
    _socket!.on('new_message', (data) {
      debugPrint('SocketService: New message received - $data');
      try {
        if (data is Map && data['message'] != null) {
          final message = ChatMessage.fromJson(
            Map<String, dynamic>.from(data['message']),
          );
          _messageController.add(message);
        }
      } catch (e) {
        debugPrint('SocketService: Error parsing message - $e');
      }
    });

    // Typing indicator
    _socket!.on('user_typing', (data) {
      debugPrint('SocketService: User typing - $data');
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
      debugPrint('SocketService: Messages read - $data');
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
      debugPrint('SocketService: Cannot join chat - not connected');
      return;
    }

    // Leave previous room if any
    if (_currentOrderId != null && _currentOrderId != orderId) {
      leaveChat(_currentOrderId!);
    }

    _currentOrderId = orderId;
    _socket!.emit('join_chat', {'order_id': orderId});
    debugPrint('SocketService: Joining chat room for order $orderId');
  }

  /// Leave chat room
  void leaveChat(String orderId) {
    if (_socket == null) return;

    _socket!.emit('leave_chat', {'order_id': orderId});
    if (_currentOrderId == orderId) {
      _currentOrderId = null;
    }
    debugPrint('SocketService: Leaving chat room for order $orderId');
  }

  /// Kirim pesan via WebSocket
  void sendMessage(String orderId, String message) {
    if (_socket == null || !_isConnected) {
      _errorController.add('Tidak terhubung ke server');
      return;
    }

    _socket!.emit('send_message', {'order_id': orderId, 'message': message});
    debugPrint('SocketService: Sending message to order $orderId');
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
    debugPrint('SocketService: Disconnected and disposed');
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
