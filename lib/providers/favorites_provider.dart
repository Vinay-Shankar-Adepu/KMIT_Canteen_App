import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteItemIds = {};
  bool _initialized = false;

  Set<String> get favorites => _favoriteItemIds;

  FavoritesProvider() {
    _init();
  }

  void _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
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
}
