import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/admin_sidebar.dart';
import '../main.dart';

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
  Set<String> selectedOrderIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ASidebar(),
      appBar: AppBar(title: const Text('KMIT CANTEEN'), centerTitle: true),
      floatingActionButton:
          selectedOrderIds.isNotEmpty
              ? FloatingActionButton.extended(
                icon: const Icon(Icons.batch_prediction),
                label: const Text("Bulk Update"),
                onPressed: () => _showBulkStatusDialog(context),
              )
              : FloatingActionButton(
                onPressed: () => Navigator.pushNamed(context, '/scanner'),
                child: const Icon(Icons.qr_code_scanner),
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(height: 60),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('canteenStatus')
                .doc('status')
                .snapshots(),
        builder: (context, statusSnapshot) {
          bool isOnline = true;
          if (statusSnapshot.hasData) {
            isOnline = statusSnapshot.data?.get('isOnline') ?? true;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (!isOnline)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.red.shade700,
                    child: const Text(
                      "⚠️ The Canteen is currently OFFLINE",
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
          );
        },
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
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

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

        if (filteredOrders.isEmpty)
          return const Center(child: Text("No active orders."));

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
                  orderNo: doc['orderId'],
                  location: doc['pickupPoint'],
                  status: doc['status'],
                  itemCount: itemCount,
                  description: 'Price: ₹${doc['totalPrice']}',
                  isSelected: selectedOrderIds.contains(doc.id),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedOrderIds.add(doc.id);
                      } else {
                        selectedOrderIds.remove(doc.id);
                      }
                    });
                  },
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

  void _showBulkStatusDialog(BuildContext context) {
    String selected = 'Preparing';
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Bulk Status Update'),
            content: DropdownButton<String>(
              value: selected,
              items:
                  ['Pending', 'Preparing', 'Ready', 'Delivered']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(() => selected = val ?? selected),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  for (var orderId in selectedOrderIds) {
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(orderId)
                        .update({'status': selected});
                  }
                  setState(() => selectedOrderIds.clear());
                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          ),
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
  final bool isSelected;
  final Function(bool) onSelected;

  const OrderCard({
    super.key,
    required this.orderNo,
    required this.location,
    required this.status,
    required this.itemCount,
    required this.description,
    required this.onStatusChange,
    required this.isSelected,
    required this.onSelected,
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (val) => onSelected(val ?? false),
                ),
                Expanded(
                  child: ListTile(
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
                              child: Text(buttonLabel),
                            )
                            : null,
                  ),
                ),
              ],
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
