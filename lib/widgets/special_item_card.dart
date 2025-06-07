import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item.dart';

class SpecialItemCard extends StatelessWidget {
  final Function(Map<String, dynamic>) onAddToCart;
  const SpecialItemCard({super.key, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('canteenStatus')
              .doc('status')
              .snapshots(),
      builder: (context, statusSnapshot) {
        if (!statusSnapshot.hasData) return const SizedBox();
        final data = statusSnapshot.data!.data() as Map<String, dynamic>?;
        final isOnline = data?['isOnline'] ?? false;

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('menuItems')
                  .where('isSpecial', isEqualTo: true)
                  .limit(1)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox();
            }

            final itemRef = snapshot.data!.docs.first;
            final data = itemRef.data() as Map<String, dynamic>;
            final isAvailable = data['availability'] == true;
            final itemId = itemRef.id;
            final cartBoxItem = Hive.box<CartItem>('cart');

            if (!isAvailable && isOnline) return const SizedBox();

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  child: Text(
                    "Today's Special 🔥",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: cartBoxItem.listenable(),
                  builder: (context, Box<CartItem> box, _) {
                    final existingInCart = box.get(itemId);
                    final quantityInCart = existingInCart?.quantity ?? 0;
                    final isInCart = quantityInCart > 0;

                    return Card(
                      elevation: 3,
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            child: ColorFiltered(
                              colorFilter:
                                  isOnline
                                      ? const ColorFilter.mode(
                                        Colors.transparent,
                                        BlendMode.multiply,
                                      )
                                      : const ColorFilter.matrix(<double>[
                                        0.2126,
                                        0.7152,
                                        0.0722,
                                        0,
                                        0,
                                        0.2126,
                                        0.7152,
                                        0.0722,
                                        0,
                                        0,
                                        0.2126,
                                        0.7152,
                                        0.0722,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        1,
                                        0,
                                      ]),
                              child: Image.network(
                                data['imageUrl'] ?? '',
                                width: double.infinity,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Container(
                                      height: 150,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image),
                                    ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? '',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "₹ ${data['price']}",
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOnline)
                                  isInCart
                                      ? Container(
                                        decoration: BoxDecoration(
                                          color:
                                              isDark
                                                  ? const Color(0xFF2C2C2C)
                                                  : const Color(0xFFE0E0E0),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () {
                                                final newQty =
                                                    quantityInCart - 1;
                                                if (newQty <= 0) {
                                                  box.delete(itemId);
                                                } else {
                                                  box.put(
                                                    itemId,
                                                    CartItem(
                                                      itemId: itemId,
                                                      name: data['name'],
                                                      price:
                                                          (data['price'] as num)
                                                              .toDouble(),
                                                      quantity: newQty,
                                                      imageUrl:
                                                          data['imageUrl'],
                                                      description:
                                                          data['description'],
                                                      category:
                                                          data['category'],
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            Text('$quantityInCart'),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () {
                                                if (quantityInCart >= 5) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "Limit reached: Max 5 per item",
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }

                                                box.put(
                                                  itemId,
                                                  CartItem(
                                                    itemId: itemId,
                                                    name: data['name'],
                                                    price:
                                                        (data['price'] as num)
                                                            .toDouble(),
                                                    quantity:
                                                        quantityInCart + 1,
                                                    imageUrl: data['imageUrl'],
                                                    description:
                                                        data['description'],
                                                    category: data['category'],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      )
                                      : ElevatedButton(
                                        onPressed: () {
                                          onAddToCart({
                                            'itemId': itemId,
                                            'name': data['name'],
                                            'price': data['price'],
                                            'imageUrl': data['imageUrl'],
                                            'description': data['description'],
                                            'category': data['category'],
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text("ADD"),
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
