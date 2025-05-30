import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewAllOrdersPage extends StatelessWidget {
  const ViewAllOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Orders"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .orderBy('orderDate', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching orders"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text("No orders found."));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final orderData = orderDoc.data() as Map<String, dynamic>;
              final orderId = orderData['orderId'] ?? 'N/A';
              final status = orderData['status'] ?? 'Unknown';
              final pickupPoint = orderData['pickupPoint'] ?? 'Unknown';
              final totalPrice = orderData['totalPrice'] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text("Order #$orderId"),
                  subtitle: Text(
                    "Status: $status | Pickup: $pickupPoint\nTotal: ₹$totalPrice",
                  ),
                  children: [
                    FutureBuilder<QuerySnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('orders')
                              .doc(orderDoc.id)
                              .collection('orderItems')
                              .get(),
                      builder: (context, itemSnapshot) {
                        if (!itemSnapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          );
                        }

                        final items = itemSnapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final itemData =
                                items[i].data() as Map<String, dynamic>;
                            final itemName = itemData['itemId'];
                            final qty = itemData['quantity'];
                            final price = itemData['price'];

                            return ListTile(
                              title: Text(itemName),
                              subtitle: Text("Qty: $qty | ₹$price"),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
