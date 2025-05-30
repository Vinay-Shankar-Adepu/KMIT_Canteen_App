// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class AASidebar extends StatelessWidget {
//   const AASidebar({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;

//     return Drawer(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(color: Colors.orange[100]),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 const Icon(Icons.account_circle, size: 40),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         user?.displayName ?? "Admin",
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         user?.email ?? "Roll Number",
//                         style: const TextStyle(fontSize: 12),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Icon(Icons.settings),
//               ],
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.favorite),
//             title: const Text("Manage Menu"),
//             onTap: () {
//               // Navigator.of(context).pop();
//               // Navigator.pushNamed(context, '/favourites');
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.history),
//             title: const Text("Analytics"),
//             onTap: () {
//               // Navigator.of(context).pop();
//               // Navigator.pushNamed(context, '/previousOrders');
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.history),
//             title: const Text("All Orders"),
//             onTap: () {
//               // Navigator.of(context).pop();
//               // Navigator.pushNamed(context, '/previousOrders');
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.lock),
//             title: const Text("Change Password"),
//             onTap: () {
//               Navigator.of(context).pop();
//               Navigator.pushNamed(context, '/changePassword');
//             },
//           ),
//           const Divider(),
//           ListTile(
//             leading: const Icon(Icons.logout),
//             title: const Text("Log out"),
//             onTap: () async {
//               await FirebaseAuth.instance.signOut();
//               Navigator.pushReplacementNamed(context, '/loginPage');
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ASidebar extends StatelessWidget {
  const ASidebar({super.key});

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
                  leading: const Icon(Icons.inventory),
                  title: const Text("Manage Stocks"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/manageStocks');
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text("Analytics"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/analytics');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: const Text("View All Orders"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/allOrders');
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
