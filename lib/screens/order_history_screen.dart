import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/food_ordering_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String? highlightOrderId;

  const OrderHistoryScreen({super.key, this.highlightOrderId});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final foodProvider = Provider.of<FoodOrderingProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await foodProvider.loadUserOrders(authProvider.currentUser!.id);
    }
  }

  String _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'orange';
      case OrderStatus.confirmed:
        return 'blue';
      case OrderStatus.preparing:
        return 'purple';
      case OrderStatus.ready:
        return 'teal';
      case OrderStatus.delivered:
        return 'green';
      case OrderStatus.cancelled:
        return 'red';
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.done;
      case OrderStatus.delivered:
        return Icons.local_shipping;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<FoodOrderingProvider, AuthProvider>(
        builder: (context, foodProvider, authProvider, child) {
          if (authProvider.currentUser == null) {
            return const Center(
              child: Text('Please login to view orders'),
            );
          }

          if (foodProvider.isLoadingOrders) {
            return const Center(child: CircularProgressIndicator());
          }

          if (foodProvider.userOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start ordering delicious food!',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadOrders,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: foodProvider.userOrders.length,
              itemBuilder: (context, index) {
                final order = foodProvider.userOrders[index];
                final isHighlighted = widget.highlightOrderId == order.orderId;
                final statusColor = _getStatusColor(order.orderStatus);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isHighlighted ? 6 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isHighlighted
                        ? BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          )
                        : BorderSide.none,
                  ),
                  child: ExpansionTile(
                    leading: Icon(
                      _getStatusIcon(order.orderStatus),
                      color: _getColorFromString(statusColor),
                    ),
                    title: Text(
                      'Order #${order.orderId.substring(order.orderId.length - 6)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (order.netPointsEarned != 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            order.netPointsEarned > 0
                                ? '+${order.netPointsEarned} eco-points 🌱'
                                : '${order.netPointsEarned} eco-points',
                            style: TextStyle(
                              fontSize: 12,
                              color: order.netPointsEarned > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${order.totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(
                            order.orderStatus.toString().split('.').last.toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: _getColorFromString(statusColor).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _getColorFromString(statusColor),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Items
                            const Text(
                              'Items:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...order.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    if (item.foodImageUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          item.foodImageUrl,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(Icons.fastfood, size: 20),
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.foodName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Qty: ${item.quantity} × ₹${item.unitPrice.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${item.totalPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const Divider(height: 24),

                            // Delivery Address
                            const Text(
                              'Delivery Address:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(order.deliveryAddress.fullAddress),

                            const Divider(height: 24),

                            // Points Breakdown
                            if (order.ecoPointsEarned > 0 || order.ecoPointsLost > 0) ...[
                              const Text(
                                'Eco-Points Breakdown:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (order.ecoPointsEarned > 0)
                                Row(
                                  children: [
                                    const Icon(Icons.add_circle, color: Colors.green, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Earned: +${order.ecoPointsEarned}',
                                      style: const TextStyle(color: Colors.green),
                                    ),
                                  ],
                                ),
                              if (order.ecoPointsLost > 0)
                                Row(
                                  children: [
                                    const Icon(Icons.remove_circle, color: Colors.red, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Lost: -${order.ecoPointsLost}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              const Divider(height: 24),
                            ],

                            // Summary
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:'),
                                Text('₹${order.subtotal.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Delivery Fee:'),
                                Text('₹${order.deliveryFee.toStringAsFixed(2)}'),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '₹${order.totalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

