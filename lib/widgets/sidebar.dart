import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // to access themeNotifier and saveThemePreference

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String? modeLabel;
  double labelOpacity = 0.0;

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final email = user.email ?? '';
    final rollNumber = email.split('@').first;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(rollNumber)
            .get();
    return doc.data();
  }

  void _toggleTheme(BuildContext context) async {
    final isCurrentlyDark = themeNotifier.value == ThemeMode.dark;
    final newTheme = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;

    themeNotifier.value = newTheme;
    await saveThemePreference(newTheme == ThemeMode.dark);
    _showThemeLabel(
      context,
      newTheme == ThemeMode.dark ? "Dark Mode" : "Light Mode",
    );
  }

  void _showThemeLabel(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Center(
            child: AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = snapshot.data;
            final name = userData?['name'] ?? 'Student';
            final rollNo = userData?['rollNo'] ?? 'Roll Number';

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
                  leading: Icon(
                    themeNotifier.value == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: const Text(
                    "Dark Mode",
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                  trailing: Switch(
                    value: themeNotifier.value == ThemeMode.dark,
                    onChanged: (_) => _toggleTheme(context),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text("Favourites"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/favourites');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text("Previous Orders"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/previousOrders');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text("Change Password"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/changePassword');
                  },
                ),
                const Spacer(),
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
    );
  }
}
