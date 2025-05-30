// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import '../models/cart_item.dart';
// import 'item_card.dart';

// class MenuItemList extends StatelessWidget {
//   final String searchQuery;
//   final Function(Map<String, dynamic>) onAddToCart;
//   final String filter;

//   const MenuItemList({
//     super.key,
//     required this.searchQuery,
//     required this.onAddToCart,
//     required this.filter,
//   });

//   Future<List<String>> _getUserFavorites() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return [];

//     final rollNo = user.email?.split('@').first;
//     if (rollNo == null) return [];

//     final doc =
//         await FirebaseFirestore.instance.collection('users').doc(rollNo).get();
//     final favRefs = doc.data()?['favorites'] as List<dynamic>? ?? [];
//     return favRefs.whereType<DocumentReference>().map((ref) => ref.id).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<String>>(
//       future: _getUserFavorites(),
//       builder: (context, favSnapshot) {
//         if (!favSnapshot.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final favIds = favSnapshot.data!;
//         return StreamBuilder<QuerySnapshot>(
//           stream:
//               FirebaseFirestore.instance.collection('menuItems').snapshots(),
//           builder: (context, snapshot) {
//             if (!snapshot.hasData) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             final filtered =
//                 snapshot.data!.docs.where((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   if ((data['isSpecial'] ?? false) == true) return false;

//                   final nameMatch = data['name']
//                       .toString()
//                       .toLowerCase()
//                       .contains(searchQuery.toLowerCase());

//                   if (filter == 'Most Ordered') return nameMatch;
//                   if (filter.isNotEmpty) {
//                     return nameMatch && data['category'] == filter;
//                   }

//                   return nameMatch;
//                 }).toList();

//             if (filter == 'Most Ordered') {
//               filtered.sort((a, b) {
//                 final aData = a.data() as Map<String, dynamic>;
//                 final bData = b.data() as Map<String, dynamic>;
//                 return (bData['orderCount'] ?? 0).compareTo(
//                   aData['orderCount'] ?? 0,
//                 );
//               });
//             }

//             if (filtered.isEmpty) return const Text("No items found.");

//             final cartBox = Hive.box<CartItem>('cart');

//             return ListView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: filtered.length,
//               itemBuilder: (context, index) {
//                 final itemRef = filtered[index];
//                 final data = itemRef.data() as Map<String, dynamic>;
//                 final isOutOfStock = data['availability'] == false;
//                 final itemId = itemRef.id;
//                 final isFav = favIds.contains(itemId);
//                 final currentCartItem = cartBox.get(itemId);
//                 final isInCart = currentCartItem != null;

//                 return ItemCard(
//                   itemId: itemId,
//                   title: data['name'] ?? '',
//                   description: data['description'] ?? '',
//                   label: '₹${data['price'] ?? 0}',
//                   imageUrl: data['imageUrl'] ?? '',
//                   showQuantityControl: isInCart,
//                   isFavorite: isFav,
//                   onFavoriteToggle: (isNowFav) async {
//                     final user = FirebaseAuth.instance.currentUser;
//                     if (user == null) return;

//                     final rollNo = user.email?.split('@').first;
//                     if (rollNo == null) return;

//                     final userDoc = FirebaseFirestore.instance
//                         .collection('users')
//                         .doc(rollNo);
//                     final itemDoc = FirebaseFirestore.instance
//                         .collection('menuItems')
//                         .doc(itemId);

//                     try {
//                       final userSnap = await userDoc.get();
//                       if (!userSnap.exists) return;

//                       await userDoc.update({
//                         'favorites':
//                             isNowFav
//                                 ? FieldValue.arrayUnion([itemDoc])
//                                 : FieldValue.arrayRemove([itemDoc]),
//                       });
//                     } catch (e) {
//                       debugPrint("❌ Failed to update favorites: $e");
//                     }
//                   },
//                   onAddToCart:
//                       isOutOfStock
//                           ? null
//                           : () => onAddToCart({
//                             'itemId': itemId,
//                             'name': data['name'],
//                             'price': data['price'],
//                             'imageUrl': data['imageUrl'],
//                             'description': data['description'],
//                             'category': data['category'],
//                           }),
//                   onRemoveFromCart: () => cartBox.delete(itemId),
//                   onQuantityChanged: (qty) {
//                     cartBox.put(
//                       itemId,
//                       CartItem(
//                         itemId: itemId,
//                         name: data['name'] ?? '',
//                         price: (data['price'] as num?)?.toDouble() ?? 0.0,
//                         quantity: qty,
//                         imageUrl: data['imageUrl'] ?? '',
//                         description: data['description'] ?? '',
//                         category: data['category'] ?? '',
//                       ),
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

  Future<List<String>> _getUserFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final favRefs = doc.data()?['favorites'] as List<dynamic>? ?? [];
    return favRefs.map((ref) => (ref as DocumentReference).id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _getUserFavorites(),
      builder: (context, favSnapshot) {
        if (!favSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final favIds = favSnapshot.data!;
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
                      .contains(searchQuery);
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

            final cartBox = Hive.box<CartItem>('cart');

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final itemRef = filtered[index];
                final data = itemRef.data() as Map<String, dynamic>;
                final isOutOfStock = data['availability'] == false;
                final itemId = itemRef.id;
                final inFav = favIds.contains(itemId);
                final currentCartItem = cartBox.get(itemId);
                final isInCart = currentCartItem != null;

                return ItemCard(
                  itemId: itemId,
                  title: data['name'] ?? '',
                  description: data['description'] ?? '',
                  label: '₹${data['price'] ?? 0}',
                  imageUrl: data['imageUrl'] ?? '',
                  showQuantityControl: isInCart,
                  isFavorite: inFav,
                  onFavoriteToggle: () async {
                    final userDoc = FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid);
                    final favRef = FirebaseFirestore.instance
                        .collection('menuItems')
                        .doc(itemId);
                    if (inFav) {
                      await userDoc.update({
                        'favorites': FieldValue.arrayRemove([favRef]),
                      });
                    } else {
                      await userDoc.update({
                        'favorites': FieldValue.arrayUnion([favRef]),
                      });
                    }
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
