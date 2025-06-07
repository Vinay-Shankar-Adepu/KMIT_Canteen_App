import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CanteenStatusProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  CanteenStatusProvider() {
    _initialize();
  }

  void _initialize() {
    _firestore.collection('canteenStatus').doc('status').snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data.containsKey('isOnline')) {
          _isOnline = data['isOnline'] == true;
          notifyListeners();
        }
      }
    });
  }

  // Optional: For admin toggle
  Future<void> setCanteenStatus(bool online) async {
    await _firestore.collection('canteenStatus').doc('status').set({
      'isOnline': online,
    }, SetOptions(merge: true));
  }
}
