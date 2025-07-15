// ignore_for_file: use_build_context_synchronously
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/admin_sidebar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final player = AudioPlayer();
  String selectedStatus = 'All';
  String searchQuery = '';
  int lastOrderCount = 0;

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> playNewOrderSound() async {
    await player.play(AssetSource('audio/confirmation.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ASidebar(),
      appBar: AppBar(title: const Text('KMIT CANTEEN'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
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
                          ['All', 'Pending', 'Preparing', 'Ready', 'Delivered']
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.length > lastOrderCount) {
          playNewOrderSound();
        }
        lastOrderCount = docs.length;

        final filtered =
            docs.where((doc) {
              final status = doc['status'] ?? '';
              final orderId = doc['orderId']?.toString().toLowerCase() ?? '';
              final matchesStatus =
                  selectedStatus == 'All' || status == selectedStatus;
              final matchesSearch = orderId.contains(searchQuery.toLowerCase());
              return status != 'Delivered' && matchesStatus && matchesSearch;
            }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text("No active orders."));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final doc = filtered[index];

            return FutureBuilder<QuerySnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('orders')
                      .doc(doc.id)
                      .collection('orderItems')
                      .get(),
              builder: (context, itemSnapshot) {
                if (!itemSnapshot.hasData) return const SizedBox();

                final itemDocs = itemSnapshot.data!.docs;

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: Future.wait(
                    itemDocs.map((itemDoc) async {
                      final data = itemDoc.data() as Map<String, dynamic>;
                      final ref = data['itemId'] as DocumentReference;
                      final itemSnap = await ref.get();
                      final name =
                          itemSnap.exists ? itemSnap['name'] : 'Unnamed';
                      return {'name': name, 'quantity': data['quantity']};
                    }),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final itemsList = snapshot.data!;
                    return OrderCard(
                      orderNo: doc['orderId'],
                      location: doc['pickupPoint'],
                      status: doc['status'],
                      itemCount: itemsList.length,
                      totalPrice: (doc['totalPrice'] ?? 0).toDouble(),
                      itemsList: itemsList,
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
      },
    );
  }
}

class OrderCard extends StatefulWidget {
  final String orderNo;
  final String location;
  final String status;
  final int itemCount;
  final double totalPrice;
  final List<Map<String, dynamic>> itemsList;
  final Function(String) onStatusChange;

  const OrderCard({
    super.key,
    required this.orderNo,
    required this.location,
    required this.status,
    required this.itemCount,
    required this.totalPrice,
    required this.itemsList,
    required this.onStatusChange,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final nextStatus = _getNextStatus(widget.status);

    return GestureDetector(
      onTap: () => setState(() => isExpanded = !isExpanded),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${widget.orderNo}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(widget.status),
                    backgroundColor: _getStatusColor(widget.status),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  if (isExpanded && nextStatus != null)
                    ElevatedButton(
                      onPressed: () => widget.onStatusChange(nextStatus),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getStatusColor(nextStatus),
                      ),
                      child: Text('Mark $nextStatus'),
                    ),
                ],
              ),
              if (isExpanded) ...[
                const Divider(),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ...widget.itemsList.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '- ${item['name']} x${item['quantity']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total: ₹${widget.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _getNextStatus(String current) {
    switch (current) {
      case 'Pending':
        return 'Preparing';
      case 'Preparing':
        return 'Ready';
      case 'Ready':
        return 'Delivered';
      default:
        return null;
    }
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
