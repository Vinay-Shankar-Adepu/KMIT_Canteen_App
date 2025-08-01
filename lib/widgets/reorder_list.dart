import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'item_card.dart';
import '../models/cart_item.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ReorderList extends StatelessWidget {
  final Function(Map<String, dynamic>) addToCart;

  const ReorderList({super.key, required this.addToCart});

  Future<bool> _fetchCanteenStatus() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('canteenStatus')
            .doc('status')
            .get();
    return doc.data()?['isOnline'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    final rollNo = user.email?.split('@').first;
    if (rollNo == null) return const SizedBox();

    final cartBox = Hive.box<CartItem>('cart');

    return FutureBuilder<bool>(
      future: _fetchCanteenStatus(),
      builder: (context, canteenSnapshot) {
        if (!canteenSnapshot.hasData) return const SizedBox();
        final isOnline = canteenSnapshot.data!;

        return FutureBuilder<QuerySnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('orders')
                  .where('rollNo', isEqualTo: rollNo)
                  .orderBy('orderDate', descending: true)
                  .limit(1)
                  .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox();
            }

            final order = snapshot.data!.docs.first;

            return StreamBuilder<QuerySnapshot>(
              stream: order.reference.collection('orderItems').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const SizedBox();
                }

                final items = snap.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final itemRef = items[index]['itemId'];
                    if (itemRef == null || itemRef is! DocumentReference) {
                      return const SizedBox();
                    }

                    return FutureBuilder<DocumentSnapshot>(
                      future: itemRef.get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const SizedBox();
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final itemId = itemRef.id;
                        final isOutOfStock = data['availability'] == false;
                        final existing = cartBox.get(itemId);
                        final quantity = existing?.quantity ?? 0;
                        final isInCart = quantity > 0;

                        return ItemCard(
                          itemId: itemId,
                          title: data['name'] ?? 'Unnamed',
                          description: data['description'] ?? '',
                          label: '₹${data['price'] ?? 0}',
                          imageUrl: data['imageUrl'] ?? '',
                          availability: !isOutOfStock,
                          showQuantityControl: isInCart,
                          isFavorite: false, // ✅ No heart icon in reorder
                          isCanteenOnline: isOnline,
                          onAddToCart:
                              isOutOfStock
                                  ? null
                                  : () => addToCart({
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
                                name: data['name'],
                                price: (data['price'] as num?)?.toDouble() ?? 0,
                                quantity: qty,
                                imageUrl: data['imageUrl'],
                                description: data['description'],
                                category: data['category'],
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
        );
      },
    );
  }
}
