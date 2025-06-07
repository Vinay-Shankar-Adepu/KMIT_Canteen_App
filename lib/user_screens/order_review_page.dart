import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item.dart';
import 'confirmed_order_page.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class OrderReviewPage extends StatefulWidget {
  final String selectedPickupPoint;

  const OrderReviewPage({super.key, required this.selectedPickupPoint});

  @override
  State<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends State<OrderReviewPage>
    with SingleTickerProviderStateMixin {
  late Box<CartItem> cartBox;
  late List<CartItem> cartItems;
  late double totalPrice;
  bool _isPlacingOrder = false;
  late Razorpay _razorpay;
  late AnimationController _btnController;

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

    _btnController = AnimationController(
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 0.1,
      vsync: this,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _placeOrder();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  Future<void> _startPayment() async {
    await _btnController.forward();
    await _btnController.reverse();

    var options = {
      'key': 'rzp_test_4sHatsNBeRQefo',
      'amount': (totalPrice * 100).toInt(),
      'name': 'KMIT Canteen',
      'description': 'Order Payment',
      'prefill': {'contact': '9999999999', 'email': 'test@kmit.in'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay error: $e');
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw "User not logged in";

      final userSnap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final rollNumber = userSnap.exists ? userSnap.id : "anonymous";

      final now = Timestamp.now();
      final metaRef = FirebaseFirestore.instance
          .collection('metadata')
          .doc('orders');
      final metaSnap = await metaRef.get();
      int current = metaSnap.exists ? (metaSnap['count'] ?? 1000) : 1000;
      final newOrderId = 'O${current + 1}';

      final orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(newOrderId);

      await metaRef.set({'count': current + 1});
      await orderRef.set({
        'orderId': newOrderId,
        'pickupPoint': widget.selectedPickupPoint,
        'orderDate': now,
        'status': 'Pending',
        'totalPrice': totalPrice,
        'userId': rollNumber,
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

      await cartBox.clear();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmationPage(orderId: newOrderId),
        ),
      );
    } catch (e) {
      debugPrint("❌ Order error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to place order.")));
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _btnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("KMIT  🍴  CANTEEN"), centerTitle: true),
      body:
          cartItems.isEmpty
              ? const Center(child: Text("Your cart is empty."))
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order Review",
                      style: theme.textTheme.headlineSmall?.copyWith(
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
                            color: theme.colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl ?? '',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => const Icon(Icons.image),
                                ),
                              ),
                              title: Text(
                                item.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              trailing: Text(
                                "x${item.quantity}",
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Total: ",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "₹${totalPrice.toStringAsFixed(2)}",
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTapDown: (_) => _btnController.forward(),
                      onTapUp: (_) {
                        _btnController.reverse();
                        if (!_isPlacingOrder) _startPayment();
                      },
                      child: AnimatedBuilder(
                        animation: _btnController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1 - _btnController.value,
                            child: child,
                          );
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isPlacingOrder ? null : _startPayment,

                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _isPlacingOrder
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      "Pay & Confirm",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
