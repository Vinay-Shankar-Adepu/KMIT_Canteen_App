import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageStocksPage extends StatelessWidget {
  const ManageStocksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Stocks'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menuItems').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final doc = items[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading:
                      data['imageUrl'] != null &&
                              data['imageUrl'].toString().isNotEmpty
                          ? Image.network(
                            data['imageUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderImage(),
                          )
                          : _placeholderImage(),
                  title: Text(data['name'] ?? 'Unnamed'),
                  subtitle: Text(data['description'] ?? 'No description'),
                  trailing: Switch(
                    value: data['availability'] ?? true,
                    onChanged: (value) async {
                      await FirebaseFirestore.instance
                          .collection('menuItems')
                          .doc(doc.id)
                          .update({'availability': value});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported),
    );
  }
}
