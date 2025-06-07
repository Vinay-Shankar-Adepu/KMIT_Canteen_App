import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin_screens/admin_dashboard.dart';
import '../user_screens/home_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 100), () async {
      await _checkAndRedirectIfLoggedIn();
    });
  }

  Future<void> _checkAndRedirectIfLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final rollNo = user.email!.split('@').first;
      debugPrint('🔁 Session detected for $rollNo, checking role...');
      final isAdmin = await _checkIfAdmin(rollNo);
      _redirectUser(isAdmin);
    }
  }

  Future<bool> _checkIfAdmin(String rollNo) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(rollNo)
              .get();

      if (!snapshot.exists) {
        debugPrint('❌ No Firestore document found for $rollNo');
        return false;
      }

      final isAdmin = snapshot.data()?['isAdmin'] ?? false;
      debugPrint('✅ $rollNo → isAdmin: $isAdmin');
      return isAdmin;
    } catch (e, stack) {
      debugPrint('🔥 Error checking isAdmin: $e');
      debugPrint('🪵 Stacktrace:\n$stack');
      return false;
    }
  }

  void _redirectUser(bool isAdmin) {
    debugPrint(
      '➡️ Navigating to: ${isAdmin ? "AdminDashboard" : "HomeScreen"}',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isAdmin ? const AdminDashboard() : const HomeScreen(),
        ),
      );
    });
  }

  Future<void> _login() async {
    final rollNo = _rollNoController.text.trim();
    final email = '$rollNo@kmit.in';
    final password = _passwordController.text.trim();

    if (rollNo.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both roll number and password"),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ Login successful for $rollNo');

      final isAdmin = await _checkIfAdmin(rollNo);
      _redirectUser(isAdmin);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Failed: ${e.message ?? 'Unknown error'}'),
        ),
      );
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
    } catch (e, stack) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred')),
      );
      debugPrint('❌ Unexpected login error: $e');
      debugPrint('🪵 Stacktrace:\n$stack');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'KMIT Canteen',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _rollNoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Roll Number',
                      prefixIcon: Icon(Icons.person, color: Colors.white),
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white,
                        ),
                        onPressed:
                            () => setState(() => _obscureText = !_obscureText),
                      ),
                      labelStyle: const TextStyle(color: Colors.white),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _loading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
