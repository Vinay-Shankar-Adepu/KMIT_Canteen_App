import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageStocksPage extends StatefulWidget {
  const ManageStocksPage({super.key});

  @override
  State<ManageStocksPage> createState() => _ManageStocksPageState();
}

class _ManageStocksPageState extends State<ManageStocksPage> {
  String searchQuery = '';
  String filter = 'All'; // All, Available, Unavailable

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Stocks'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search item...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged:
                  (val) =>
                      setState(() => searchQuery = val.trim().toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                FilterChip(
                  label: const Text("Available"),
                  selected: filter == 'Available',
                  onSelected: (_) => setState(() => filter = 'Available'),
                  selectedColor: Colors.green.shade200,
                ),
                const SizedBox(width: 10),
                FilterChip(
                  label: const Text("Unavailable"),
                  selected: filter == 'Unavailable',
                  onSelected: (_) => setState(() => filter = 'Unavailable'),
                  selectedColor: Colors.red.shade200,
                ),
                const SizedBox(width: 10),
                FilterChip(
                  label: const Text("All"),
                  selected: filter == 'All',
                  onSelected: (_) => setState(() => filter = 'All'),
                  selectedColor: Colors.blue.shade200,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('menuItems')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name']?.toString().toLowerCase() ?? '';
                      final isAvailable = data['availability'] ?? true;

                      final matchesSearch = name.contains(searchQuery);
                      final matchesFilter =
                          filter == 'All' ||
                          (filter == 'Available' && isAvailable) ||
                          (filter == 'Unavailable' && !isAvailable);

                      return matchesSearch && matchesFilter;
                    }).toList();

                if (items.isEmpty) {
                  return const Center(child: Text("No items found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              data['imageUrl'] != null &&
                                      data['imageUrl'].toString().isNotEmpty
                                  ? Image.network(
                                    data['imageUrl'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => _placeholderImage(),
                                  )
                                  : _placeholderImage(),
                        ),
                        title: Text(
                          data['name'] ?? 'Unnamed',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          data['description'] ?? 'No description',
                          style: TextStyle(color: textColor.withOpacity(0.7)),
                        ),
                        trailing: Switch(
                          value: data['availability'] ?? true,
                          onChanged: (value) async {
                            await FirebaseFirestore.instance
                                .collection('menuItems')
                                .doc(doc.id)
                                .update({'availability': value});
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[400],
      child: const Icon(Icons.image_not_supported, color: Colors.black45),
    );
  }
}
