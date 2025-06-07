import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewAllOrdersPage extends StatelessWidget {
  const ViewAllOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

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
                color: cardColor,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    collapsedTextColor: textColor,
                    textColor: textColor,
                    iconColor: textColor,
                    title: Text(
                      "Order #$orderId",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      "Status: $status | Pickup: $pickupPoint\nTotal: ₹$totalPrice",
                      style: TextStyle(color: textColor.withOpacity(0.8)),
                    ),
                    children: [
                      FutureBuilder<QuerySnapshot>(
                        future:
                            orderDoc.reference.collection('orderItems').get(),
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
                              final itemRef = itemData['itemId'];
                              final qty = itemData['quantity'];
                              final price = itemData['price'];

                              if (itemRef is! DocumentReference) {
                                return ListTile(
                                  title: Text(
                                    "Invalid item",
                                    style: TextStyle(color: textColor),
                                  ),
                                  subtitle: Text(
                                    "Qty: $qty | ₹$price",
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.8),
                                    ),
                                  ),
                                );
                              }

                              return FutureBuilder<DocumentSnapshot>(
                                future: itemRef.get(),
                                builder: (context, itemSnap) {
                                  if (!itemSnap.hasData ||
                                      !itemSnap.data!.exists) {
                                    return const ListTile(
                                      title: Text("Item not found"),
                                    );
                                  }

                                  final itemDetails =
                                      itemSnap.data!.data()
                                          as Map<String, dynamic>;
                                  final itemName =
                                      itemDetails['name'] ?? 'Unnamed';

                                  return ListTile(
                                    title: Text(
                                      itemName,
                                      style: TextStyle(color: textColor),
                                    ),
                                    subtitle: Text(
                                      "Qty: $qty | ₹$price",
                                      style: TextStyle(
                                        color: textColor.withOpacity(0.8),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
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
