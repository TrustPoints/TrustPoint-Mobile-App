import 'dart:io';

/// Order Status Constants
class OrderStatus {
  static const String pending = 'PENDING';
  static const String claimed = 'CLAIMED';
  static const String inTransit = 'IN_TRANSIT';
  static const String delivered = 'DELIVERED';
  static const String cancelled = 'CANCELLED';

  /// Get display name for status
  static String getDisplayName(String status) {
    switch (status) {
      case pending:
        return 'Menunggu';
      case claimed:
        return 'Diambil';
      case inTransit:
        return 'Dalam Perjalanan';
      case delivered:
        return 'Terkirim';
      case cancelled:
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  /// Get status color
  static int getColor(String status) {
    switch (status) {
      case pending:
        return 0xFFFFB300; // Orange
      case claimed:
        return 0xFF2196F3; // Blue
      case inTransit:
        return 0xFF9C27B0; // Purple
      case delivered:
        return 0xFF00C853; // Green
      case cancelled:
        return 0xFFE53935; // Red
      default:
        return 0xFF9E9E9E; // Grey
    }
  }
}

/// Item Category Constants
class ItemCategory {
  static const String food = 'FOOD';
  static const String document = 'DOCUMENT';
  static const String electronics = 'ELECTRONICS';
  static const String fashion = 'FASHION';
  static const String grocery = 'GROCERY';
  static const String medicine = 'MEDICINE';
  static const String other = 'OTHER';

  /// Get display name
  static String getDisplayName(String category) {
    switch (category) {
      case food:
        return 'Makanan';
      case document:
        return 'Dokumen';
      case electronics:
        return 'Elektronik';
      case fashion:
        return 'Fashion';
      case grocery:
        return 'Groceries';
      case medicine:
        return 'Obat';
      case other:
        return 'Lainnya';
      default:
        return category;
    }
  }

  /// Get icon
  static String getIcon(String category) {
    switch (category) {
      case food:
        return '🍔';
      case document:
        return '📄';
      case electronics:
        return '📱';
      case fashion:
        return '👕';
      case grocery:
        return '🛒';
      case medicine:
        return '💊';
      case other:
        return '📦';
      default:
        return '📦';
    }
  }

  /// Get all categories
  static List<CategoryItem> getAll() {
    return [
      CategoryItem(code: food, name: 'Makanan', icon: '🍔'),
      CategoryItem(code: document, name: 'Dokumen', icon: '📄'),
      CategoryItem(code: electronics, name: 'Elektronik', icon: '📱'),
      CategoryItem(code: fashion, name: 'Fashion', icon: '👕'),
      CategoryItem(code: grocery, name: 'Groceries', icon: '🛒'),
      CategoryItem(code: medicine, name: 'Obat', icon: '💊'),
      CategoryItem(code: other, name: 'Lainnya', icon: '📦'),
    ];
  }
}

/// Category Item
class CategoryItem {
  final String code;
  final String name;
  final String icon;

  CategoryItem({required this.code, required this.name, required this.icon});

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '📦',
    );
  }
}

/// Coordinates Model
class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({required this.latitude, required this.longitude});

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

/// Location Model
class Location {
  final String address;
  final Coordinates coords;

  Location({required this.address, required this.coords});

  factory Location.fromJson(Map<String, dynamic> json) {
    // Handle GeoJSON format from backend
    final coordsJson = json['coords'] as Map<String, dynamic>?;
    Coordinates coords;

    if (coordsJson != null && coordsJson['coordinates'] != null) {
      // GeoJSON format: [longitude, latitude]
      final geoCoords = coordsJson['coordinates'] as List<dynamic>;
      coords = Coordinates(
        longitude: (geoCoords[0] as num).toDouble(),
        latitude: (geoCoords[1] as num).toDouble(),
      );
    } else {
      coords = Coordinates(latitude: 0, longitude: 0);
    }

    return Location(address: json['address'] as String? ?? '', coords: coords);
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': coords.latitude,
      'longitude': coords.longitude,
    };
  }
}

/// Item Model
class OrderItem {
  final String name;
  final String category;
  final double weight;
  final String? photoUrl;
  final String? description;
  final bool isFragile;

  OrderItem({
    required this.name,
    required this.category,
    required this.weight,
    this.photoUrl,
    this.description,
    required this.isFragile,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? ItemCategory.other,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      photoUrl: json['photo_url'] as String?,
      description: json['description'] as String?,
      isFragile: json['is_fragile'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'weight': weight,
      'photo_url': photoUrl,
      'description': description,
      'is_fragile': isFragile,
    };
  }

  String get categoryDisplayName => ItemCategory.getDisplayName(category);
  String get categoryIcon => ItemCategory.getIcon(category);
}

/// Order Model
class Order {
  final String id;
  final String orderId;
  final String senderId;
  final String? hunterId;
  final OrderItem item;
  final Location pickup;
  final Location destination;
  final Coordinates pickupCoordinates;
  final Coordinates destinationCoordinates;
  final double distanceKm;
  final int pointsCost; // Cost for sender
  final int trustPointsReward; // Reward for hunter
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? claimedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.orderId,
    required this.senderId,
    this.hunterId,
    required this.item,
    required this.pickup,
    required this.destination,
    required this.pickupCoordinates,
    required this.destinationCoordinates,
    required this.distanceKm,
    required this.pointsCost,
    required this.trustPointsReward,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.claimedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  /// Parse date from various formats
  static DateTime _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }

    try {
      // Try ISO 8601 format first
      return DateTime.parse(dateString);
    } catch (_) {
      try {
        // Try HTTP date format
        return HttpDate.parse(dateString);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  static DateTime? _parseDateNullable(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return null;
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    // Parse location
    final locationJson = json['location'] as Map<String, dynamic>?;
    Location pickup;
    Location destination;

    if (locationJson != null) {
      pickup = Location.fromJson(
        locationJson['pickup'] as Map<String, dynamic>? ?? {},
      );
      destination = Location.fromJson(
        locationJson['destination'] as Map<String, dynamic>? ?? {},
      );
    } else {
      pickup = Location(
        address: '',
        coords: Coordinates(latitude: 0, longitude: 0),
      );
      destination = Location(
        address: '',
        coords: Coordinates(latitude: 0, longitude: 0),
      );
    }

    // Parse simplified coordinates
    final pickupCoordsJson =
        json['pickup_coordinates'] as Map<String, dynamic>?;
    final destCoordsJson =
        json['destination_coordinates'] as Map<String, dynamic>?;

    return Order(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      hunterId: json['hunter_id'] as String?,
      item: OrderItem.fromJson(json['item'] as Map<String, dynamic>? ?? {}),
      pickup: pickup,
      destination: destination,
      pickupCoordinates: pickupCoordsJson != null
          ? Coordinates.fromJson(pickupCoordsJson)
          : pickup.coords,
      destinationCoordinates: destCoordsJson != null
          ? Coordinates.fromJson(destCoordsJson)
          : destination.coords,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      pointsCost: (json['points_cost'] as num?)?.toInt() ?? 0,
      trustPointsReward: (json['trust_points_reward'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? OrderStatus.pending,
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at'] as String?),
      updatedAt: _parseDate(json['updated_at'] as String?),
      claimedAt: _parseDateNullable(json['claimed_at'] as String?),
      pickedUpAt: _parseDateNullable(json['picked_up_at'] as String?),
      deliveredAt: _parseDateNullable(json['delivered_at'] as String?),
    );
  }

  /// Status helpers
  String get statusDisplayName => OrderStatus.getDisplayName(status);
  int get statusColor => OrderStatus.getColor(status);

  bool get isPending => status == OrderStatus.pending;
  bool get isClaimed => status == OrderStatus.claimed;
  bool get isInTransit => status == OrderStatus.inTransit;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isActive => isPending || isClaimed || isInTransit;
}

/// Map Marker Model for displaying on map
class OrderMapMarker {
  final String orderId;
  final Coordinates pickupCoordinates;
  final Coordinates destinationCoordinates;
  final String itemName;
  final String itemCategory;
  final double distanceKm;
  final int trustPointsReward;

  OrderMapMarker({
    required this.orderId,
    required this.pickupCoordinates,
    required this.destinationCoordinates,
    required this.itemName,
    required this.itemCategory,
    required this.distanceKm,
    required this.trustPointsReward,
  });

  factory OrderMapMarker.fromJson(Map<String, dynamic> json) {
    return OrderMapMarker(
      orderId: json['order_id'] as String? ?? '',
      pickupCoordinates: Coordinates.fromJson(
        json['pickup_coordinates'] as Map<String, dynamic>? ?? {},
      ),
      destinationCoordinates: Coordinates.fromJson(
        json['destination_coordinates'] as Map<String, dynamic>? ?? {},
      ),
      itemName: json['item_name'] as String? ?? '',
      itemCategory: json['item_category'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      trustPointsReward: (json['trust_points_reward'] as num?)?.toInt() ?? 0,
    );
  }

  String get categoryIcon => ItemCategory.getIcon(itemCategory);
}

/// Create Order Request Model
class CreateOrderRequest {
  final OrderItem item;
  final Location pickup;
  final Location destination;
  final double distanceKm;
  final String? notes;

  CreateOrderRequest({
    required this.item,
    required this.pickup,
    required this.destination,
    required this.distanceKm,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'item': item.toJson(),
      'location': {
        'pickup': pickup.toJson(),
        'destination': destination.toJson(),
      },
      'distance_km': distanceKm,
      'notes': notes,
    };
  }
}
