import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import 'order_chat_screen.dart';
import 'widgets/order_widgets.dart';

/// Order Detail Screen
class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final bool isHunterView;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.isHunterView = false,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderDetail();
    });
  }

  Future<void> _loadOrderDetail() async {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (authProvider.token != null) {
      await orderProvider.getOrderDetail(
        token: authProvider.token!,
        orderId: widget.orderId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading && orderProvider.currentOrder == null) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryStart),
              ),
            );
          }

          final order = orderProvider.currentOrder;
          if (order == null) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Pesanan Tidak Ditemukan',
              subtitle: orderProvider.error ?? 'Silakan coba lagi nanti.',
              buttonText: 'Kembali',
              onButtonPressed: () => Navigator.pop(context),
            );
          }

          return LoadingOverlay(
            isLoading: orderProvider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID & Status
                  _OrderHeader(order: order),
                  const SizedBox(height: 16),

                  // Item Info
                  _SectionCard(
                    title: 'Informasi Barang',
                    child: _ItemInfo(order: order),
                  ),
                  const SizedBox(height: 16),

                  // Location Info
                  _SectionCard(
                    title: 'Lokasi',
                    child: _LocationInfo(order: order),
                  ),
                  const SizedBox(height: 16),

                  // Tracking Map (show when order is in progress)
                  if (order.status == OrderStatus.claimed ||
                      order.status == OrderStatus.inTransit) ...[
                    _SectionCard(
                      title: 'Tracking Pengiriman',
                      child: _TrackingMap(order: order),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Chat Section (show when order has hunter)
                  if (order.hunterId != null &&
                      order.status != OrderStatus.cancelled) ...[
                    _ChatSection(
                      orderId: order.id,
                      orderDisplayId: order.orderId,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Notes (if any)
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Catatan',
                      child: Text(
                        order.notes!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Timeline
                  _SectionCard(
                    title: 'Status Pengiriman',
                    child: _OrderTimeline(order: order),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _ActionButtons(
                    order: order,
                    isHunterView: widget.isHunterView,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Order Header Widget
class _OrderHeader extends StatelessWidget {
  final Order order;

  const _OrderHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order ID',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      order.orderId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Color(order.statusColor).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.statusDisplayName,
                  style: TextStyle(
                    color: Color(order.statusColor),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeaderStat(
                icon: Icons.straighten,
                label: 'Jarak',
                value: '${order.distanceKm.toStringAsFixed(1)} km',
              ),
              const SizedBox(width: 24),
              _HeaderStat(
                icon: Icons.scale,
                label: 'Berat',
                value: '${order.item.weight} kg',
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryStart, AppColors.primaryEnd],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '+${order.trustPointsReward} TP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Section Card Widget
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Item Info Widget
class _ItemInfo extends StatelessWidget {
  final Order order;

  const _ItemInfo({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            order.item.categoryIcon,
            style: const TextStyle(fontSize: 32),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.item.categoryDisplayName,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (order.item.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  order.item.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (order.item.isFragile) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Fragile - Hati-hati!',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Location Info Widget
class _LocationInfo extends StatelessWidget {
  final Order order;

  const _LocationInfo({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LocationTile(
          icon: Icons.circle,
          iconColor: AppColors.primaryStart,
          label: 'Pickup',
          address: order.pickup.address,
          coordinates: order.pickupCoordinates,
        ),
        const Padding(padding: EdgeInsets.only(left: 10), child: _DottedLine()),
        _LocationTile(
          icon: Icons.location_on,
          iconColor: AppColors.error,
          label: 'Tujuan',
          address: order.destination.address,
          coordinates: order.destinationCoordinates,
        ),
      ],
    );
  }
}

/// Chat Section Widget - Quick access to chat
class _ChatSection extends StatelessWidget {
  final String orderId;
  final String orderDisplayId;

  const _ChatSection({required this.orderId, required this.orderDisplayId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryStart.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primaryStart,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat Pesanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Komunikasi dengan sender/hunter',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderChatScreen(
                      orderId: orderId,
                      orderDisplayId: orderDisplayId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.message),
              label: const Text('Buka Chat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tracking Map Widget - Shows delivery route on map
class _TrackingMap extends StatelessWidget {
  final Order order;

  const _TrackingMap({required this.order});

  @override
  Widget build(BuildContext context) {
    final pickupLatLng = LatLng(
      order.pickupCoordinates.latitude,
      order.pickupCoordinates.longitude,
    );
    final destinationLatLng = LatLng(
      order.destinationCoordinates.latitude,
      order.destinationCoordinates.longitude,
    );

    // Calculate center point between pickup and destination
    final centerLat = (pickupLatLng.latitude + destinationLatLng.latitude) / 2;
    final centerLng =
        (pickupLatLng.longitude + destinationLatLng.longitude) / 2;
    final centerLatLng = LatLng(centerLat, centerLng);

    // Calculate appropriate zoom level based on distance
    final distance = order.distanceKm;
    double zoom = 14.0;
    if (distance > 20) {
      zoom = 10.0;
    } else if (distance > 10) {
      zoom = 11.0;
    } else if (distance > 5) {
      zoom = 12.0;
    } else if (distance > 2) {
      zoom = 13.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: order.status == OrderStatus.inTransit
                ? AppColors.primaryStart.withOpacity(0.1)
                : AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                order.status == OrderStatus.inTransit
                    ? Icons.local_shipping
                    : Icons.person_pin_circle,
                color: order.status == OrderStatus.inTransit
                    ? AppColors.primaryStart
                    : AppColors.info,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                order.status == OrderStatus.inTransit
                    ? 'Hunter sedang dalam perjalanan'
                    : 'Hunter akan mengambil barang',
                style: TextStyle(
                  color: order.status == OrderStatus.inTransit
                      ? AppColors.primaryStart
                      : AppColors.info,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Map
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 250,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: centerLatLng,
                initialZoom: zoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                // OpenStreetMap tile layer
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.trustpoints.app',
                  maxZoom: 19,
                ),

                // Route line between pickup and destination
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [pickupLatLng, destinationLatLng],
                      color: AppColors.primaryStart,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),

                // Markers
                MarkerLayer(
                  markers: [
                    // Pickup marker
                    Marker(
                      point: pickupLatLng,
                      width: 40,
                      height: 40,
                      child: _MapMarker(
                        icon: Icons.circle,
                        color: AppColors.primaryStart,
                        label: 'A',
                      ),
                    ),
                    // Destination marker
                    Marker(
                      point: destinationLatLng,
                      width: 40,
                      height: 40,
                      child: _MapMarker(
                        icon: Icons.location_on,
                        color: AppColors.error,
                        label: 'B',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Legend
        Row(
          children: [
            _MapLegendItem(color: AppColors.primaryStart, label: 'Pickup'),
            const SizedBox(width: 16),
            _MapLegendItem(color: AppColors.error, label: 'Tujuan'),
            const Spacer(),
            Text(
              '${order.distanceKm.toStringAsFixed(1)} km',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Custom map marker widget
class _MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _MapMarker({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Map legend item
class _MapLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _MapLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _LocationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;
  final Coordinates coordinates;

  const _LocationTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
    required this.coordinates,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.directions, color: AppColors.primaryStart),
          onPressed: () {
            // TODO: Open in maps
          },
          tooltip: 'Buka di Maps',
        ),
      ],
    );
  }
}

class _DottedLine extends StatelessWidget {
  const _DottedLine();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          width: 2,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.textTertiary.withOpacity(0.4),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

/// Order Timeline Widget
class _OrderTimeline extends StatelessWidget {
  final Order order;

  const _OrderTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineItem(
          title: 'Pesanan Dibuat',
          time: order.createdAt,
          isCompleted: true,
          isFirst: true,
        ),
        _TimelineItem(
          title: 'Diambil Hunter',
          time: order.claimedAt,
          isCompleted: order.claimedAt != null,
        ),
        _TimelineItem(
          title: 'Dalam Perjalanan',
          time: order.pickedUpAt,
          isCompleted: order.pickedUpAt != null,
        ),
        _TimelineItem(
          title: 'Terkirim',
          time: order.deliveredAt,
          isCompleted: order.deliveredAt != null,
          isLast: true,
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final DateTime? time;
  final bool isCompleted;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    this.time,
    required this.isCompleted,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primaryStart
                    : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isCompleted
                    ? AppColors.primaryStart
                    : AppColors.surfaceVariant,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                    color: isCompleted
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
                if (time != null)
                  Text(
                    _formatDateTime(time!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

/// Action Buttons Widget
class _ActionButtons extends StatelessWidget {
  final Order order;
  final bool isHunterView;

  const _ActionButtons({required this.order, required this.isHunterView});

  @override
  Widget build(BuildContext context) {
    if (isHunterView) {
      return _HunterActions(order: order);
    } else {
      return _SenderActions(order: order);
    }
  }
}

/// Hunter Action Buttons
class _HunterActions extends StatelessWidget {
  final Order order;

  const _HunterActions({required this.order});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (order.isPending) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await orderProvider.claimOrder(
              token: authProvider.token!,
              orderId: order.orderId,
            );
            if (result.success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.message ?? 'Pesanan berhasil diambil!'),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.message ?? 'Gagal mengambil pesanan'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          icon: const Icon(Icons.check_circle),
          label: const Text('Ambil Pesanan Ini'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    }

    if (order.isClaimed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await orderProvider.pickupOrder(
              token: authProvider.token!,
              orderId: order.orderId,
            );
            if (result.success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.message ?? 'Pengiriman dimulai!'),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.message ?? 'Gagal memulai pengiriman'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          icon: const Icon(Icons.local_shipping),
          label: const Text('Sudah Pickup - Mulai Antar'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    }

    if (order.isInTransit) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await orderProvider.deliverOrder(
              token: authProvider.token!,
              orderId: order.orderId,
            );
            if (result.success && context.mounted) {
              _showDeliverySuccessDialog(context, result.trustPointsEarned);
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.message ?? 'Gagal menyelesaikan pengiriman',
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Selesaikan Pengiriman'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    }

    if (order.isDelivered) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            Text(
              'Pengiriman Selesai (+${order.trustPointsReward} TP)',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showDeliverySuccessDialog(BuildContext context, int trustPoints) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Pengiriman Selesai!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda mendapatkan',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '+$trustPoints Trust Points',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryStart,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Selesai'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sender Action Buttons
class _SenderActions extends StatelessWidget {
  final Order order;

  const _SenderActions({required this.order});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (order.isPending || order.isClaimed) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () =>
              _showCancelDialog(context, authProvider, orderProvider),
          icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
          label: const Text('Batalkan Pesanan'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    }

    if (order.isInTransit) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping, color: AppColors.info),
            SizedBox(width: 8),
            Text(
              'Pesanan sedang dalam perjalanan',
              style: TextStyle(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (order.isDelivered) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'Pesanan telah terkirim',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (order.isCancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'Pesanan telah dibatalkan',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showCancelDialog(
    BuildContext context,
    AuthProvider authProvider,
    OrderProvider orderProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan?'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await orderProvider.cancelOrder(
                token: authProvider.token!,
                orderId: order.orderId,
              );
              if (result.success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message ?? 'Pesanan dibatalkan'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}
