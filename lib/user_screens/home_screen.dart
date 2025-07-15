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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Box<CartItem> _cartBox;
  int _selectedIndex = 0;
  String _searchQuery = "";
  String _selectedFilter = '';
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _cartBox = Hive.box<CartItem>('cart');
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final rollNumber = user?.email?.split('@').first ?? "";

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SpecialItemCard(onAddToCart: _addToCart),
          const SizedBox(height: 15),
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: "Search for items...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          /// Reorder Section
          FutureBuilder<QuerySnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('orders')
                    .where('rollNo', isEqualTo: rollNumber)
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ReorderList(addToCart: _addToCart),
                  const SizedBox(height: 15),
                ],
              );
            },
          ),

          /// Menu with inline offline status
          StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('canteenStatus')
                    .doc('status')
                    .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final isOnline = data?['isOnline'] ?? true;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Menu:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isOnline) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.circle, color: Colors.red, size: 10),
                        const SizedBox(width: 6),
                        const Text(
                          "Canteen Offline",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
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
                          PopupMenuItem(
                            value: 'Chinese',
                            child: Text('Chinese'),
                          ),
                          PopupMenuItem(
                            value: 'Beverages',
                            child: Text('Beverages'),
                          ),
                          PopupMenuItem(value: 'Snacks', child: Text('Snacks')),
                        ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),

          /// Menu Item List
          MenuItemList(
            searchQuery: _searchQuery,
            onAddToCart: _addToCart,
            filter: _selectedFilter,
          ),
        ],
      ),

      /// Bottom Cart or NavBar
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
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, -1),
                            blurRadius: 12,
                          ),
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
