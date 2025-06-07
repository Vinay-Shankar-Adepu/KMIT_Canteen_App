import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .where(
                  'orderDate',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(
                    DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    ),
                  ),
                )
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ordersSnapshot = snapshot.data!;
          int todayOrders = ordersSnapshot.docs.length;
          double totalIncome = 0.0;
          Map<String, int> pickupSales = {'Block - B': 0, 'Canteen': 0};

          for (var order in ordersSnapshot.docs) {
            final data = order.data() as Map<String, dynamic>;
            totalIncome += (data['totalPrice'] ?? 0).toDouble();

            String pickup = data['pickupPoint'] ?? '';
            if (pickupSales.containsKey(pickup)) {
              pickupSales[pickup] = pickupSales[pickup]! + 1;
            }
          }

          return FutureBuilder<Map<String, int>>(
            future: _getTopItems(ordersSnapshot.docs),
            builder: (context, itemSnapshot) {
              if (!itemSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final sortedItems =
                  itemSnapshot.data!.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
              final topItems = sortedItems.take(4).map((e) => e.key).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Overview", textColor),
                    Row(
                      children: [
                        _infoCard(
                          "Today's Orders",
                          "$todayOrders",
                          cardColor,
                          textColor,
                        ),
                        const SizedBox(width: 16),
                        _infoCard(
                          "Income",
                          "₹${totalIncome.toInt()}",
                          cardColor,
                          textColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sectionCard(
                      title: "Most Ordered Items",
                      cardColor: cardColor,
                      textColor: textColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            topItems.map((item) => Text("• $item")).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sectionCard(
                      title: "Top Pick-up Point",
                      cardColor: cardColor,
                      textColor: textColor,
                      child: Text(
                        pickupSales.entries
                            .reduce((a, b) => a.value > b.value ? a : b)
                            .key,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _infoCard(
                          "B-Block Sales",
                          "${pickupSales['Block - B']}",
                          cardColor,
                          textColor,
                        ),
                        const SizedBox(width: 16),
                        _infoCard(
                          "Canteen Sales",
                          "${pickupSales['Canteen']}",
                          cardColor,
                          textColor,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, int>> _getTopItems(
    List<QueryDocumentSnapshot> orders,
  ) async {
    Map<String, int> itemCounts = {};
    for (var order in orders) {
      final orderItemsSnap =
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(order.id)
              .collection('orderItems')
              .get();

      for (var item in orderItemsSnap.docs) {
        final itemData = item.data() as Map<String, dynamic>;
        final ref = itemData['itemId'] as DocumentReference;
        final quantity = itemData['quantity'] ?? 0;

        final itemDoc = await ref.get();
        if (!itemDoc.exists) continue;

        final name = (itemDoc.data()! as Map<String, dynamic>)['name'];
        if (name != null) {
          itemCounts[name] = (itemCounts[name] ?? 0) + (quantity as int);
        }
      }
    }
    return itemCounts;
  }

  Widget _infoCard(String title, String value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          DefaultTextStyle(
            style: TextStyle(color: textColor, fontSize: 14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
