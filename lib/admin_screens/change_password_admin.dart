import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  bool showCurrent = false;
  bool showNew = false;
  bool showConfirm = false;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> handleChangePassword() async {
    final current = currentPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showMessage("All fields are required");
      return;
    }

    if (newPass != confirm) {
      _showMessage("New passwords do not match");
      return;
    }

    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*]).{8,}$',
    );
    if (!passwordRegex.hasMatch(newPass)) {
      _showMessage("Password must meet all criteria listed below");
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = _auth.currentUser;
      final email = user?.email;
      if (user == null || email == null) {
        _showMessage("User not logged in");
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: current,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPass);

      _showMessage("Password updated successfully", success: true);
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showMessage("Current password is incorrect");
      } else {
        _showMessage("Error: ${e.message}");
      }
    } catch (_) {
      _showMessage("Something went wrong");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KMIT CANTEEN"),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Change Password",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            const Text("Current Password"),
            const SizedBox(height: 5),
            TextField(
              controller: currentPasswordController,
              obscureText: !showCurrent,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Enter current password",
                suffixIcon: IconButton(
                  icon: Icon(
                    showCurrent ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => showCurrent = !showCurrent),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text("New Password"),
            const SizedBox(height: 5),
            TextField(
              controller: newPasswordController,
              obscureText: !showNew,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Enter new password",
                suffixIcon: IconButton(
                  icon: Icon(showNew ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => showNew = !showNew),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Confirm New Password"),
            const SizedBox(height: 5),
            TextField(
              controller: confirmPasswordController,
              obscureText: !showConfirm,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Re-enter new password",
                suffixIcon: IconButton(
                  icon: Icon(
                    showConfirm ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => showConfirm = !showConfirm),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "• Must contain at least 8 characters",
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  Text(
                    "• Must include a number (0-9)",
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  Text(
                    "• Must include a lowercase letter (a-z)",
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  Text(
                    "• Must include an uppercase letter (A-Z)",
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  Text(
                    "• Must include a special character (!@#\$%^&*)",
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: isLoading ? null : handleChangePassword,
                child:
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Proceed"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
