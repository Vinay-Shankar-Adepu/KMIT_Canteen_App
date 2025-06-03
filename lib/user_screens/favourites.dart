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

class _FavouritesPageState extends State<FavouritesPage> {
  late Stream<DocumentSnapshot> userStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userStream =
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots();
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: userStream,
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final favRefs =
              userSnapshot.data?.get('favorites') as List<dynamic>? ?? [];

          if (favRefs.isEmpty) {
            return const Center(child: Text("No favorite items found."));
          }

          return FutureBuilder<List<DocumentSnapshot>>(
            future: Future.wait(
              favRefs
                  .whereType<DocumentReference>()
                  .map((ref) => ref.get())
                  .toList(),
            ),
            builder: (context, favItemsSnapshot) {
              if (favItemsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = favItemsSnapshot.data ?? [];

              if (docs.isEmpty) {
                return const Center(child: Text("No favorite items found."));
              }

              final cartBox = Hive.box<CartItem>('cart');

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final itemDoc = docs[index];
                  final data = itemDoc.data() as Map<String, dynamic>;
                  final itemId = itemDoc.id;
                  final isOutOfStock = data['availability'] == false;
                  final currentCartItem = cartBox.get(itemId);
                  final isInCart = currentCartItem != null;

                  return ItemCard(
                    itemId: itemId,
                    title: data['name'] ?? '',
                    description: data['description'] ?? '',
                    label: '₹${data['price'] ?? 0}',
                    imageUrl: data['imageUrl'] ?? '',
                    availability: !isOutOfStock,
                    showQuantityControl: isInCart,
                    isFavorite: true,
                    onFavoriteToggle: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .set({
                            'favorites': FieldValue.arrayRemove([
                              itemDoc.reference,
                            ]),
                          }, SetOptions(merge: true));
                    },
                    onAddToCart:
                        isOutOfStock
                            ? null
                            : () {
                              cartBox.put(
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
                    onRemoveFromCart: () => cartBox.delete(itemId),
                    onQuantityChanged: (qty) {
                      cartBox.put(
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
      ),
    );
  }
}
