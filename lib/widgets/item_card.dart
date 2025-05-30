// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import '../models/cart_item.dart';

// class ItemCard extends StatefulWidget {
//   final String itemId;
//   final String title;
//   final String description;
//   final String label;
//   final String imageUrl;
//   final bool showQuantityControl;
//   final bool isFavorite;
//   final VoidCallback? onAddToCart;
//   final VoidCallback? onRemoveFromCart;
//   final ValueChanged<int>? onQuantityChanged;
//   final ValueChanged<bool>? onFavoriteToggle; // ✅ updated type

//   const ItemCard({
//     super.key,
//     required this.itemId,
//     required this.title,
//     required this.description,
//     required this.label,
//     required this.imageUrl,
//     required this.showQuantityControl,
//     required this.isFavorite,
//     this.onAddToCart,
//     this.onRemoveFromCart,
//     this.onQuantityChanged,
//     this.onFavoriteToggle,
//   });

//   @override
//   State<ItemCard> createState() => _ItemCardState();
// }

// class _ItemCardState extends State<ItemCard>
//     with SingleTickerProviderStateMixin {
//   late bool _isFav;
//   late AnimationController _controller;
//   late Animation<double> _scaleAnim;

//   @override
//   void initState() {
//     super.initState();
//     _isFav = widget.isFavorite;

//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 200),
//       lowerBound: 0.7,
//       upperBound: 1.0,
//     );

//     _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
//   }

//   @override
//   void didUpdateWidget(covariant ItemCard oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.isFavorite != widget.isFavorite) {
//       _isFav = widget.isFavorite;
//     }
//   }

//   void _toggleFavorite() {
//     setState(() => _isFav = !_isFav);
//     _controller.forward(from: 0.7);
//     widget.onFavoriteToggle?.call(_isFav); // ✅ Pass new state to parent
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cartBox = Hive.box<CartItem>('cart');

//     return ValueListenableBuilder(
//       valueListenable: cartBox.listenable(),
//       builder: (context, Box<CartItem> box, _) {
//         final CartItem? current = box.get(widget.itemId);
//         final int quantity = current?.quantity ?? 0;
//         final bool isInCart = quantity > 0;

//         return Card(
//           margin: const EdgeInsets.all(8),
//           elevation: 3,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(10),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Image.network(
//                     widget.imageUrl,
//                     width: 60,
//                     height: 60,
//                     fit: BoxFit.cover,
//                     errorBuilder:
//                         (_, __, ___) => Container(
//                           width: 60,
//                           height: 60,
//                           color: Colors.grey[300],
//                           child: const Icon(Icons.image),
//                         ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         widget.title,
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                         widget.description,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 5),
//                       Text(
//                         widget.label,
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Column(
//                   children: [
//                     GestureDetector(
//                       onTap: _toggleFavorite,
//                       child: ScaleTransition(
//                         scale: _scaleAnim,
//                         child: Icon(
//                           _isFav ? Icons.favorite : Icons.favorite_border,
//                           color: _isFav ? Colors.red : Colors.grey,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     if (!isInCart)
//                       ElevatedButton(
//                         onPressed: widget.onAddToCart,
//                         child: const Text("ADD"),
//                       ),
//                     if (isInCart)
//                       Row(
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.remove),
//                             onPressed: () {
//                               final newQty = quantity - 1;
//                               if (newQty <= 0) {
//                                 box.delete(widget.itemId);
//                                 widget.onRemoveFromCart?.call();
//                               } else {
//                                 final updated = current!..quantity = newQty;
//                                 box.put(widget.itemId, updated);
//                                 widget.onQuantityChanged?.call(newQty);
//                               }
//                             },
//                           ),
//                           Text('$quantity'),
//                           IconButton(
//                             icon: const Icon(Icons.add),
//                             onPressed: () {
//                               final updated =
//                                   current == null
//                                         ? CartItem(
//                                           itemId: widget.itemId,
//                                           name: widget.title,
//                                           price:
//                                               double.tryParse(
//                                                 widget.label.replaceAll(
//                                                   RegExp(r'[^\d.]'),
//                                                   '',
//                                                 ),
//                                               ) ??
//                                               0.0,
//                                           quantity: 1,
//                                           imageUrl: widget.imageUrl,
//                                           description: widget.description,
//                                           category: "",
//                                         )
//                                         : current!
//                                     ..quantity += 1;

//                               box.put(widget.itemId, updated);
//                               widget.onQuantityChanged?.call(updated.quantity);
//                             },
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item.dart';

class ItemCard extends StatefulWidget {
  final String itemId;
  final String title;
  final String description;
  final String label;
  final String imageUrl;
  final bool showQuantityControl;
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
    required this.showQuantityControl,
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

  void _toggleFavorite() {
    setState(() => _isFav = !_isFav);
    _controller.forward(from: 0.7);
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

    return ValueListenableBuilder(
      valueListenable: cartBox.listenable(),
      builder: (context, Box<CartItem> box, _) {
        final CartItem? current = box.get(widget.itemId);
        final int quantity = current?.quantity ?? 0;
        final bool isInCart = quantity > 0;

        return Card(
          margin: const EdgeInsets.all(8),
          elevation: 3,
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                    if (!isInCart)
                      ElevatedButton(
                        onPressed: widget.onAddToCart,
                        child: const Text("ADD"),
                      ),
                    if (isInCart)
                      Row(
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
                              final updated =
                                  current == null
                                        ? CartItem(
                                          itemId: widget.itemId,
                                          name: widget.title,
                                          price:
                                              double.tryParse(
                                                widget.label.replaceAll(
                                                  RegExp(r'[^\d.]'),
                                                  '',
                                                ),
                                              ) ??
                                              0.0,
                                          quantity: 1,
                                          imageUrl: widget.imageUrl,
                                          description: widget.description,
                                          category: "",
                                        )
                                        : current!
                                    ..quantity += 1;
                              box.put(widget.itemId, updated);
                              widget.onQuantityChanged?.call(updated.quantity);
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
