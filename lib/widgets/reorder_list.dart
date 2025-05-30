// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import '../models/cart_item.dart';
// import 'item_card.dart';

// class ReorderList extends StatelessWidget {
//   final Function(Map<String, dynamic>) addToCart;
//   const ReorderList({super.key, required this.addToCart});

//   @override
//   Widget build(BuildContext context) {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     final cartBox = Hive.box<CartItem>('cart');

//     if (userId == null) return const SizedBox();

//     return FutureBuilder<QuerySnapshot>(
//       future:
//           FirebaseFirestore.instance
//               .collection('orders')
//               .where('rollNo', isEqualTo: '/users/$userId')
//               .orderBy('orderDate', descending: true)
//               .limit(1)
//               .get(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return const SizedBox();
//         }

//         final orderDoc = snapshot.data!.docs.first;

//         return StreamBuilder<QuerySnapshot>(
//           stream: orderDoc.reference.collection('orderItems').snapshots(),
//           builder: (context, itemsSnap) {
//             if (!itemsSnap.hasData || itemsSnap.data!.docs.isEmpty) {
//               return const SizedBox();
//             }

//             return ListView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: itemsSnap.data!.docs.length,
//               itemBuilder: (context, index) {
//                 final orderItem = itemsSnap.data!.docs[index];
//                 final dynamic rawItemRef = orderItem['itemId'];

//                 if (rawItemRef == null || rawItemRef is! DocumentReference) {
//                   return const SizedBox(); // Skip invalid items
//                 }

//                 final itemRef = rawItemRef;

//                 return FutureBuilder<DocumentSnapshot>(
//                   future: itemRef.get(),
//                   builder: (context, menuItemSnap) {
//                     if (!menuItemSnap.hasData || !menuItemSnap.data!.exists) {
//                       return const SizedBox();
//                     }

//                     final data =
//                         menuItemSnap.data!.data() as Map<String, dynamic>;
//                     final itemId = itemRef.id;

//                     return ValueListenableBuilder(
//                       valueListenable: cartBox.listenable(),
//                       builder: (context, Box<CartItem> box, _) {
//                         final existingInCart = box.get(itemId);
//                         final quantityInCart = existingInCart?.quantity ?? 0;
//                         final bool isInCart = quantityInCart > 0;

//                         return ItemCard(
//                           title: data['name'] ?? 'No Name',
//                           description: data['description'] ?? '',
//                           label: '₹${data['price'] ?? 0}',
//                           imageUrl: data['imageUrl'] ?? '',
//                           initialQuantity: quantityInCart,
//                           showQuantityControl: isInCart,
//                           onAddToCart: () {
//                             addToCart({
//                               'itemId': itemId,
//                               'name': data['name'],
//                               'price': data['price'],
//                               'imageUrl': data['imageUrl'],
//                               'description': data['description'],
//                               'category': data['category'],
//                             });
//                           },
//                           onQuantityChanged: (newQty) {
//                             if (newQty <= 0) {
//                               box.delete(itemId);
//                             } else {
//                               final updatedItem = CartItem(
//                                 itemId: itemId,
//                                 name: data['name'] ?? '',
//                                 price:
//                                     (data['price'] as num?)?.toDouble() ?? 0.0,
//                                 quantity: newQty,
//                                 imageUrl: data['imageUrl'] ?? '',
//                                 description: data['description'] ?? '',
//                                 category: data['category'] ?? '',
//                               );
//                               box.put(itemId, updatedItem);
//                             }
//                           },
//                           onRemoveFromCart: () => box.delete(itemId),
//                         );
//                       },
//                     );
//                   },
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'item_card.dart';
import '../models/cart_item.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ReorderList extends StatelessWidget {
  final Function(Map<String, dynamic>) addToCart;
  const ReorderList({super.key, required this.addToCart});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const SizedBox();
    }

    final cartBox = Hive.box<CartItem>('cart');

    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('orders')
              .where('rollNo', isEqualTo: '/users/$userId')
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

                    final data = snapshot.data!.data() as Map<String, dynamic>;
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
                      showQuantityControl: isInCart,
                      isFavorite: false, // Not needed in reorder list
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
                            price: (data['price'] as num?)?.toDouble() ?? 0.0,
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
  }
}
