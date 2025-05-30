import 'package:hive/hive.dart';

part 'cart_item.g.dart';

@HiveType(typeId: 0)
class CartItem extends HiveObject {
  @HiveField(0)
  final String itemId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double price;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  final String? imageUrl;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final String? category;

  CartItem({
    required this.itemId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.imageUrl,
    this.description,
    this.category,
  });

  CartItem copyWith({
    String? itemId,
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
    String? description,
    String? category,
  }) {
    return CartItem(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }

  // Useful for Firestore / Debugging
  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'description': description,
      'category': category,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      itemId: map['itemId'],
      name: map['name'],
      price: map['price'],
      quantity: map['quantity'] ?? 1,
      imageUrl: map['imageUrl'],
      description: map['description'],
      category: map['category'],
    );
  }

  @override
  String toString() {
    return 'CartItem(name: $name, quantity: $quantity, price: $price)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId;

  @override
  int get hashCode => itemId.hashCode;
}
