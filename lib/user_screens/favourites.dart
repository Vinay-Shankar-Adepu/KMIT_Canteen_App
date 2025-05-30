// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import '../models/cart_item.dart';
// import '../widgets/item_card.dart';

// class FavouritesPage extends StatefulWidget {
//   const FavouritesPage({super.key});

//   @override
//   State<FavouritesPage> createState() => _FavouritesPageState();
// }

// class _FavouritesPageState extends State<FavouritesPage> {
//   final user = FirebaseAuth.instance.currentUser;

//   Future<void> _toggleFavorite(String itemId, bool isFav) async {
//     final rollNo = user?.email?.split('@').first;
//     if (rollNo == null) return;

//     final userDoc = FirebaseFirestore.instance.collection('users').doc(rollNo);
//     final itemRef = FirebaseFirestore.instance
//         .collection('menuItems')
//         .doc(itemId);

//     final snapshot = await userDoc.get();
//     if (!snapshot.exists) return;

//     await userDoc.update({
//       'favorites':
//           isFav
//               ? FieldValue.arrayRemove([itemRef])
//               : FieldValue.arrayUnion([itemRef]),
//     });

//     setState(() {});
//   }

//   Future<List<DocumentSnapshot>> _getFavoriteItems(List favorites) async {
//     List<DocumentSnapshot> items = [];
//     for (final ref in favorites) {
//       if (ref is DocumentReference) {
//         final doc = await ref.get();
//         if (doc.exists) items.add(doc);
//       }
//     }
//     return items;
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (user == null) {
//       return const Scaffold(body: Center(child: Text("User not logged in")));
//     }

//     final cartBox = Hive.box<CartItem>('cart');
//     final rollNo = user!.email!.split('@').first;

//     return Scaffold(
//       appBar: AppBar(title: const Text("My Favourites")),
//       body: FutureBuilder<DocumentSnapshot>(
//         future:
//             FirebaseFirestore.instance.collection('users').doc(rollNo).get(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final userData = snapshot.data!.data() as Map<String, dynamic>?;
//           final favRefs = userData?['favorites'] as List<dynamic>?;

//           if (favRefs == null || favRefs.isEmpty) {
//             return const Center(child: Text("No favourites found."));
//           }

//           return FutureBuilder<List<DocumentSnapshot>>(
//             future: _getFavoriteItems(favRefs),
//             builder: (context, favSnap) {
//               if (!favSnap.hasData) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               final items = favSnap.data!;
//               return ListView.builder(
//                 itemCount: items.length,
//                 itemBuilder: (context, index) {
//                   final doc = items[index];
//                   final data = doc.data() as Map<String, dynamic>;
//                   final itemId = doc.id;

//                   final existing = cartBox.get(itemId);
//                   final quantity = existing?.quantity ?? 0;
//                   final isInCart = quantity > 0;
//                   final isOutOfStock = data['availability'] == false;

//                   return ItemCard(
//                     itemId: itemId,
//                     title: data['name'] ?? '',
//                     description: data['description'] ?? '',
//                     label: '₹${data['price'] ?? 0}',
//                     imageUrl: data['imageUrl'] ?? '',
//                     showQuantityControl: isInCart,
//                     isFavorite: true,
//                     onFavoriteToggle:
//                         (isNowFav) => _toggleFavorite(itemId, !isNowFav),
//                     onAddToCart:
//                         isOutOfStock
//                             ? null
//                             : () {
//                               cartBox.put(
//                                 itemId,
//                                 CartItem(
//                                   itemId: itemId,
//                                   name: data['name'],
//                                   price: (data['price'] as num).toDouble(),
//                                   quantity: 1,
//                                   imageUrl: data['imageUrl'],
//                                   description: data['description'],
//                                   category: data['category'],
//                                 ),
//                               );
//                             },
//                     onRemoveFromCart: () => cartBox.delete(itemId),
//                     onQuantityChanged: (qty) {
//                       cartBox.put(
//                         itemId,
//                         CartItem(
//                           itemId: itemId,
//                           name: data['name'],
//                           price: (data['price'] as num).toDouble(),
//                           quantity: qty,
//                           imageUrl: data['imageUrl'],
//                           description: data['description'],
//                           category: data['category'],
//                         ),
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
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
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _toggleFavorite(String itemId, bool isFav) async {
    final userId = user?.uid;
    if (userId == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    final itemRef = FirebaseFirestore.instance
        .collection('menuItems')
        .doc(itemId);

    await userDoc.update({
      'favorites':
          isFav
              ? FieldValue.arrayRemove([itemRef])
              : FieldValue.arrayUnion([itemRef]),
    });

    setState(() {}); // Refresh UI
  }

  Future<List<DocumentSnapshot>> _getFavoriteItems(List favorites) async {
    List<DocumentSnapshot> items = [];
    for (final ref in favorites) {
      if (ref is DocumentReference) {
        final doc = await ref.get();
        if (doc.exists) items.add(doc);
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final cartBox = Hive.box<CartItem>('cart');

    return Scaffold(
      appBar: AppBar(title: const Text("My Favourites")),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final favRefs = userData?['favorites'] as List<dynamic>?;

          if (favRefs == null || favRefs.isEmpty) {
            return const Center(child: Text("No favourites found."));
          }

          return FutureBuilder<List<DocumentSnapshot>>(
            future: _getFavoriteItems(favRefs),
            builder: (context, favSnap) {
              if (!favSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = favSnap.data!;
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final doc = items[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final itemId = doc.id;

                  final existing = cartBox.get(itemId);
                  final quantity = existing?.quantity ?? 0;
                  final isInCart = quantity > 0;
                  final isOutOfStock = data['availability'] == false;

                  return ItemCard(
                    itemId: itemId,
                    title: data['name'] ?? '',
                    description: data['description'] ?? '',
                    label: '₹${data['price'] ?? 0}',
                    imageUrl: data['imageUrl'] ?? '',
                    showQuantityControl: isInCart,
                    isFavorite: true,
                    onFavoriteToggle: () => _toggleFavorite(itemId, true),
                    onAddToCart:
                        isOutOfStock
                            ? null
                            : () {
                              cartBox.put(
                                itemId,
                                CartItem(
                                  itemId: itemId,
                                  name: data['name'],
                                  price: (data['price'] as num).toDouble(),
                                  quantity: 1,
                                  imageUrl: data['imageUrl'],
                                  description: data['description'],
                                  category: data['category'],
                                ),
                              );
                            },
                    onRemoveFromCart: () => cartBox.delete(itemId),
                    onQuantityChanged: (qty) {
                      cartBox.put(
                        itemId,
                        CartItem(
                          itemId: itemId,
                          name: data['name'],
                          price: (data['price'] as num).toDouble(),
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
      ),
    );
  }
}
