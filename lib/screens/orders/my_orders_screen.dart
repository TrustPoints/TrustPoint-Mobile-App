import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import 'widgets/order_widgets.dart';
import 'order_detail_screen.dart';

/// My Orders Screen - For Senders to view their orders
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (authProvider.token != null) {
      await orderProvider.loadMyOrders(
        token: authProvider.token!,
        refresh: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryStart,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryStart,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Selesai'),
            Tab(text: 'Dibatalkan'),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading && orderProvider.myOrders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryStart),
              ),
            );
          }

          final activeOrders = orderProvider.myOrders
              .where((o) => o.isPending || o.isClaimed || o.isInTransit)
              .toList();
          final completedOrders = orderProvider.myOrders
              .where((o) => o.isDelivered)
              .toList();
          final cancelledOrders = orderProvider.myOrders
              .where((o) => o.isCancelled)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _OrderList(
                orders: activeOrders,
                emptyIcon: Icons.local_shipping_outlined,
                emptyTitle: 'Tidak Ada Pesanan Aktif',
                emptySubtitle: 'Pesanan aktif Anda akan muncul di sini.',
                onRefresh: _loadOrders,
              ),
              _OrderList(
                orders: completedOrders,
                emptyIcon: Icons.check_circle_outline,
                emptyTitle: 'Belum Ada Pesanan Selesai',
                emptySubtitle:
                    'Pesanan yang sudah terkirim akan muncul di sini.',
                onRefresh: _loadOrders,
              ),
              _OrderList(
                orders: cancelledOrders,
                emptyIcon: Icons.cancel_outlined,
                emptyTitle: 'Tidak Ada Pesanan Dibatalkan',
                emptySubtitle: 'Pesanan yang dibatalkan akan muncul di sini.',
                onRefresh: _loadOrders,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// My Deliveries Screen - For Hunters to view their deliveries
class MyDeliveriesScreen extends StatefulWidget {
  const MyDeliveriesScreen({super.key});

  @override
  State<MyDeliveriesScreen> createState() => _MyDeliveriesScreenState();
}

class _MyDeliveriesScreenState extends State<MyDeliveriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeliveries();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveries() async {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (authProvider.token != null) {
      await orderProvider.loadMyDeliveries(
        token: authProvider.token!,
        refresh: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengiriman Saya'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryStart,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryStart,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading && orderProvider.myDeliveries.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryStart),
              ),
            );
          }

          final activeDeliveries = orderProvider.myDeliveries
              .where((o) => o.isClaimed || o.isInTransit)
              .toList();
          final completedDeliveries = orderProvider.myDeliveries
              .where((o) => o.isDelivered)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _OrderList(
                orders: activeDeliveries,
                emptyIcon: Icons.delivery_dining,
                emptyTitle: 'Tidak Ada Pengiriman Aktif',
                emptySubtitle: 'Ambil pesanan untuk mulai mengantarkan.',
                onRefresh: _loadDeliveries,
                isHunterView: true,
              ),
              _OrderList(
                orders: completedDeliveries,
                emptyIcon: Icons.emoji_events_outlined,
                emptyTitle: 'Belum Ada Pengiriman Selesai',
                emptySubtitle: 'Pengiriman yang selesai akan muncul di sini.',
                onRefresh: _loadDeliveries,
                isHunterView: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Order List Widget
class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final Future<void> Function() onRefresh;
  final bool isHunterView;

  const _OrderList({
    required this.orders,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRefresh,
    this.isHunterView = false,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryStart,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            order: order,
            isHunterView: isHunterView,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(
                    orderId: order.orderId,
                    isHunterView: isHunterView,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
