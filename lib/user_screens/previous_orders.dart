import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/cart_item.dart';
import 'pick_up_point.dart';

class PreviousOrdersPage extends StatefulWidget {
  const PreviousOrdersPage({super.key});

  @override
  State<PreviousOrdersPage> createState() => _PreviousOrdersPageState();
}

class _PreviousOrdersPageState extends State<PreviousOrdersPage> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final cartBox = Hive.box<CartItem>('cart');
  final Map<String, bool> expanded = {};

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("KMIT  🍴  CANTEEN"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              // Toggle dark/light mode
              final current = Theme.of(context).brightness;
              final newMode =
                  current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
              (context.findAncestorStateOfType<State<MaterialApp>>() as dynamic)
                  ?.setState(() => ThemeMode.system == newMode);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('orders')
                  .where(
                    'rollNo',
                    isEqualTo: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId),
                  )
                  .orderBy('orderDate', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();

            final orders = snapshot.data!.docs;

            if (orders.isEmpty) {
              return const Center(child: Text("No previous orders found."));
            }

            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final orderDoc = orders[index];
                final orderId = orderDoc['orderId'];
                final orderDate = orderDoc['orderDate'].toDate();
                final orderRef = orderDoc.reference;
                final isExpanded = expanded[orderId] ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text("Order No: $orderId"),
                        subtitle: Text("Date: ${orderDate.toLocal()}"),
                        trailing: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                        ),
                        onTap: () {
                          setState(() {
                            expanded[orderId] = !isExpanded;
                          });
                        },
                      ),
                      if (isExpanded)
                        StreamBuilder<QuerySnapshot>(
                          stream: orderRef.collection('orderItems').snapshots(),
                          builder: (context, itemSnap) {
                            if (!itemSnap.hasData) return const SizedBox();

                            final orderItems = itemSnap.data!.docs;

                            return Column(
                              children: [
                                ...orderItems.map((doc) {
                                  final itemRef =
                                      doc['itemId'] as DocumentReference;
                                  final quantity = doc['quantity'];
                                  final price = doc['price'];

                                  return FutureBuilder<DocumentSnapshot>(
                                    future: itemRef.get(),
                                    builder: (context, menuItemSnap) {
                                      if (!menuItemSnap.hasData ||
                                          !menuItemSnap.data!.exists) {
                                        return const ListTile(
                                          title: Text("Item not found"),
                                        );
                                      }

                                      final item = menuItemSnap.data!;
                                      final data =
                                          item.data() as Map<String, dynamic>;

                                      final itemId = item.id;
                                      final itemName = data['name'];
                                      final description = data['description'];
                                      final imageUrl = data['imageUrl'] ?? '';

                                      return ListTile(
                                        leading:
                                            imageUrl.isNotEmpty
                                                ? Image.network(
                                                  imageUrl,
                                                  width: 50,
                                                  height: 50,
                                                )
                                                : const Icon(
                                                  Icons.image,
                                                  size: 50,
                                                ),
                                        title: Text(itemName ?? ''),
                                        subtitle: Text(description ?? ''),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () {
                                                setState(() {
                                                  final cartItem = cartBox.get(
                                                    itemId,
                                                  );
                                                  if (cartItem != null &&
                                                      cartItem.quantity > 1) {
                                                    cartItem.quantity -= 1;
                                                    cartBox.put(
                                                      itemId,
                                                      cartItem,
                                                    );
                                                  } else {
                                                    cartBox.delete(itemId);
                                                  }
                                                });
                                              },
                                            ),
                                            Text(
                                              '${cartBox.get(itemId)?.quantity ?? quantity}',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () {
                                                setState(() {
                                                  final existing = cartBox.get(
                                                    itemId,
                                                  );
                                                  final updated = CartItem(
                                                    itemId: itemId,
                                                    name: itemName,
                                                    price:
                                                        (price as num)
                                                            .toDouble(),
                                                    quantity:
                                                        (existing?.quantity ??
                                                            0) +
                                                        1,
                                                    imageUrl: imageUrl,
                                                    description: description,
                                                    category:
                                                        data['category'] ?? '',
                                                  );
                                                  cartBox.put(itemId, updated);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => const PickupPointPage(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 30,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text("Re-Order"),
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}
