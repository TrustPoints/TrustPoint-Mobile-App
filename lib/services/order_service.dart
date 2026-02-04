import '../models/order_model.dart';
import 'api_service.dart';

/// Order Service - Handles all order-related API calls
class OrderService {
  final ApiService _apiService = ApiService();

  /// Create a new order (Sender)
  Future<OrderResult> createOrder({
    required String token,
    required CreateOrderRequest request,
  }) async {
    final response = await _apiService.post(
      '/orders',
      body: request.toJson(),
      token: token,
    );

    if (response.success && response.data != null) {
      final orderData =
          response.data!['data']?['order'] as Map<String, dynamic>?;
      if (orderData != null) {
        return OrderResult.success(
          order: Order.fromJson(orderData),
          message:
              response.data!['message'] as String? ?? 'Pesanan berhasil dibuat',
        );
      }
    }

    return OrderResult.error(
      message:
          response.data?['message'] as String? ??
          response.message ??
          'Gagal membuat pesanan',
      errors: _extractErrors(response.data),
    );
  }

  /// Get available orders (Hunter - for map/list)
  Future<OrderListResult> getAvailableOrders({
    required String token,
    int limit = 50,
    int skip = 0,
  }) async {
    final response = await _apiService.get(
      '/orders/available?limit=$limit&skip=$skip',
      token: token,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        final ordersJson = data['orders'] as List<dynamic>? ?? [];
        final markersJson = data['map_markers'] as List<dynamic>? ?? [];

        final orders = ordersJson
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
        final markers = markersJson
            .map((e) => OrderMapMarker.fromJson(e as Map<String, dynamic>))
            .toList();

        return OrderListResult.success(
          orders: orders,
          mapMarkers: markers,
          total: data['total'] as int? ?? orders.length,
          message: response.data!['message'] as String?,
        );
      }
    }

    return OrderListResult.error(
      message:
          response.data?['message'] as String? ??
          response.message ??
          'Gagal mengambil pesanan',
    );
  }

  /// Get nearby orders (Geospatial search)
  Future<OrderListResult> getNearbyOrders({
    required String token,
    required double latitude,
    required double longitude,
    double radius = 10,
    int limit = 50,
  }) async {
    final response = await _apiService.get(
      '/orders/nearby?lat=$latitude&lng=$longitude&radius=$radius&limit=$limit',
      token: token,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        final ordersJson = data['orders'] as List<dynamic>? ?? [];
        final markersJson = data['map_markers'] as List<dynamic>? ?? [];

        final orders = ordersJson
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
        final markers = markersJson
            .map((e) => OrderMapMarker.fromJson(e as Map<String, dynamic>))
            .toList();

        return OrderListResult.success(
          orders: orders,
          mapMarkers: markers,
          total: data['count'] as int? ?? orders.length,
          message: response.data!['message'] as String?,
        );
      }
    }

    return OrderListResult.error(
      message:
          response.data?['message'] as String? ??
          response.message ??
          'Gagal mencari pesanan terdekat',
    );
  }

  /// Get order detail
  Future<OrderResult> getOrderDetail({
    required String token,
    required String orderId,
  }) async {
    final response = await _apiService.get('/orders/$orderId', token: token);

    if (response.success && response.data != null) {
      final orderData =
          response.data!['data']?['order'] as Map<String, dynamic>?;
      if (orderData != null) {
        return OrderResult.success(
          order: Order.fromJson(orderData),
          message: response.data!['message'] as String?,
        );
      }
    }

    return OrderResult.error(
      message:
          response.data?['message'] as String? ??
          response.message ??
          'Pesanan tidak ditemukan',
    );
  }

  /// Claim order (Hunter)
  Future<OrderResult> claimOrder({
    required String token,
    required String orderId,
  }) async {
    final response = await _apiService.put(
      '/orders/claim/$orderId',
      token: token,
    );

    if (response.success && response.data != null) {
      final orderData =
          response.data!['data']?['order'] as Map<String, dynamic>?;
      if (orderData != null) {
        return OrderResult.success(
          order: Order.fromJson(orderData),
          message:
              response.data!['message'] as String? ??
              'Pesanan berhasil diambil',
        );
      }
    }

    return OrderResult.error(
      message:
          response.data?['message'] as String? ??
          response.message ??
          'Gagal mengambil pesanan',
    );
  }

  /// Pickup order (Hunter - start delivery)
  Future<OrderResult> pickupOrder({
    required String token,
    required String orderId,
  }) async {
    final response = await _apiService.put(
      '/orders/pickup/$orderId',
      token: token,
    );

    if (response.success && response.data != null) {
      final orderData =
          response.data!['data']?['order'] as Map<String, dynamic>?;
      if (orderData != null) {
        return OrderResult.success(
          order: Order.fromJson(orderData),
          message: response.data!['message'] as String? ?? 'Pengiriman dimulai',
        );
      }
    }

    return OrderResult.error(
      message:
          response.data?['message'] as String? ??
          response.message ??
          'Gagal memulai pengiriman',
    );
  }

  /// Deliver order (Hunter - complete delivery)
  Future<DeliveryResult> deliverOrder({
    required String token,
    required String orderId,
  }) async {
    final response = await _apiService.put(
      '/orders/deliver/$orderId',
      token: token,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      final orderData = data?['order'] as Map<String, dynamic>?;
      if (orderData != null) {
        return DeliveryResult.success(
          order: Order.fromJson(orderData),
          trustPointsEarned: data?['trust_points_earned'] as int? ?? 0,
          message: response.data!['message'] as String? ?? 'Pengiriman selesai',
        );
      }
    }

    return DeliveryResult.error(
      message:
          response.data?['message'] as String? ??
          response.message ??
          'Gagal menyelesaikan pengiriman',
    );
  }

  /// Cancel order (Sender)
  Future<OrderResult> cancelOrder({
    required String token,
    required String orderId,
  }) async {
    final response = await _apiService.put(
      '/orders/cancel/$orderId',
      token: token,
    );

    if (response.success && response.data != null) {
      final orderData =
          response.data!['data']?['order'] as Map<String, dynamic>?;
      if (orderData != null) {
        return OrderResult.success(
          order: Order.fromJson(orderData),
          message: response.data!['message'] as String? ?? 'Pesanan dibatalkan',
        );
      }
    }

    return OrderResult.error(
      message:
          response.data?['message'] as String? ??
          response.message ??
          'Gagal membatalkan pesanan',
    );
  }

  /// Get my orders (as Sender)
  Future<OrderListResult> getMyOrders({
    required String token,
    String? status,
    int limit = 50,
    int skip = 0,
  }) async {
    String endpoint = '/orders/my-orders?limit=$limit&skip=$skip';
    if (status != null) {
      endpoint += '&status=$status';
    }

    final response = await _apiService.get(endpoint, token: token);

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        final ordersJson = data['orders'] as List<dynamic>? ?? [];
        final orders = ordersJson
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();

        return OrderListResult.success(
          orders: orders,
          total: data['count'] as int? ?? orders.length,
          message: response.data!['message'] as String?,
        );
      }
    }

    return OrderListResult.error(
      message:
          response.data?['message'] as String? ??
          response.message ??
          'Gagal mengambil pesanan',
    );
  }

  /// Get my deliveries (as Hunter)
  Future<OrderListResult> getMyDeliveries({
    required String token,
    String? status,
    int limit = 50,
    int skip = 0,
  }) async {
    String endpoint = '/orders/my-deliveries?limit=$limit&skip=$skip';
    if (status != null) {
      endpoint += '&status=$status';
    }

    final response = await _apiService.get(endpoint, token: token);

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        final ordersJson = data['orders'] as List<dynamic>? ?? [];
        final orders = ordersJson
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();

        return OrderListResult.success(
          orders: orders,
          total: data['count'] as int? ?? orders.length,
          message: response.data!['message'] as String?,
        );
      }
    }

    return OrderListResult.error(
      message:
          response.data?['message'] as String? ??
          response.message ??
          'Gagal mengambil pengiriman',
    );
  }

  /// Get categories
  Future<List<CategoryItem>> getCategories() async {
    final response = await _apiService.get('/orders/categories');

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      final categoriesJson = data?['categories'] as List<dynamic>? ?? [];
      return categoriesJson
          .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Return default categories on error
    return ItemCategory.getAll();
  }

  /// Helper to extract validation errors
  List<String>? _extractErrors(Map<String, dynamic>? data) {
    if (data == null) return null;
    final errors = data['errors'] as List<dynamic>?;
    return errors?.map((e) => e.toString()).toList();
  }
}

/// Result class for single order operations
class OrderResult {
  final bool success;
  final Order? order;
  final String? message;
  final List<String>? errors;

  OrderResult._({required this.success, this.order, this.message, this.errors});

  factory OrderResult.success({required Order order, String? message}) {
    return OrderResult._(success: true, order: order, message: message);
  }

  factory OrderResult.error({required String message, List<String>? errors}) {
    return OrderResult._(success: false, message: message, errors: errors);
  }
}

/// Result class for order list operations
class OrderListResult {
  final bool success;
  final List<Order> orders;
  final List<OrderMapMarker> mapMarkers;
  final int total;
  final String? message;

  OrderListResult._({
    required this.success,
    this.orders = const [],
    this.mapMarkers = const [],
    this.total = 0,
    this.message,
  });

  factory OrderListResult.success({
    required List<Order> orders,
    List<OrderMapMarker>? mapMarkers,
    int? total,
    String? message,
  }) {
    return OrderListResult._(
      success: true,
      orders: orders,
      mapMarkers: mapMarkers ?? [],
      total: total ?? orders.length,
      message: message,
    );
  }

  factory OrderListResult.error({required String message}) {
    return OrderListResult._(success: false, message: message);
  }
}

/// Result class for delivery completion (includes trust points)
class DeliveryResult {
  final bool success;
  final Order? order;
  final int trustPointsEarned;
  final String? message;

  DeliveryResult._({
    required this.success,
    this.order,
    this.trustPointsEarned = 0,
    this.message,
  });

  factory DeliveryResult.success({
    required Order order,
    required int trustPointsEarned,
    String? message,
  }) {
    return DeliveryResult._(
      success: true,
      order: order,
      trustPointsEarned: trustPointsEarned,
      message: message,
    );
  }

  factory DeliveryResult.error({required String message}) {
    return DeliveryResult._(success: false, message: message);
  }
}
