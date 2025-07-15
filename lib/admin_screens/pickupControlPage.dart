import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PickupControlPage extends StatefulWidget {
  const PickupControlPage({super.key});

  @override
  State<PickupControlPage> createState() => _PickupControlPageState();
}

class _PickupControlPageState extends State<PickupControlPage> {
  Map<String, bool> pickupStatus = {'Block - B': true, 'Canteen': true};

  @override
  void initState() {
    super.initState();
    _loadPickupStatus();
  }

  Future<void> _loadPickupStatus() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('metadata')
            .doc('pickupPoints')
            .get();

    final data = doc.data();
    if (data != null) {
      setState(() {
        pickupStatus = Map<String, bool>.from(data['status'] ?? {});
      });
    }
  }

  Future<void> _updateStatus(String point, bool isEnabled) async {
    setState(() => pickupStatus[point] = isEnabled);

    await FirebaseFirestore.instance
        .collection('metadata')
        .doc('pickupPoints')
        .set({'status': pickupStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pickup Point Control")),
      body: ListView(
        children:
            pickupStatus.entries.map((entry) {
              return SwitchListTile(
                title: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: entry.value,
                onChanged: (val) => _updateStatus(entry.key, val),
              );
            }).toList(),
      ),
    );
  }
}
