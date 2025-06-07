import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:lottie/lottie.dart';

class OrderConfirmationPage extends StatefulWidget {
  final String orderId;

  const OrderConfirmationPage({super.key, required this.orderId});

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage>
    with TickerProviderStateMixin {
  bool showTick = false;
  bool hideDetails = false;
  bool showTyping = false;
  String typingText = "";
  String? previousStatus;
  final String finalMessage = "System.out.println('Lunch is ready');";

  late AnimationController qrSlideController;
  late Animation<Offset> qrSlideAnimation;

  late AnimationController messageSlideController;
  late Animation<Offset> messageSlideAnimation;

  @override
  void initState() {
    super.initState();

    qrSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    qrSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.7),
    ).animate(
      CurvedAnimation(parent: qrSlideController, curve: Curves.easeInOut),
    );

    messageSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    messageSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: messageSlideController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    qrSlideController.dispose();
    messageSlideController.dispose();
    super.dispose();
  }

  Future<void> triggerSequence() async {
    if (showTick) return;

    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 300);
      }
    } catch (_) {}

    setState(() {
      showTick = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      hideDetails = true;
    });

    await qrSlideController.forward();
    await messageSlideController.forward();

    setState(() {
      showTyping = true;
    });

    for (int i = 0; i <= finalMessage.length; i++) {
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;

      setState(() {
        typingText = finalMessage.substring(0, i);
      });

      try {
        Vibration.vibrate(duration: 6);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

          if (previousStatus != "Delivered" && status == "Delivered") {
            previousStatus = "Delivered";
            WidgetsBinding.instance.addPostFrameCallback((_) {
              triggerSequence();
            });
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.home),
                  tooltip: 'Go to Home',
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (_) => false);
                  },
                ),
              ),

              AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: hideDetails ? 0 : 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),
                      Center(
                        child: Text(
                          "✅ Order Confirmed",
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall!.copyWith(
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              "Order ID:",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge!.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              orderId,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium!.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Pickup Point: $pickup",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            "Current Status: ",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Chip(
                            label: Text(status),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Scan this at pickup:",
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              SlideTransition(
                position: qrSlideAnimation,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          QrImageView(
                            data:
                                'Order ID: $orderId\nPickup Point: $pickup\nTotal: ₹$total',
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                          if (showTick)
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: Container(
                                width: 200,
                                height: 200,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (showTick)
                      Lottie.asset(
                        'assets/animations/verify.json',
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        repeat: false,
                      ),
                  ],
                ),
              ),
              SlideTransition(
                position: messageSlideAnimation,
                child: Visibility(
                  visible: showTyping,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 250),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 100,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Courier',
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'System',
                                    style: TextStyle(color: Color(0xFF569CD6)),
                                  ),
                                  const TextSpan(
                                    text: '.out',
                                    style: TextStyle(color: Color(0xFF9CDCFE)),
                                  ),
                                  const TextSpan(
                                    text: '.println',
                                    style: TextStyle(color: Color(0xFFDCDCAA)),
                                  ),
                                  const TextSpan(
                                    text: '(',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  TextSpan(
                                    text:
                                        "'${typingText.replaceAll("System.out.println('", "").replaceAll("');", "")}'",
                                    style: const TextStyle(
                                      color: Color(0xFFCE9178),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ');',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushNamedAndRemoveUntil('/', (_) => false);
                            },
                            child: const Text("Go to Home"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
