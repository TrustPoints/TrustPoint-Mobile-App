import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

/// Order Provider - State management for orders
class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  // State
  bool _isLoading = false;
  String? _error;
  List<Order> _availableOrders = [];
  List<Order> _myOrders = [];
  List<Order> _myDeliveries = [];
  List<OrderMapMarker> _mapMarkers = [];
  Order? _currentOrder;
  int _totalAvailable = 0;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Order> get availableOrders => _availableOrders;
  List<Order> get myOrders => _myOrders;
  List<Order> get myDeliveries => _myDeliveries;
  List<OrderMapMarker> get mapMarkers => _mapMarkers;
  Order? get currentOrder => _currentOrder;
  int get totalAvailable => _totalAvailable;

  // Filtered getters
  List<Order> get pendingOrders => _myOrders.where((o) => o.isPending).toList();
  List<Order> get activeOrders => _myOrders.where((o) => o.isActive).toList();
  List<Order> get completedOrders =>
      _myOrders.where((o) => o.isDelivered).toList();
  List<Order> get activeDeliveries =>
      _myDeliveries.where((o) => o.isClaimed || o.isInTransit).toList();
  List<Order> get completedDeliveries =>
      _myDeliveries.where((o) => o.isDelivered).toList();

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Create order (Sender)
  Future<OrderResult> createOrder({
    required String token,
    required CreateOrderRequest request,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _orderService.createOrder(
        token: token,
        request: request,
      );

      if (result.success && result.order != null) {
        _myOrders.insert(0, result.order!);
        _currentOrder = result.order;
      } else {
        _setError(result.message);
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Terjadi kesalahan: ${e.toString()}');
      _setLoading(false);
      return OrderResult.error(message: _error!);
    }
  }

  /// Load available orders for Hunter
  Future<void> loadAvailableOrders({
    required String token,
    int limit = 50,
    int skip = 0,
    bool refresh = false,
  }) async {
    if (refresh) {
      _availableOrders = [];
      _mapMarkers = [];
    }

    _setLoading(true);
    _setError(null);

    try {
      final result = await _orderService.getAvailableOrders(
        token: token,
        limit: limit,
        skip: skip,
      );

      if (result.success) {
        if (refresh || skip == 0) {
          _availableOrders = result.orders;
          _mapMarkers = result.mapMarkers;
        } else {
          _availableOrders.addAll(result.orders);
          _mapMarkers.addAll(result.mapMarkers);
        }
        _totalAvailable = result.total;
      } else {
        _setError(result.message);
      }

      _setLoading(false);
    } catch (e) {
      _setError('Terjadi kesalahan: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Load nearby orders (Geospatial)
  Future<void> loadNearbyOrders({
    required String token,
    required double latitude,
    required double longitude,
    double radius = 10,
    int limit = 50,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _orderService.getNearbyOrders(
        token: token,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        limit: limit,
      );

      if (result.success) {
        _availableOrders = result.orders;
        _mapMarkers = result.mapMarkers;
        _totalAvailable = result.total;
      } else {
        _setError(result.message);
      }

      _setLoading(false);
    } catch (e) {
      _setError('Terjadi kesalahan: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Get order detail
  Future<OrderResult> getOrderDetail({
    required String token,
    required String orderId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _orderService.getOrderDetail(
        token: token,
        orderId: orderId,
      );

      if (result.success && result.order != null) {
        _currentOrder = result.order;
      } else {
        _setError(result.message);
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Terjadi kesalahan: ${e.toString()}');
      _setLoading(false);
      return OrderResult.error(message: _error!);
    }
  }

  /// Claim order (Hunter)
  Future<OrderResult> claimOrder({
    required String token,
    required String orderId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _orderService.claimOrder(
        token: token,
        orderId: orderId,
      );

      if (result.success && result.order != null) {
        // Remove from available orders
        _availableOrders.removeWhere((o) => o.orderId == orderId);
        _mapMarkers.removeWhere((m) => m.orderId == orderId);
        // Add to my deliveries
        _myDeliveries.insert(0, result.order!);
        _currentOrder = result.order;
        _totalAvailable--;
      } else {
        _setError(result.message);
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Terjadi kesalahan: ${e.toString()}');
      _setLoading(false);
      return OrderResult.error(message: _error!);
    }
  }

  /// Pickup order (Hunter - start delivery)
  Future<OrderResult> pickupOrder({
    required String token,
    required String orderId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _orderService.pickupOrder(
        token: token,
        orderId: orderId,
      );

      if (result.success && result.order != null) {
        _updateOrderInList(result.order!);
        _currentOrder = result.order;
      } else {
        _setError(result.message);
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Terjadi kesalahan: ${e.toString()}');
      _setLoading(false);
      return OrderResult.error(message: _error!);
    }
  }

  /// Deliver order (Hunter - complete)
  Future<DeliveryResult> deliverOrder({
    required String token,
    required String orderId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _orderService.deliverOrder(
        token: token,
        orderId: orderId,
      );

      if (result.success && result.order != null) {
        _updateOrderInList(result.order!);
        _currentOrder = result.order;
      } else {
        _setError(result.message);
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Terjadi kesalahan: ${e.toString()}');
      _setLoading(false);
      return DeliveryResult.error(message: _error!);
    }
  }

  /// Cancel order (Sender)
  Future<OrderResult> cancelOrder({
    required String token,
    required String orderId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _orderService.cancelOrder(
        token: token,
        orderId: orderId,
      );

      if (result.success && result.order != null) {
        _updateOrderInList(result.order!);
        _currentOrder = result.order;
      } else {
        _setError(result.message);
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Terjadi kesalahan: ${e.toString()}');
      _setLoading(false);
      return OrderResult.error(message: _error!);
    }
  }

  /// Load my orders (as Sender)
  Future<void> loadMyOrders({
    required String token,
    String? status,
    bool refresh = false,
  }) async {
    if (refresh) {
      _myOrders = [];
    }

    _setLoading(true);
    _setError(null);

    try {
      final result = await _orderService.getMyOrders(
        token: token,
        status: status,
      );

      if (result.success) {
        _myOrders = result.orders;
      } else {
        _setError(result.message);
      }

      _setLoading(false);
    } catch (e) {
      _setError('Terjadi kesalahan: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Load my deliveries (as Hunter)
  Future<void> loadMyDeliveries({
    required String token,
    String? status,
    bool refresh = false,
  }) async {
    if (refresh) {
      _myDeliveries = [];
    }

    _setLoading(true);
    _setError(null);

    try {
      final result = await _orderService.getMyDeliveries(
        token: token,
        status: status,
      );

      if (result.success) {
        _myDeliveries = result.orders;
      } else {
        _setError(result.message);
      }

      _setLoading(false);
    } catch (e) {
      _setError('Terjadi kesalahan: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Helper: Update order in lists
  void _updateOrderInList(Order updatedOrder) {
    // Update in myOrders
    final myOrderIndex = _myOrders.indexWhere(
      (o) => o.orderId == updatedOrder.orderId,
    );
    if (myOrderIndex != -1) {
      _myOrders[myOrderIndex] = updatedOrder;
    }

    // Update in myDeliveries
    final deliveryIndex = _myDeliveries.indexWhere(
      (o) => o.orderId == updatedOrder.orderId,
    );
    if (deliveryIndex != -1) {
      _myDeliveries[deliveryIndex] = updatedOrder;
    }

    // Update in availableOrders
    final availableIndex = _availableOrders.indexWhere(
      (o) => o.orderId == updatedOrder.orderId,
    );
    if (availableIndex != -1) {
      if (updatedOrder.isPending) {
        _availableOrders[availableIndex] = updatedOrder;
      } else {
        _availableOrders.removeAt(availableIndex);
        _mapMarkers.removeWhere((m) => m.orderId == updatedOrder.orderId);
        _totalAvailable--;
      }
    }

    notifyListeners();
  }

  /// Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  /// Clear all data (on logout)
  void clearAll() {
    _isLoading = false;
    _error = null;
    _availableOrders = [];
    _myOrders = [];
    _myDeliveries = [];
    _mapMarkers = [];
    _currentOrder = null;
    _totalAvailable = 0;
    notifyListeners();
  }
}
