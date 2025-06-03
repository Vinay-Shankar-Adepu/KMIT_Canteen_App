import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item.dart';

class SpecialItemCard extends StatelessWidget {
  final Function(Map<String, dynamic>) onAddToCart;
  const SpecialItemCard({super.key, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
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
        if (!isAvailable) return const SizedBox();

        final itemId = itemRef.id;
        final cartBoxItem = Hive.box<CartItem>('cart');

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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
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
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text("₹ ${data['price']}"),
                                ],
                              ),
                            ),
                            isInCart
                                ? Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        final newQty = quantityInCart - 1;
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
                                              imageUrl: data['imageUrl'],
                                              description: data['description'],
                                              category: data['category'],
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    Text('$quantityInCart'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        box.put(
                                          itemId,
                                          CartItem(
                                            itemId: itemId,
                                            name: data['name'],
                                            price:
                                                (data['price'] as num)
                                                    .toDouble(),
                                            quantity: quantityInCart + 1,
                                            imageUrl: data['imageUrl'],
                                            description: data['description'],
                                            category: data['category'],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                )
                                : isAvailable
                                ? ElevatedButton(
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
                                  child: const Text("ADD"),
                                )
                                : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "Out of Stock",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
  }
}
