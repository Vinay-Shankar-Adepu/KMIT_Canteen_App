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

  final List<Map<String, String>> pickupPoints = [
    {'label': 'Block - B', 'icon': '🏢'},
    {'label': 'Canteen', 'icon': '🍽️'},
  ];

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
            ...pickupPoints.map((point) {
              final isSelected = selectedPoint == point['label'];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected ? colorScheme.primary : colorScheme.outline,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  leading: Text(
                    point['icon'] ?? '',
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    point['label']!,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected
                              ? colorScheme.primary
                              : colorScheme.onBackground,
                    ),
                  ),
                  trailing:
                      isSelected
                          ? Icon(Icons.check_circle, color: colorScheme.primary)
                          : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    setState(() {
                      selectedPoint = point['label'];
                    });

                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => OrderReviewPage(
                                selectedPickupPoint: point['label']!,
                              ),
                        ),
                      );
                    });
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
