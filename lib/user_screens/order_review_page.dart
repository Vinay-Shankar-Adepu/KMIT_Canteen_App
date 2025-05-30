import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item.dart';
import 'confirmed_order_page.dart';
import '../main.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  late Razorpay _razorpay;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    cartBox = Hive.box<CartItem>('cart');
    cartItems = cartBox.values.toList();
    totalPrice = cartItems.fold(
      0,
      (total, item) => total + (item.price * item.quantity),
    );

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = Timestamp.now();

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final userData = userDoc.data();
      if (userData == null) return;

      final orderMetaRef = FirebaseFirestore.instance
          .collection('metadata')
          .doc('orders');
      final orderMetaSnap = await orderMetaRef.get();
      int current =
          orderMetaSnap.exists ? (orderMetaSnap['count'] ?? 1000) : 1000;
      final newOrderId = 'O${current + 1}';
      await orderMetaRef.set({'count': current + 1});

      final orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(newOrderId);
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      await orderRef.set({
        'orderId': newOrderId,
        'pickupPoint': widget.selectedPickupPoint,
        'rollNo': userRef,
        'orderDate': now,
        'status': 'Pending',
        'totalPrice': totalPrice,
      });

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

      await FirebaseFirestore.instance.collection('payments').add({
        'orderId': orderRef,
        'amount': totalPrice,
        'status': 'Success',
        'paymentTime': now,
        'userId': user.uid,
        'razorpayPaymentId': response.paymentId,
      });

      await cartBox.clear();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => OrderConfirmationPage(
                orderId: newOrderId,
                orderData: {
                  'name': userData['name'],
                  'rollNo': userData['rollNo'],
                  'phone': userData['phoneNo'],
                  'pickupPoint': widget.selectedPickupPoint,
                  'items': cartItems,
                  'total': totalPrice,
                },
              ),
        ),
      );
    } catch (e, st) {
      debugPrint("❌ Payment success handler error: $e");
      debugPrint("❌ Stacktrace: $st");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error after payment: $e")));
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment failed. Please try again.")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("External wallet selected.")));
  }

  void _openCheckout() {
    var options = {
      'key': 'rzp_test_9bd1gY6TxxSq6Q',
      'amount': (totalPrice * 100).toInt(),
      'name': 'KMIT Canteen',
      'description': 'Order Payment',
      'prefill': {'contact': '', 'email': ''},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Order Confirmation",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Image.network(
                        item.imageUrl ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            ),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text("x${item.quantity}"),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withAlpha((0.08 * 255).toInt()),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).primaryColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place),
                  const SizedBox(width: 8),
                  const Text(
                    "Pick-up Point:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.selectedPickupPoint,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  "Total:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  '₹${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _openCheckout,
                child: const Text(
                  "Pay & Confirm",
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
