import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cart_item.dart';
import '../main.dart';
import 'package:hive_flutter/hive_flutter.dart';

class OrderConfirmationPage extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderConfirmationPage({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_clearCart); // safer than calling directly
  }

  Future<void> _clearCart() async {
    final cartBox = Hive.box<CartItem>('cart');
    if (cartBox.isNotEmpty) {
      await cartBox.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId;
    final orderData = widget.orderData;
    final items = orderData['items'] as List<CartItem>? ?? [];

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Order Confirmed ✅",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Order ID:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SelectableText(
                      orderId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: "Copy Order ID",
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
              const SizedBox(height: 20),
              Text("Name: ${orderData['name']}"),
              Text("Roll No: ${orderData['rollNo']}"),
              Text("Phone: ${orderData['phone']}"),
              Text("Pickup Point: ${orderData['pickupPoint']}"),
              const SizedBox(height: 16),
              const Text(
                "Items:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Text("No items found.")
              else
                ...items.map(
                  (item) => Text(
                    "• ${item.name} × ${item.quantity} — ₹${item.price}",
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                "Total: ₹${(orderData['total'] as double).toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
