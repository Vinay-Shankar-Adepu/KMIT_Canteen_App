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
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

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
              final roll = order['userId'];

              final userRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(roll);
              final itemsRef = orderRef.collection('orderItems');

              return FutureBuilder<DocumentSnapshot>(
                future: userRef.get(),
                builder: (context, userSnap) {
                  final userData =
                      userSnap.data?.data() as Map<String, dynamic>? ?? {};
                  final name = userData['name'] ?? 'Unknown';

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order ID: ${widget.orderId}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text("Name: $name", style: TextStyle(color: textColor)),
                        Text(
                          "Roll Number: $roll",
                          style: TextStyle(color: textColor),
                        ),
                        Text(
                          "Pickup Point: $pickup",
                          style: TextStyle(color: textColor),
                        ),
                        Text(
                          "Total: ₹$total",
                          style: TextStyle(color: textColor),
                        ),
                        Text(
                          "Status: ${isDelivered ? 'Delivered' : status}",
                          style: TextStyle(
                            color: isDelivered ? Colors.green : textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Items Ordered:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: itemsRef.snapshots(),
                            builder: (context, itemsSnap) {
                              if (!itemsSnap.hasData) {
                                return const CircularProgressIndicator();
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
                                          style: TextStyle(color: textColor),
                                        ),
                                        subtitle: Text(
                                          "Quantity: $quantity",
                                          style: TextStyle(
                                            color: textColor.withOpacity(0.7),
                                          ),
                                        ),
                                        trailing: Text(
                                          "₹${price * quantity}",
                                          style: TextStyle(color: textColor),
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
                        isDelivered
                            ? const SizedBox.shrink()
                            : ElevatedButton.icon(
                              onPressed:
                                  status == 'Delivered'
                                      ? null
                                      : () async {
                                        await orderRef.update({
                                          'status': 'Delivered',
                                        });
                                        await triggerDeliveryFeedback();
                                      },
                              icon: const Icon(Icons.check),
                              label: const Text("Confirm Delivery"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
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
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(color: Colors.black.withOpacity(0.3)),
                  ),
                  Center(
                    child: Lottie.asset(
                      'assets/animations/delivery_verify.json',
                      height: 220,
                      width: 220,
                      repeat: false,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
