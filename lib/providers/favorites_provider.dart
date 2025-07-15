import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteItemIds = {};
  bool _initialized = false;

  Set<String> get favorites => _favoriteItemIds;
  bool get isInitialized => _initialized;

  FavoritesProvider() {
    _init();
  }

  void _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final rollNo = user.email!.split('@').first; // use roll number as doc ID

    FirebaseFirestore.instance
        .collection('users')
        .doc(rollNo)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final favRefs =
                (snapshot.data()?['favorites'] as List<dynamic>? ?? []);

            _favoriteItemIds
              ..clear()
              ..addAll(
                favRefs.whereType<DocumentReference>().map((ref) => ref.id),
              );

            _initialized = true;
            notifyListeners();
          }
        });
  }

  bool isFavorite(String itemId) => _favoriteItemIds.contains(itemId);

  Future<void> toggleFavorite(String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final rollNo = user.email!.split('@').first;
    final userRef = FirebaseFirestore.instance.collection('users').doc(rollNo);
    final itemRef = FirebaseFirestore.instance
        .collection('menuItems')
        .doc(itemId);

    final isFav = _favoriteItemIds.contains(itemId);

    if (isFav) {
      await userRef.update({
        'favorites': FieldValue.arrayRemove([itemRef]),
      });
    } else {
      await userRef.update({
        'favorites': FieldValue.arrayUnion([itemRef]),
      });
    }
  }
}
