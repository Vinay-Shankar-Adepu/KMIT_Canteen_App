import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';

class ItemCard extends StatefulWidget {
  final String itemId;
  final String title;
  final String description;
  final String label;
  final String imageUrl;
  final bool availability;
  final bool showQuantityControl;
  final bool isCanteenOnline;
  final bool isFavorite;
  final VoidCallback? onAddToCart;
  final VoidCallback? onRemoveFromCart;
  final ValueChanged<int>? onQuantityChanged;
  final VoidCallback? onFavoriteToggle;

  const ItemCard({
    super.key,
    required this.itemId,
    required this.title,
    required this.description,
    required this.label,
    required this.imageUrl,
    required this.availability,
    required this.showQuantityControl,
    required this.isCanteenOnline,
    required this.isFavorite,
    this.onAddToCart,
    this.onRemoveFromCart,
    this.onQuantityChanged,
    this.onFavoriteToggle,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard>
    with SingleTickerProviderStateMixin {
  late bool _isFav;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _isFav = widget.isFavorite;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.7,
      upperBound: 1.0,
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  void _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final rollNo = user.email!.split('@').first;
    final userRef = FirebaseFirestore.instance.collection('users').doc(rollNo);
    final itemRef = FirebaseFirestore.instance
        .collection('menuItems')
        .doc(widget.itemId);

    setState(() => _isFav = !_isFav);
    _controller.forward(from: 0.7);

    await userRef.update({
      'favorites':
          _isFav
              ? FieldValue.arrayUnion([itemRef])
              : FieldValue.arrayRemove([itemRef]),
    });

    widget.onFavoriteToggle?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartBox = Hive.box<CartItem>('cart');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: cartBox.listenable(),
      builder: (context, Box<CartItem> box, _) {
        final CartItem? current = box.get(widget.itemId);
        final int quantity = current?.quantity ?? 0;
        final bool isInCart = quantity > 0;

        return Card(
          margin: const EdgeInsets.all(8),
          elevation: 3,
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ColorFiltered(
                    colorFilter:
                        widget.isCanteenOnline
                            ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            )
                            : const ColorFilter.matrix([
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
                      widget.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: _toggleFavorite,
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: Icon(
                          _isFav ? Icons.favorite : Icons.favorite_border,
                          color: _isFav ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.isCanteenOnline)
                      !widget.availability
                          ? _outOfStockBadge()
                          : !isInCart
                          ? ElevatedButton(
                            onPressed: widget.onAddToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                            ),
                            child: const Text("ADD"),
                          )
                          : _quantityControls(box, current, quantity, isDark),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _outOfStockBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        "Out of Stock",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _quantityControls(
    Box<CartItem> box,
    CartItem? current,
    int quantity,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              final newQty = quantity - 1;
              if (newQty <= 0) {
                box.delete(widget.itemId);
                widget.onRemoveFromCart?.call();
              } else {
                final updated = current!..quantity = newQty;
                box.put(widget.itemId, updated);
                widget.onQuantityChanged?.call(newQty);
              }
            },
          ),
          Text('$quantity'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              if (quantity >= 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Limit reached: Max 5 per item"),
                  ),
                );
                return;
              }

              final updated =
                  current ??
                        CartItem(
                          itemId: widget.itemId,
                          name: widget.title,
                          price:
                              double.tryParse(
                                widget.label.replaceAll(RegExp(r'[^\d.]'), ''),
                              ) ??
                              0.0,
                          quantity: 1,
                          imageUrl: widget.imageUrl,
                          description: widget.description,
                          category: "",
                        )
                    ..quantity += 1;

              box.put(widget.itemId, updated);
              widget.onQuantityChanged?.call(updated.quantity);
            },
          ),
        ],
      ),
    );
  }
}
