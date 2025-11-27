import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/food_ordering_provider.dart';
import '../../providers/auth_provider.dart';
import 'add_address_screen.dart';

class AddressManagementScreen extends StatelessWidget {
  const AddressManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddAddressScreen(),
            ),
          );
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final foodProvider = Provider.of<FoodOrderingProvider>(context, listen: false);
          if (authProvider.currentUser != null) {
            await foodProvider.loadUserAddresses(authProvider.currentUser!.id);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
      body: Consumer2<FoodOrderingProvider, AuthProvider>(
        builder: (context, foodProvider, authProvider, child) {
          if (authProvider.currentUser == null) {
            return const Center(
              child: Text('Please login to manage addresses'),
            );
          }

          if (foodProvider.isLoadingAddresses) {
            return const Center(child: CircularProgressIndicator());
          }

          if (foodProvider.userAddresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No addresses saved',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first delivery address',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => foodProvider.loadUserAddresses(authProvider.currentUser!.id),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: foodProvider.userAddresses.length,
              itemBuilder: (context, index) {
                final address = foodProvider.userAddresses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: address.isDefault ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: address.isDefault
                        ? BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          )
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          address.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: const Text(
                              'Default',
                              style: TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Theme.of(context).primaryColor,
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(address.fullAddress),
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${address.latitude.toStringAsFixed(4)}, '
                          'Lng: ${address.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddAddressScreen(address: address),
                              ),
                            );
                            if (authProvider.currentUser != null) {
                              await foodProvider.loadUserAddresses(
                                authProvider.currentUser!.id,
                              );
                            }
                          },
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.star, size: 20),
                              SizedBox(width: 8),
                              Text('Set as Default'),
                            ],
                          ),
                          onTap: () async {
                            await foodProvider.updateAddress(
                              authProvider.currentUser!.id,
                              address.copyWith(isDefault: true),
                            );
                          },
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Address'),
                                content: Text(
                                  'Are you sure you want to delete "${address.label}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true && authProvider.currentUser != null) {
                              await foodProvider.deleteAddress(
                                authProvider.currentUser!.id,
                                address.addressId,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

