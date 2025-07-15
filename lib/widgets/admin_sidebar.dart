import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class ASidebar extends StatefulWidget {
  const ASidebar({super.key});

  @override
  State<ASidebar> createState() => _ASidebarState();
}

class _ASidebarState extends State<ASidebar> {
  bool isOnline = true;
  String? modeLabel;
  double labelOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _getCanteenStatus();
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final rollNumber = user.email?.split('@').first ?? '';
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(rollNumber)
            .get();
    return doc.data();
  }

  Future<void> _getCanteenStatus() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('canteenStatus')
            .doc('status')
            .get();
    setState(() {
      isOnline = doc.data()?['isOnline'] ?? true;
    });
  }

  Future<void> _setCanteenStatus(bool status) async {
    await FirebaseFirestore.instance
        .collection('canteenStatus')
        .doc('status')
        .set({'isOnline': status});
  }

  void _toggleTheme(BuildContext context) async {
    final isDarkMode = themeNotifier.value == ThemeMode.dark;
    final newTheme = isDarkMode ? ThemeMode.light : ThemeMode.dark;

    themeNotifier.value = newTheme;
    await saveThemePreference(newTheme == ThemeMode.dark);
    _showThemeLabel(
      context,
      newTheme == ThemeMode.dark ? "Dark Mode" : "Light Mode",
    );
  }

  void _showThemeLabel(BuildContext context, String message) {
    setState(() {
      modeLabel = message;
      labelOpacity = 1.0;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => labelOpacity = 0.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Drawer(
          child: SafeArea(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _getUserData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;
                final name = data['name'] ?? 'Admin';
                final rollNo = data['rollNo'] ?? 'Roll Number';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: isDark ? Colors.grey[900] : Colors.orange[100],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      width: double.infinity,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rollNo,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    ListTile(
                      leading: const Icon(Icons.inventory),
                      title: const Text("Manage Stocks"),
                      onTap:
                          () => Navigator.pushNamed(context, '/manageStocks'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.analytics),
                      title: const Text("Analytics"),
                      onTap: () => Navigator.pushNamed(context, '/analytics'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.list_alt),
                      title: const Text("View All Orders"),
                      onTap: () => Navigator.pushNamed(context, '/allOrders'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_pin),
                      title: const Text("Pickup Point Control"),
                      onTap:
                          () => Navigator.pushNamed(context, '/pickupControl'),
                    ),

                    ListTile(
                      leading: Icon(
                        themeNotifier.value == ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                      ),
                      title: const Text("Dark Mode"),
                      trailing: Switch(
                        value: themeNotifier.value == ThemeMode.dark,
                        onChanged: (_) => _toggleTheme(context),
                      ),
                    ),

                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text("Change Password"),
                      onTap:
                          () => Navigator.pushNamed(context, '/changePassword'),
                    ),

                    const Spacer(),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Canteen Online",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Switch(
                            value: isOnline,
                            onChanged: (val) {
                              setState(() => isOnline = val);
                              _setCanteenStatus(val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text("Log out"),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/loginPage');
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        if (modeLabel != null)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: AnimatedOpacity(
                  opacity: labelOpacity,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      modeLabel!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
