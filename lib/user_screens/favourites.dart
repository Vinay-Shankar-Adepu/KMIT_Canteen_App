import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/cart_item.dart';
import '../widgets/item_card.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage>
    with TickerProviderStateMixin {
  final Box<CartItem> _cartBox = Hive.box<CartItem>('cart');
  int _selectedIndex = 0;
  late Stream<DocumentSnapshot> userStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final rollNo = user.email!.split('@').first;
      userStream =
          FirebaseFirestore.instance
              .collection('users')
              .doc(rollNo)
              .snapshots();
    }
  }

  Future<bool> _getCanteenStatus() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('canteenStatus')
            .doc('status')
            .get();
    return doc.data()?['isOnline'] ?? false;
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
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("No user logged in")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Favorites"), centerTitle: true),
      body: FutureBuilder<bool>(
        future: _getCanteenStatus(),
        builder: (context, statusSnapshot) {
          if (!statusSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final isOnline = statusSnapshot.data!;

          return StreamBuilder<DocumentSnapshot>(
            stream: userStream,
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final userDoc = userSnapshot.data!;
              final favorites =
                  (userDoc['favorites'] as List?)
                      ?.whereType<DocumentReference>()
                      .toList() ??
                  [];

              if (favorites.isEmpty) {
                return const Center(child: Text("No favorite items found."));
              }

              return FutureBuilder<List<DocumentSnapshot>>(
                future: Future.wait(favorites.map((ref) => ref.get())),
                builder: (context, favItemsSnapshot) {
                  if (favItemsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = favItemsSnapshot.data ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("No favorite items found."),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final itemDoc = docs[index];
                      if (!itemDoc.exists) return const SizedBox();

                      final data = itemDoc.data() as Map<String, dynamic>;
                      final itemId = itemDoc.id;
                      final isOutOfStock = data['availability'] == false;
                      final currentCartItem = _cartBox.get(itemId);
                      final isInCart = currentCartItem != null;

                      return ItemCard(
                        itemId: itemId,
                        title: data['name'] ?? '',
                        description: data['description'] ?? '',
                        label: '₹${data['price'] ?? 0}',
                        imageUrl: data['imageUrl'] ?? '',
                        availability: !isOutOfStock,
                        showQuantityControl: isInCart,
                        isCanteenOnline: isOnline,
                        isFavorite: true, // always true in this list
                        onFavoriteToggle:
                            () {}, // StreamBuilder will auto-refresh
                        onAddToCart:
                            isOutOfStock
                                ? null
                                : () {
                                  _cartBox.put(
                                    itemId,
                                    CartItem(
                                      itemId: itemId,
                                      name: data['name'] ?? '',
                                      price:
                                          (data['price'] as num?)?.toDouble() ??
                                          0.0,
                                      quantity: 1,
                                      imageUrl: data['imageUrl'] ?? '',
                                      description: data['description'] ?? '',
                                      category: data['category'] ?? '',
                                    ),
                                  );
                                },
                        onRemoveFromCart: () => _cartBox.delete(itemId),
                        onQuantityChanged: (qty) {
                          _cartBox.put(
                            itemId,
                            CartItem(
                              itemId: itemId,
                              name: data['name'] ?? '',
                              price: (data['price'] as num?)?.toDouble() ?? 0.0,
                              quantity: qty,
                              imageUrl: data['imageUrl'] ?? '',
                              description: data['description'] ?? '',
                              category: data['category'] ?? '',
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: _cartBox.listenable(),
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
                        color: Theme.of(context).primaryColor,
                        boxShadow: [
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              backgroundColor: Colors.white,
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
