import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/food_ordering_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/points_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/order_model.dart';
import 'address_management_screen.dart';
import '../order_history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryAddress? _selectedAddress;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final foodProvider = Provider.of<FoodOrderingProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await foodProvider.loadUserAddresses(authProvider.currentUser!.id);
      setState(() {
        _selectedAddress = foodProvider.defaultAddress;
      });
    }
  }

  void _showHarmfulOptionNotification(String optionName, int pointsLost) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '⚠️ Not Eco-Friendly!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'You selected "$optionName". You will lose $pointsLost eco-points!',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEcoFriendlyNotification(String optionName, int pointsEarned, {bool isSelected = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.eco, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🌱 Eco-Friendly Choice!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    isSelected
                        ? 'You selected "$optionName". You will earn $pointsEarned eco-points!'
                        : 'You declined "$optionName". You will earn $pointsEarned eco-points!',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final foodProvider = Provider.of<FoodOrderingProvider>(context, listen: false);
      final pointsProvider = Provider.of<PointsProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Place order
      final order = await foodProvider.placeOrder(
        userId: authProvider.currentUser!.id,
        deliveryAddress: _selectedAddress!,
      );

      // Add points to user
      if (order.netPointsEarned != 0) {
        await pointsProvider.addPoints(
          order.netPointsEarned,
          category: 'food_ordering',
        );
      }

      // Send notification
      if (order.netPointsEarned > 0) {
        await notificationProvider.sendAchievementNotification(
          'Order Placed! 🌱',
          'You earned ${order.netPointsEarned} eco-points for your eco-friendly choices!',
        );
      } else if (order.netPointsEarned < 0) {
        await notificationProvider.sendAchievementNotification(
          'Order Placed',
          'You lost ${order.netPointsEarned.abs()} eco-points due to non-eco-friendly choices.',
        );
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderHistoryScreen(highlightOrderId: order.orderId),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order placed successfully! ${order.netPointsEarned > 0 ? "+${order.netPointsEarned} points" : ""}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<FoodOrderingProvider>(
        builder: (context, provider, child) {
          final pointsPreview = provider.getCartPointsPreview();
          final netPoints = pointsPreview['netPoints'] as int;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Points Summary Card
                Card(
                  elevation: 2,
                  color: netPoints > 0
                      ? Colors.green.withOpacity(0.1)
                      : netPoints < 0
                          ? Colors.red.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              netPoints > 0
                                  ? Icons.eco
                                  : netPoints < 0
                                      ? Icons.warning
                                      : Icons.info,
                              color: netPoints > 0
                                  ? Colors.green
                                  : netPoints < 0
                                      ? Colors.red
                                      : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Eco-Points Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: netPoints > 0
                                    ? Colors.green[700]
                                    : netPoints < 0
                                        ? Colors.red[700]
                                        : Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Detailed Points Breakdown
                        if (pointsPreview['ecoFriendlyChoices'] != null && 
                            (pointsPreview['ecoFriendlyChoices'] as List).isNotEmpty) ...[
                          const Text(
                            'Points Earned:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...(pointsPreview['ecoFriendlyChoices'] as List<String>).map((choice) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      choice,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                        if (pointsPreview['plasticChoices'] != null && 
                            (pointsPreview['plasticChoices'] as List).isNotEmpty) ...[
                          const Text(
                            'Points Lost:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...(pointsPreview['plasticChoices'] as List<String>).map((choice) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      choice,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                        const Divider(height: 24),
                        // Summary Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Net Points:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              netPoints > 0
                                  ? '+$netPoints'
                                  : netPoints < 0
                                      ? '$netPoints'
                                      : '0',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: netPoints > 0
                                    ? Colors.green
                                    : netPoints < 0
                                        ? Colors.red
                                        : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        // Helper text
                        if (netPoints != 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            netPoints > 0
                                ? '🌱 Great! You\'re making eco-friendly choices!'
                                : '⚠️ Consider declining plastic items to earn points',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: netPoints > 0
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Checkout Options for each item
                const Text(
                  'Checkout Options',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                ...provider.cartItems.map((cartItem) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cartItem.foodItem.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (cartItem.foodItem.checkoutOptions.isEmpty)
                            const Text(
                              'No checkout options available',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ...cartItem.foodItem.checkoutOptions.map((option) {
                              final selectedOption = cartItem.selectedOptions
                                  .firstWhere(
                                    (opt) => opt.optionId == option.id,
                                    orElse: () => SelectedCheckoutOption(
                                      optionId: option.id,
                                      optionName: option.name,
                                      optionType: option.type,
                                      environmentalImpact: option.environmentalImpact,
                                      isSelected: option.isDefault,
                                    ),
                                  );

                              final isSelected = selectedOption.isSelected;
                              final isHarmful = option.isHarmful;

                              // Determine points message based on option type
                              String pointsMessage;
                              Color messageColor;
                              
                              if (isHarmful) {
                                // PLASTIC OPTIONS
                                if (isSelected) {
                                  // Selected plastic → LOSE points
                                  pointsMessage = 'You will lose ${option.pointsPenalty ?? 0} points';
                                  messageColor = Colors.red;
                                } else {
                                  // Declined plastic → EARN points
                                  pointsMessage = 'You will earn ${option.pointsReward} points';
                                  messageColor = Colors.green;
                                }
                              } else {
                                // PAPER/ECO-FRIENDLY OPTIONS
                                if (isSelected) {
                                  // Selected eco-friendly → EARN points
                                  pointsMessage = 'You will earn ${option.pointsReward} points';
                                  messageColor = Colors.green;
                                } else {
                                  // Declined eco-friendly → No change
                                  pointsMessage = 'No points change';
                                  messageColor = Colors.grey;
                                }
                              }

                              return CheckboxListTile(
                                title: Text(option.name),
                                subtitle: Text(
                                  pointsMessage,
                                  style: TextStyle(
                                    color: messageColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                value: isSelected,
                                onChanged: (value) {
                                  final newValue = value ?? false;
                                  provider.updateCheckoutOption(
                                    cartItem.foodItem.id,
                                    option.id,
                                    newValue,
                                  );

                                  // Show notification based on option type
                                  if (isHarmful) {
                                    // PLASTIC OPTIONS
                                    if (newValue) {
                                      // Selected plastic → Show warning
                                      _showHarmfulOptionNotification(
                                        option.name,
                                        option.pointsPenalty ?? 0,
                                      );
                                    } else {
                                      // Declined plastic → Show reward
                                      _showEcoFriendlyNotification(
                                        option.name,
                                        option.pointsReward,
                                      );
                                    }
                                  } else {
                                    // PAPER/ECO-FRIENDLY OPTIONS
                                    if (newValue) {
                                      // Selected eco-friendly → Show reward with "selected" message
                                      _showEcoFriendlyNotification(
                                        option.name,
                                        option.pointsReward,
                                        isSelected: true,
                                      );
                                    }
                                    // If deselected eco-friendly, no notification needed
                                  }
                                },
                                secondary: Icon(
                                  isHarmful
                                      ? Icons.warning
                                      : Icons.check_circle,
                                  color: isHarmful
                                      ? Colors.red
                                      : Colors.green,
                                ),
                                activeColor: isHarmful ? Colors.red : Colors.green,
                              );
                            }),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Delivery Address
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddressManagementScreen(),
                          ),
                        );
                        _loadAddresses();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add/Manage'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Consumer<FoodOrderingProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingAddresses) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.userAddresses.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.location_off, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text('No addresses saved'),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AddressManagementScreen(),
                                    ),
                                  );
                                  _loadAddresses();
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Address'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: provider.userAddresses.map((address) {
                        final isSelected = _selectedAddress?.addressId == address.addressId;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: isSelected ? 4 : 1,
                          color: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : null,
                          child: RadioListTile<DeliveryAddress>(
                            title: Text(
                              address.label,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(address.fullAddress),
                            value: address,
                            groupValue: _selectedAddress,
                            onChanged: (value) {
                              setState(() {
                                _selectedAddress = value;
                              });
                            },
                            secondary: address.isDefault
                                ? const Chip(
                                    label: Text('Default'),
                                    labelStyle: TextStyle(fontSize: 10),
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Order Summary
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text('₹${provider.cartSubtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Fee'),
                            const Text('₹0.00'),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${provider.cartSubtotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Place Order Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isPlacingOrder ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isPlacingOrder
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Place Order',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

