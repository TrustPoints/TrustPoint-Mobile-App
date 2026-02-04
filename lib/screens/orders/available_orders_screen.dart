import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import 'widgets/order_widgets.dart';
import 'order_detail_screen.dart';

/// Available Orders Screen - For Hunters to browse and claim orders
class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (authProvider.token != null) {
      await orderProvider.loadAvailableOrders(
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
        title: const Text('Pesanan Tersedia'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading &&
              orderProvider.availableOrders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryStart),
              ),
            );
          }

          if (orderProvider.error != null &&
              orderProvider.availableOrders.isEmpty) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Terjadi Kesalahan',
              subtitle: orderProvider.error!,
              buttonText: 'Coba Lagi',
              onButtonPressed: _loadOrders,
            );
          }

          if (orderProvider.availableOrders.isEmpty) {
            return EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Belum Ada Pesanan',
              subtitle:
                  'Saat ini tidak ada pesanan yang tersedia di sekitar Anda.',
              buttonText: 'Refresh',
              onButtonPressed: _loadOrders,
            );
          }

          return RefreshIndicator(
            onRefresh: _loadOrders,
            color: AppColors.primaryStart,
            child: Column(
              children: [
                // Stats bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.primaryStart,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${orderProvider.totalAvailable} pesanan tersedia',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Orders list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orderProvider.availableOrders.length,
                    itemBuilder: (context, index) {
                      final order = orderProvider.availableOrders[index];
                      return OrderCard(
                        order: order,
                        isHunterView: true,
                        onTap: () => _navigateToDetail(order),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OrderDetailScreen(orderId: order.orderId, isHunterView: true),
      ),
    );
  }
}
