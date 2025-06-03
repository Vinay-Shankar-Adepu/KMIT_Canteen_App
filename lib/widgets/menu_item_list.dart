import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item.dart';
import 'item_card.dart';

class MenuItemList extends StatelessWidget {
  final String searchQuery;
  final Function(Map<String, dynamic>) onAddToCart;
  final String filter;

  const MenuItemList({
    super.key,
    required this.searchQuery,
    required this.onAddToCart,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("User not logged in"));
    }

    final cartBox = Hive.box<CartItem>('cart');

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
      builder: (context, favSnapshot) {
        if (!favSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final favData = favSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final favRefs =
            (favData['favorites'] as List<dynamic>? ?? [])
                .whereType<DocumentReference>()
                .map((ref) => ref.id)
                .toList();

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('menuItems').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final filtered =
                snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if ((data['isSpecial'] ?? false) == true) return false;

                  final nameMatch = data['name']
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase());

                  if (filter == 'Most Ordered') return nameMatch;
                  if (filter.isNotEmpty) {
                    return nameMatch && data['category'] == filter;
                  }

                  return nameMatch;
                }).toList();

            if (filter == 'Most Ordered') {
              filtered.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                return (bData['orderCount'] ?? 0).compareTo(
                  aData['orderCount'] ?? 0,
                );
              });
            }

            if (filtered.isEmpty) return const Text("No items found.");

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final itemRef = filtered[index];
                final data = itemRef.data() as Map<String, dynamic>;
                final itemId = itemRef.id;
                final isOutOfStock = data['availability'] == false;
                final isFav = favRefs.contains(itemId);
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
                  isFavorite: isFav,
                  onFavoriteToggle: () async {
                    final favRef = FirebaseFirestore.instance
                        .collection('menuItems')
                        .doc(itemId);
                    final userDoc = FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid);

                    await userDoc.set({
                      'favorites':
                          isFav
                              ? FieldValue.arrayRemove([favRef])
                              : FieldValue.arrayUnion([favRef]),
                    }, SetOptions(merge: true));
                  },
                  onAddToCart:
                      isOutOfStock
                          ? null
                          : () => onAddToCart({
                            'itemId': itemId,
                            'name': data['name'],
                            'price': data['price'],
                            'imageUrl': data['imageUrl'],
                            'description': data['description'],
                            'category': data['category'],
                          }),
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
    );
  }
}
