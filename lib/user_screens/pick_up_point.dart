import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'order_review_page.dart';

class PickupPointPage extends StatefulWidget {
  const PickupPointPage({super.key});

  @override
  State<PickupPointPage> createState() => _PickupPointPageState();
}

class _PickupPointPageState extends State<PickupPointPage> {
  String? selectedPoint;

  final List<Map<String, String>> allPickupPoints = [
    {'label': 'Block - B', 'icon': '🏢'},
    {'label': 'Canteen', 'icon': '🍽️'},
  ];

  Map<String, bool> enabledPoints = {};

  @override
  void initState() {
    super.initState();
    _loadEnabledPoints();
  }

  Future<void> _loadEnabledPoints() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('metadata')
            .doc('pickupPoints')
            .get();

    final statusMap = doc.data()?['status'] as Map<String, dynamic>? ?? {};
    setState(() {
      enabledPoints = statusMap.map((k, v) => MapEntry(k, v as bool));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("KMIT  🍴  CANTEEN"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Pick-up Point",
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...allPickupPoints.map((point) {
              final label = point['label']!;
              final isEnabled = enabledPoints[label] ?? true;
              final isSelected = selectedPoint == label;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected && isEnabled
                          ? colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected && isEnabled
                            ? colorScheme.primary
                            : colorScheme.outline,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  enabled: isEnabled,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  leading: Text(
                    point['icon'] ?? '',
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    label,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isEnabled
                              ? (isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onBackground)
                              : Colors.grey,
                    ),
                  ),
                  subtitle:
                      !isEnabled
                          ? const Text(
                            "Not Available",
                            style: TextStyle(color: Colors.grey),
                          )
                          : null,
                  trailing:
                      isEnabled
                          ? (isSelected
                              ? Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
                              )
                              : const Icon(Icons.arrow_forward_ios, size: 16))
                          : const Icon(Icons.block, color: Colors.grey),
                  onTap:
                      isEnabled
                          ? () {
                            setState(() {
                              selectedPoint = label;
                            });

                            Future.delayed(
                              const Duration(milliseconds: 300),
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => OrderReviewPage(
                                          selectedPickupPoint: label,
                                        ),
                                  ),
                                );
                              },
                            );
                          }
                          : null,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
