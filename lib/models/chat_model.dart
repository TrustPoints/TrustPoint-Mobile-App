/// Chat Message Model for TrustPoints
class ChatMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String senderName;
  final String message;
  final String messageType;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? 'Unknown',
      message: json['message'] as String? ?? '',
      messageType: json['message_type'] as String? ?? 'text',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'message_type': messageType,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isSystemMessage => messageType == 'system';

  /// Check if this message is from the given user
  bool isFromUser(String userId) => senderId == userId;
}

/// Chat Result for API responses
class ChatResult {
  final bool success;
  final List<ChatMessage> messages;
  final String? message;
  final int? unreadCount;

  ChatResult({
    required this.success,
    this.messages = const [],
    this.message,
    this.unreadCount,
  });

  factory ChatResult.success({
    required List<ChatMessage> messages,
    String? message,
  }) {
    return ChatResult(success: true, messages: messages, message: message);
  }

  factory ChatResult.error({required String message}) {
    return ChatResult(success: false, message: message);
  }
}

/// Send Message Result
class SendMessageResult {
  final bool success;
  final ChatMessage? chatMessage;
  final String? message;

  SendMessageResult({required this.success, this.chatMessage, this.message});

  factory SendMessageResult.success({
    required ChatMessage chatMessage,
    String? message,
  }) {
    return SendMessageResult(
      success: true,
      chatMessage: chatMessage,
      message: message,
    );
  }

  factory SendMessageResult.error({required String message}) {
    return SendMessageResult(success: false, message: message);
  }
}
