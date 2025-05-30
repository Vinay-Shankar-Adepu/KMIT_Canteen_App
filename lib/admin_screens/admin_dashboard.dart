import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/admin_sidebar.dart';
import '../main.dart'; // to access themeNotifier

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String selectedStatus = 'All';
  String searchQuery = '';

  final List<String> statusFilters = [
    'All',
    'Pending',
    'Preparing',
    'Ready',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ASidebar(),
      appBar: AppBar(
        title: const Text('KMIT CANTEEN'),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, mode, _) {
              return IconButton(
                icon: Icon(
                  mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                ),
                onPressed: () {
                  themeNotifier.value =
                      mode == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light;
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Admin Dashboard",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by Order ID',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged:
                        (val) => setState(() => searchQuery = val.trim()),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedStatus,
                  items:
                      statusFilters
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => selectedStatus = val!),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildOrderList()),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('orders')
              .orderBy('orderDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading orders"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rawOrders = snapshot.data!.docs;

        final filteredOrders =
            rawOrders.where((doc) {
              final status = doc['status'] ?? '';
              final orderId = doc['orderId']?.toString().toLowerCase() ?? '';
              final matchesStatus =
                  selectedStatus == 'All' || status == selectedStatus;
              final matchesSearch = orderId.contains(searchQuery.toLowerCase());
              return status != 'Delivered' && matchesStatus && matchesSearch;
            }).toList();

        final statusPriority = {'Pending': 0, 'Preparing': 1, 'Ready': 2};
        filteredOrders.sort((a, b) {
          final sa = a['status'] ?? '';
          final sb = b['status'] ?? '';
          return (statusPriority[sa] ?? 99).compareTo(statusPriority[sb] ?? 99);
        });

        if (filteredOrders.isEmpty) {
          return const Center(child: Text("No active orders."));
        }

        return ListView.builder(
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final doc = filteredOrders[index];

            return FutureBuilder<QuerySnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('orders')
                      .doc(doc.id)
                      .collection('orderItems')
                      .get(),
              builder: (context, itemSnapshot) {
                int itemCount = 0;
                if (itemSnapshot.hasData) {
                  itemCount = itemSnapshot.data!.docs.length;
                }

                return OrderCard(
                  orderNo: doc['orderId'] ?? 'N/A',
                  location: doc['pickupPoint'] ?? 'Unknown',
                  status: doc['status'] ?? 'Pending',
                  itemCount: itemCount,
                  description: 'Price: ₹${doc['totalPrice'] ?? 0}',
                  onStatusChange: (newStatus) {
                    FirebaseFirestore.instance
                        .collection('orders')
                        .doc(doc.id)
                        .update({'status': newStatus});
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class OrderCard extends StatelessWidget {
  final String orderNo;
  final String location;
  final String status;
  final int itemCount;
  final String description;
  final Function(String) onStatusChange;

  const OrderCard({
    super.key,
    required this.orderNo,
    required this.location,
    required this.status,
    required this.itemCount,
    required this.description,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    String? nextStatus;
    String buttonLabel = '';

    if (status == 'Pending') {
      nextStatus = 'Preparing';
      buttonLabel = 'Mark Preparing';
    } else if (status == 'Preparing') {
      nextStatus = 'Ready';
      buttonLabel = 'Mark Ready';
    } else if (status == 'Ready') {
      nextStatus = 'Delivered';
      buttonLabel = 'Mark Delivered';
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.fastfood),
              title: Text('Order #$orderNo - $location'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items: $itemCount'),
                  Text(description),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(status),
                    backgroundColor: _getStatusColor(status),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              trailing:
                  nextStatus != null
                      ? ElevatedButton(
                        onPressed: () => onStatusChange(nextStatus!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: Text(buttonLabel),
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Preparing':
        return Colors.deepPurple;
      case 'Ready':
        return Colors.green;
      case 'Delivered':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
