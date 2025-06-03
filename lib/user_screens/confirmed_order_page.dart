import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class OrderConfirmationPage extends StatelessWidget {
  final String orderId;

  const OrderConfirmationPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("🎉 Order Confirmed!")));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("KMIT 🍴 CANTEEN"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: "Go Home",
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              themeNotifier.value =
                  themeNotifier.value == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .doc(orderId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text("Order not found."));
          }

          final status = data['status'] ?? 'Pending';
          final pickup = data['pickupPoint'] ?? 'Unknown';
          final total = data['totalPrice'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "✅ Order Confirmed",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Column(
                    children: [
                      const Text("Order ID:", style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      SelectableText(
                        orderId,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: orderId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Order ID copied!")),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  "Pickup Point: $pickup",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Text(
                      "Current Status: ",
                      style: TextStyle(fontSize: 16),
                    ),
                    Chip(
                      label: Text(status),
                      backgroundColor: Colors.deepPurple,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Text(
                  "Items Ordered:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('orders')
                            .doc(orderId)
                            .collection('orderItems')
                            .snapshots(),
                    builder: (context, itemSnap) {
                      if (!itemSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final items = itemSnap.data!.docs;
                      if (items.isEmpty) {
                        return const Text("No items found.");
                      }

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item =
                              items[index].data() as Map<String, dynamic>;
                          final qty = item['quantity'];
                          final price = item['price'];
                          final itemRef = item['itemId'] as DocumentReference;

                          return FutureBuilder<DocumentSnapshot>(
                            future: itemRef.get(),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return const ListTile(
                                  title: Text("Loading..."),
                                );
                              }

                              final itemData =
                                  snap.data!.data() as Map<String, dynamic>?;
                              if (itemData == null) {
                                return const ListTile(
                                  title: Text("Item not found"),
                                );
                              }

                              final name = itemData['name'] ?? 'Unnamed';
                              return ListTile(
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text("Qty: $qty"),
                                trailing: Text(
                                  "₹${(price * qty).toStringAsFixed(2)}",
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      "Total: ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "₹${total.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
