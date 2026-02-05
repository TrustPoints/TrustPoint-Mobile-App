import '../models/chat_model.dart';
import 'api_service.dart';

/// Chat Service - Handles all chat-related API calls
class ChatService {
  final ApiService _apiService = ApiService();

  /// Get all messages for an order
  Future<ChatResult> getMessages({
    required String token,
    required String orderId,
    int limit = 100,
    int skip = 0,
  }) async {
    final response = await _apiService.get(
      '/api/chat/$orderId/messages?limit=$limit&skip=$skip',
      token: token,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        final messagesJson = data['messages'] as List<dynamic>? ?? [];
        final messages = messagesJson
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();

        return ChatResult.success(
          messages: messages,
          message: response.data!['message'] as String?,
        );
      }
    }

    return ChatResult.error(
      message:
          response.data?['message'] as String? ??
          response.message ??
          'Gagal mengambil pesan',
    );
  }

  /// Send a message
  Future<SendMessageResult> sendMessage({
    required String token,
    required String orderId,
    required String message,
  }) async {
    final response = await _apiService.post(
      '/api/chat/$orderId/send',
      body: {'message': message},
      token: token,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      final messageData = data?['message'] as Map<String, dynamic>?;
      if (messageData != null) {
        return SendMessageResult.success(
          chatMessage: ChatMessage.fromJson(messageData),
          message: response.data!['message'] as String?,
        );
      }
    }

    return SendMessageResult.error(
      message:
          response.data?['message'] as String? ??
          response.message ??
          'Gagal mengirim pesan',
    );
  }

  /// Get unread message count
  Future<int> getUnreadCount({
    required String token,
    required String orderId,
  }) async {
    final response = await _apiService.get(
      '/api/chat/$orderId/unread',
      token: token,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      return data?['unread_count'] as int? ?? 0;
    }

    return 0;
  }

  /// Mark all messages as read
  Future<bool> markAsRead({
    required String token,
    required String orderId,
  }) async {
    final response = await _apiService.put(
      '/api/chat/$orderId/read',
      token: token,
    );

    return response.success;
  }
}
