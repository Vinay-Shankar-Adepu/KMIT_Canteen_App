import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/cart_item.dart';
import 'confirmed_order_page.dart';
import 'pick_up_point.dart';

class PreviousOrdersPage extends StatefulWidget {
  const PreviousOrdersPage({super.key});

  @override
  State<PreviousOrdersPage> createState() => _PreviousOrdersPageState();
}

class _PreviousOrdersPageState extends State<PreviousOrdersPage>
    with TickerProviderStateMixin {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final cartBox = Hive.box<CartItem>('cart');
  final Map<String, bool> expanded = {};
  late AnimationController _slideController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/previousOrders');
        break;
      case 1:
        Navigator.pushNamed(context, '/cart');
        break;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("KMIT  🍴  CANTEEN"), centerTitle: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('canteenStatus')
                .doc('status')
                .snapshots(),
        builder: (context, canteenSnap) {
          if (!canteenSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final isOnline = canteenSnap.data!.get('isOnline') == true;

          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('orders')
                      .where('userId', isEqualTo: userId)
                      .orderBy('orderDate', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!.docs;
                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      "No previous orders found.",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onBackground,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final orderDoc = orders[index];
                    final orderId = orderDoc['orderId'];
                    final orderDate = orderDoc['orderDate'].toDate();
                    final orderRef = orderDoc.reference;
                    final isExpanded = expanded[orderId] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      color: colorScheme.surface,
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              "Order No: $orderId",
                              style: theme.textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              "Date: ${orderDate.toLocal()}",
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                            onTap: () {
                              setState(() {
                                expanded[orderId] = !isExpanded;
                              });
                            },
                          ),
                          if (isExpanded)
                            StreamBuilder<QuerySnapshot>(
                              stream:
                                  orderRef.collection('orderItems').snapshots(),
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
                                              item.data()
                                                  as Map<String, dynamic>;
                                          final itemName = data['name'] ?? '';
                                          final description =
                                              data['description'] ?? '';
                                          final imageUrl =
                                              data['imageUrl'] ?? '';

                                          return ListTile(
                                            leading:
                                                imageUrl.isNotEmpty
                                                    ? Image.network(
                                                      imageUrl,
                                                      width: 50,
                                                      height: 50,
                                                      fit: BoxFit.cover,
                                                    )
                                                    : const Icon(
                                                      Icons.image,
                                                      size: 50,
                                                    ),
                                            title: Text(itemName),
                                            subtitle: Text(description),
                                            trailing: Text(
                                              'Qty: $quantity',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                    const SizedBox(height: 12),
                                    if (!isOnline)
                                      Text(
                                        "Canteen is offline",
                                        style: TextStyle(
                                          color: colorScheme.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    if (isOnline)
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          foregroundColor:
                                              colorScheme.onPrimary,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      const PickupPointPage(),
                                            ),
                                          );
                                        },
                                        child: const Text("Re-Order"),
                                      ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => OrderConfirmationPage(
                                                  orderId: orderId,
                                                ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text("View Order"),
                                    ),
                                    const SizedBox(height: 10),
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
          );
        },
      ),
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: cartBox.listenable(),
        builder: (context, Box<CartItem> box, _) {
          final items = box.values.toList();
          final itemCount = items.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          );
          final total = items.fold<double>(
            0.0,
            (sum, item) => sum + item.price * item.quantity,
          );
          final showCartBar = itemCount > 0;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              final offsetAnim = Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animation);
              return SlideTransition(position: offsetAnim, child: child);
            },
            child:
                showCartBar
                    ? Container(
                      key: const ValueKey("cartBar"),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "$itemCount Item${itemCount > 1 ? 's' : ''}  ₹${total.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              backgroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed:
                                () => Navigator.pushNamed(context, '/cart'),
                            icon: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 20,
                            ),
                            label: const Text("View Cart"),
                          ),
                        ],
                      ),
                    )
                    : BottomNavigationBar(
                      key: const ValueKey("bottomNav"),
                      currentIndex: _selectedIndex,
                      onTap: _onBottomNavTap,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.history),
                          label: 'Previous Orders',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.shopping_cart),
                          label: 'Cart',
                        ),
                      ],
                    ),
          );
        },
      ),
    );
  }
}
