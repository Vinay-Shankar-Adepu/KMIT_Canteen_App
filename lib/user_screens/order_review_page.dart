import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item.dart';
import 'confirmed_order_page.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderReviewPage extends StatefulWidget {
  final String selectedPickupPoint;

  const OrderReviewPage({super.key, required this.selectedPickupPoint});

  @override
  State<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends State<OrderReviewPage> {
  late Box<CartItem> cartBox;
  late List<CartItem> cartItems;
  late double totalPrice;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    cartBox = Hive.box<CartItem>('cart');
    cartItems = cartBox.values.toList();
    totalPrice = cartItems.fold(
      0,
      (total, item) => total + (item.price * item.quantity),
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);
    print("🔁 Starting anonymous order placement...");

    try {
      final now = Timestamp.now();
      final metaRef = FirebaseFirestore.instance
          .collection('metadata')
          .doc('orders');

      final metaSnap = await metaRef.get();
      int current = metaSnap.exists ? (metaSnap['count'] ?? 1000) : 1000;
      final newOrderId = 'O${current + 1}';
      print("🆕 New Order ID: $newOrderId");

      final orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(newOrderId);

      await metaRef.set({'count': current + 1});
      print("📈 Metadata updated");

      await orderRef.set({
        'orderId': newOrderId,
        'pickupPoint': widget.selectedPickupPoint,
        'orderDate': now,
        'status': 'Pending',
        'totalPrice': totalPrice,
        'userId': "anonymous",
      });
      print("✅ Order document created");

      for (final item in cartItems) {
        final itemRef = FirebaseFirestore.instance
            .collection('menuItems')
            .doc(item.itemId);
        await orderRef.collection('orderItems').add({
          'itemId': itemRef,
          'price': item.price,
          'quantity': item.quantity,
        });

        await FirebaseFirestore.instance.runTransaction((tx) async {
          final snap = await tx.get(itemRef);
          final existing = snap.exists ? (snap['orderCount'] ?? 0) : 0;
          tx.update(itemRef, {'orderCount': existing + item.quantity});
        });
      }
      print("📦 Items added to subcollection");

      await cartBox.clear();
      print("🧹 Cart cleared");

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmationPage(orderId: newOrderId),
        ),
      );
      print("🚀 Redirected to confirmation page");
    } catch (e) {
      print("❌ Order creation error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to place order. Please try again."),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              themeNotifier.value =
                  themeNotifier.value == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
            },
          ),
        ],
      ),
      body:
          cartItems.isEmpty
              ? const Center(child: Text("Your cart is empty."))
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Order Review",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Card(
                            child: ListTile(
                              leading: Image.network(
                                item.imageUrl ?? '',
                                width: 50,
                                height: 50,
                                errorBuilder:
                                    (_, __, ___) => const Icon(Icons.image),
                              ),
                              title: Text(item.name),
                              trailing: Text("x${item.quantity}"),
                            ),
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
                          "₹${totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isPlacingOrder ? null : _placeOrder,
                        child:
                            _isPlacingOrder
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  "Confirm Order",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
