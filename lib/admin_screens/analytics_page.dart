import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor =
        isDark
            ? const Color.fromARGB(255, 40, 40, 40)
            : const Color.fromARGB(255, 245, 245, 245);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              // Theme toggle logic if using ValueNotifier<ThemeMode>
              // themeNotifier.value = themeNotifier.value == ThemeMode.dark
              //     ? ThemeMode.light
              //     : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Overview", textColor),
            Row(
              children: [
                _infoCard("Today's Orders", "50", cardColor, textColor),
                const SizedBox(width: 16),
                _infoCard("Income", "₹5,000", cardColor, textColor),
              ],
            ),
            const SizedBox(height: 20),

            _sectionCard(
              title: "Most Ordered Items",
              cardColor: cardColor,
              textColor: textColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("• Veg Biryani"),
                  Text("• Chicken Wrap"),
                  Text("• Samosa"),
                  Text("• Idli Vada"),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _sectionCard(
              title: "Top Pick-up Point",
              cardColor: cardColor,
              textColor: textColor,
              child: const Text("• B Block"),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                _infoCard("B-Block Sales", "50", cardColor, textColor),
                const SizedBox(width: 16),
                _infoCard("Canteen Sales", "40", cardColor, textColor),
              ],
            ),

            const SizedBox(height: 20),
            _sectionCard(
              title: "Out-of-Stock Items",
              cardColor: cardColor,
              textColor: textColor,
              child: const Text("• Lemon Rice"),
            ),
          ],
        ),
      ),
    );
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
