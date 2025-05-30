import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/cart_item.dart';
import '../widgets/sidebar.dart';
import '../widgets/special_item_card.dart';
import '../widgets/menu_item_list.dart';
import '../widgets/reorder_list.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Box<CartItem> _cartBox;
  int _selectedIndex = 0;
  String _searchQuery = "";
  String _selectedFilter = '';

  @override
  void initState() {
    super.initState();
    _cartBox = Hive.box<CartItem>('cart');
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

  void _addToCart(Map<String, dynamic> item) {
    final existing = _cartBox.get(item['itemId']);

    if (existing != null) {
      existing.quantity += 1;
      _cartBox.put(existing.itemId, existing);
    } else {
      final newItem = CartItem(
        itemId: item['itemId'] ?? '',
        name: item['name'] ?? '',
        price: (item['price'] as num?)?.toDouble() ?? 0.0,
        quantity: 1,
        imageUrl: item['imageUrl'] ?? '',
        description: item['description'] ?? '',
        category: item['category'] ?? '',
      );
      _cartBox.put(newItem.itemId, newItem);
    }

    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Item added to cart")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const Sidebar(),
      appBar: AppBar(
        title: const Text("KMIT  🍴  CANTEEN"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => Navigator.pushNamed(context, '/favourites'),
          ),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              themeNotifier.value =
                  themeNotifier.value == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SpecialItemCard(onAddToCart: _addToCart),
            const SizedBox(height: 15),
            TextField(
              onChanged:
                  (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search for items...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<QuerySnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('orders')
                      .where(
                        'rollNo',
                        isEqualTo:
                            '/users/${FirebaseAuth.instance.currentUser?.uid}',
                      )
                      .orderBy('orderDate', descending: true)
                      .limit(1)
                      .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Re-Order:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ReorderList(addToCart: _addToCart),
                    const SizedBox(height: 15),
                  ],
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Menu:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_alt),
                  onSelected:
                      (value) => setState(() => _selectedFilter = value),
                  itemBuilder:
                      (context) => const [
                        PopupMenuItem(value: '', child: Text('All')),
                        PopupMenuItem(
                          value: 'Most Ordered',
                          child: Text('Most Ordered'),
                        ),
                        PopupMenuItem(value: 'Indian', child: Text('Indian')),
                        PopupMenuItem(value: 'Chinese', child: Text('Chinese')),
                        PopupMenuItem(
                          value: 'Beverages',
                          child: Text('Beverages'),
                        ),
                        PopupMenuItem(value: 'Snacks', child: Text('Snacks')),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            MenuItemList(
              searchQuery: _searchQuery,
              onAddToCart: _addToCart,
              filter: _selectedFilter,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
  }
}

// class SpecialItemCard extends StatelessWidget {
//   final Function(Map<String, dynamic>) onAddToCart;
//   const SpecialItemCard({super.key, required this.onAddToCart});

//   @override
//   Widget build(BuildContext context) {
//     final cartBoxItem = Hive.box<CartItem>('cart');

//     return StreamBuilder<QuerySnapshot>(
//       stream:
//           FirebaseFirestore.instance
//               .collection('menuItems')
//               .where('isSpecial', isEqualTo: true)
//               .limit(1)
//               .snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return const SizedBox();
//         }

//         final itemRef = snapshot.data!.docs.first;
//         final data = itemRef.data() as Map<String, dynamic>;

//         final isAvailable = data['availability'] ?? false;
//         if (!isAvailable) return const SizedBox();

//         return ValueListenableBuilder(
//           valueListenable: cartBoxItem.listenable(),
//           builder: (context, Box<CartItem> box, _) {
//             final existingInCart = box.get(itemRef.id);
//             final int quantityInCart = existingInCart?.quantity ?? 0;
//             final bool isInCart = quantityInCart > 0;

//             return Card(
//               elevation: 3,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ClipRRect(
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(10),
//                       topRight: Radius.circular(10),
//                     ),
//                     child:
//                         (data['imageURL'] != null &&
//                                 data['imageURL'].toString().isNotEmpty)
//                             ? Image.network(
//                               data['imageURL'],
//                               width: double.infinity,
//                               height: 150,
//                               fit: BoxFit.cover,
//                             )
//                             : Container(
//                               width: double.infinity,
//                               height: 150,
//                               color: Colors.grey[300],
//                               child: const Icon(Icons.image, size: 50),
//                             ),
//                   ),

//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 10,
//                     ),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 data['name'] ?? 'Title',
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 "₹ ${data['price']}",
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         isInCart
//                             ? Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 IconButton(
//                                   icon: const Icon(Icons.remove),
//                                   onPressed: () {
//                                     final newQty = quantityInCart - 1;
//                                     if (newQty <= 0) {
//                                       box.delete(itemRef.id);
//                                     } else {
//                                       box.put(
//                                         itemRef.id,
//                                         CartItem(
//                                           itemId: itemRef.id,
//                                           name: data['name'],
//                                           price:
//                                               (data['price'] as num).toDouble(),
//                                           quantity: newQty,
//                                           imageUrl: data['imageURL'],
//                                           description: data['description'],
//                                           category: data['category'],
//                                         ),
//                                       );
//                                     }
//                                   },
//                                 ),
//                                 Text('$quantityInCart'),
//                                 IconButton(
//                                   icon: const Icon(Icons.add),
//                                   onPressed: () {
//                                     box.put(
//                                       itemRef.id,
//                                       CartItem(
//                                         itemId: itemRef.id,
//                                         name: data['name'],
//                                         price:
//                                             (data['price'] as num).toDouble(),
//                                         quantity: quantityInCart + 1,
//                                         imageUrl: data['imageURL'],
//                                         description: data['description'],
//                                         category: data['category'],
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ],
//                             )
//                             : ElevatedButton(
//                               onPressed: () {
//                                 onAddToCart({
//                                   'itemId': itemRef.id,
//                                   'name': data['name'],
//                                   'price': data['price'],
//                                   'imageUrl': data['imageURL'],
//                                   'description': data['description'],
//                                   'category': data['category'],
//                                 });
//                               },
//                               child: const Text("ADD"),
//                             ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }

// class ReorderList extends StatelessWidget {
//   final Function(Map<String, dynamic>) addToCart;
//   const ReorderList({super.key, required this.addToCart});

//   @override
//   Widget build(BuildContext context) {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
//     final cartBoxItem = Hive.box<CartItem>('cart');

//     return FutureBuilder<QuerySnapshot>(
//       future:
//           FirebaseFirestore.instance
//               .collection('orders')
//               .where('rollNo', isEqualTo: userRef)
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
//                   return const SizedBox(); // skip invalid items
//                 }

//                 final itemRef = rawItemRef;

//                 return FutureBuilder<DocumentSnapshot>(
//                   future: itemRef.get(),
//                   builder: (context, menuItemSnap) {
//                     if (!menuItemSnap.hasData || !menuItemSnap.data!.exists) {
//                       return const Text("Item not found");
//                     }

//                     final data =
//                         menuItemSnap.data!.data() as Map<String, dynamic>;

//                     final itemId = itemRef.id;
//                     if (itemId == null || itemId.toString().isEmpty) {
//                       return const SizedBox();
//                     }

//                     return ValueListenableBuilder(
//                       valueListenable: cartBoxItem.listenable(),
//                       builder: (context, Box<CartItem> box, _) {
//                         final existingInCart = box.get(itemId);
//                         final int quantityInCart =
//                             existingInCart?.quantity ?? 0;
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
//                                 name: data['name'],
//                                 price:
//                                     (data['price'] as num?)?.toDouble() ?? 0.0,
//                                 quantity: newQty,
//                                 imageUrl: data['imageUrl'],
//                                 description: data['description'],
//                                 category: data['category'],
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

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance.collection('menuItems').snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final filtered =
//             snapshot.data!.docs.where((doc) {
//               final data = doc.data() as Map<String, dynamic>;
//               final isSpecial = data['isSpecial'] ?? false;
//               if (isSpecial) return false;

//               final nameMatch = data['name'].toString().toLowerCase().contains(
//                 searchQuery,
//               );

//               if (filter == 'Most Ordered') return nameMatch;
//               if (filter.isNotEmpty) {
//                 return nameMatch && data['category'] == filter;
//               }

//               return nameMatch;
//             }).toList();

//         if (filter == 'Most Ordered') {
//           filtered.sort((a, b) {
//             final aData = a.data() as Map<String, dynamic>;
//             final bData = b.data() as Map<String, dynamic>;
//             return (bData['orderCount'] ?? 0).compareTo(
//               aData['orderCount'] ?? 0,
//             );
//           });
//         }

//         if (filtered.isEmpty) return const Text("No items found.");

//         final cartBoxItem = Hive.box<CartItem>('cart');

//         return ListView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemCount: filtered.length,
//           itemBuilder: (context, index) {
//             final itemRef = filtered[index];
//             final String itemId = itemRef.id;

//             final data = itemRef.data() as Map<String, dynamic>;
//             final isOutOfStock = data['availability'] == false;

//             return ValueListenableBuilder(
//               valueListenable: cartBoxItem.listenable(),
//               builder: (context, Box<CartItem> box, _) {
//                 final CartItem? existingInCart = box.get(itemId);
//                 final int quantityInCart = existingInCart?.quantity ?? 0;
//                 final bool isInCart = quantityInCart > 0;

//                 return Stack(
//                   children: [
//                     ItemCard(
//                       title: data['name'] ?? 'Unnamed',
//                       description: data['description'] ?? '',
//                       label: '₹${data['price'] ?? 0}',
//                       imageUrl: data['imageUrl'] ?? '',
//                       initialQuantity: quantityInCart,
//                       showQuantityControl: isInCart,
//                       onAddToCart:
//                           isOutOfStock
//                               ? null
//                               : () => onAddToCart({
//                                 'itemId': itemId,
//                                 'name': data['name'],
//                                 'price': data['price'],
//                                 'imageUrl': data['imageUrl'],
//                                 'description': data['description'],
//                                 'category': data['category'],
//                               }),
//                       onQuantityChanged: (newQty) {
//                         if (newQty <= 0) {
//                           box.delete(itemId);
//                         } else {
//                           final updatedItem = CartItem(
//                             itemId: itemId,
//                             name: data['name'] ?? '',
//                             price: (data['price'] as num?)?.toDouble() ?? 0.0,
//                             quantity: newQty,
//                             imageUrl: data['imageUrl'] ?? '',
//                             description: data['description'] ?? '',
//                             category: data['category'] ?? '',
//                           );
//                           box.put(itemId, updatedItem);
//                         }
//                       },
//                       onRemoveFromCart: () => box.delete(itemId),
//                     ),
//                     if (isOutOfStock)
//                       Positioned(
//                         bottom: 15,
//                         right: 15,
//                         child: Container(
//                           padding: const EdgeInsets.all(5),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.withAlpha((0.8 * 255).toInt()),
//                             borderRadius: BorderRadius.circular(5),
//                           ),
//                           child: const Text(
//                             "Out of stock",
//                             style: TextStyle(color: Colors.white, fontSize: 12),
//                           ),
//                         ),
//                       ),
//                   ],
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }
