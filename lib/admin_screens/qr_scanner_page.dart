import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lottie/lottie.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'admin_dashboard.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  void handleScan(String code) async {
    if (_hasScanned) return;
    _hasScanned = true;

    await _controller.stop();

    final lines = code.split('\n');
    final orderLine = lines.firstWhere(
      (line) => line.startsWith('Order ID:'),
      orElse: () => '',
    );

    if (orderLine.isNotEmpty) {
      final orderId = orderLine.replaceAll('Order ID:', '').trim();
      Future.delayed(const Duration(milliseconds: 200), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderVerificationPage(orderId: orderId),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid QR Code")));
      await _controller.start();
      _hasScanned = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code")),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final code = capture.barcodes.first.rawValue;
          if (code != null) {
            handleScan(code);
          }
        },
      ),
    );
  }
}

class OrderVerificationPage extends StatefulWidget {
  final String orderId;
  const OrderVerificationPage({super.key, required this.orderId});

  @override
  State<OrderVerificationPage> createState() => _OrderVerificationPageState();
}

class _OrderVerificationPageState extends State<OrderVerificationPage> {
  bool isDelivered = false;

  Future<void> triggerDeliveryFeedback() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 300);
      }
    } catch (_) {}

    final player = AudioPlayer();
    await player.play(AssetSource('audio/confirmation.mp3'));

    setState(() => isDelivered = true);

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminDashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelStyle = TextStyle(fontWeight: FontWeight.bold, color: textColor);

    final orderRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId);

    return Scaffold(
      appBar: AppBar(title: const Text("Verify Order")),
      body: Stack(
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: orderRef.get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("Order not found."));
              }

              final order = snapshot.data!.data() as Map<String, dynamic>;
              final status = order['status'];
              final pickup = order['pickupPoint'];
              final total = order['totalPrice'];

              String? userId;
              if (order['userId'] is DocumentReference) {
                userId = (order['userId'] as DocumentReference).id;
              } else if (order['userId'] is String) {
                userId = order['userId'];
              }
              if (userId == null) {
                return const Center(child: Text("User ID not found."));
              }

              final userRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId);
              final itemsRef = orderRef.collection('orderItems');

              if (status == 'Delivered') {
                return const Center(
                  child: Text(
                    "✅ This order has already been delivered.",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: userRef.get(),
                builder: (context, userSnap) {
                  final userData =
                      userSnap.data?.data() as Map<String, dynamic>? ?? {};
                  final name = userData['name'] ?? 'Unknown';
                  final rollNo = userRef.id;

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Order ID: ${widget.orderId}",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 20),
                            const SizedBox(width: 8),
                            Text("Name: ", style: labelStyle),
                            Text(name, style: TextStyle(color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.badge, size: 20),
                            const SizedBox(width: 8),
                            Text("Roll Number: ", style: labelStyle),
                            Text(rollNo, style: TextStyle(color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 8),
                            Text("Pickup Point: ", style: labelStyle),
                            Text(pickup, style: TextStyle(color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.payments, color: Colors.green),
                            const SizedBox(width: 8),
                            Text("Total: ", style: labelStyle),
                            Text("₹$total", style: TextStyle(color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text("🧾 Items Ordered:", style: labelStyle),
                        const SizedBox(height: 8),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: itemsRef.snapshots(),
                            builder: (context, itemsSnap) {
                              if (!itemsSnap.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final items = itemsSnap.data!.docs;

                              return ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final itemData =
                                      items[index].data()
                                          as Map<String, dynamic>;
                                  final quantity = itemData['quantity'];
                                  final price = itemData['price'];
                                  final itemRef =
                                      itemData['itemId'] as DocumentReference;

                                  return FutureBuilder<DocumentSnapshot>(
                                    future: itemRef.get(),
                                    builder: (context, snap) {
                                      if (!snap.hasData) {
                                        return const ListTile(
                                          title: Text("Loading item..."),
                                        );
                                      }
                                      final name = snap.data!.get('name');
                                      return ListTile(
                                        title: Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Qty: $quantity",
                                          style: TextStyle(
                                            color: textColor.withOpacity(0.7),
                                          ),
                                        ),
                                        trailing: Text(
                                          "₹${price * quantity}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: textColor,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed:
                              status == 'Delivered'
                                  ? null
                                  : () async {
                                    await orderRef.update({
                                      'status': 'Delivered',
                                      'deliveredAt':
                                          FieldValue.serverTimestamp(),
                                    });
                                    await triggerDeliveryFeedback();
                                  },
                          icon: const Icon(Icons.check),
                          label: Text(
                            status == 'Delivered'
                                ? "Already Delivered"
                                : "Confirm Delivery",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                status == 'Delivered'
                                    ? Colors.grey
                                    : Colors.green,
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          if (isDelivered)
            Positioned.fill(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(color: Colors.black.withOpacity(0.3)),
                  ),
                  Lottie.asset(
                    'assets/animations/delivery_verify.json',
                    height: 320,
                    width: 320,
                    repeat: false,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
