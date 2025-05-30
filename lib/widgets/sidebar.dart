import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

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
