import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_service.dart';
import '../../routes/app_routes.dart';
import '../shared/loading_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final AuthService _auth = AuthService();
  bool _isChangingPassword = false;

  void _showChangePasswordDialog() {
    final _passKey = GlobalKey<FormState>();
    final _oldPassController = TextEditingController();
    final _newPassController = TextEditingController();
    final _confirmPassController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Form(
          key: _passKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _oldPassController,
                decoration: const InputDecoration(labelText: "Current Password"),
                obscureText: true,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _newPassController,
                decoration: const InputDecoration(labelText: "New Password (min 6 chars)"),
                obscureText: true,
                validator: (val) => val!.length < 6 ? "Too short" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmPassController,
                decoration: const InputDecoration(labelText: "Confirm New Password"),
                obscureText: true,
                validator: (val) => val != _newPassController.text ? "Mismatch" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_passKey.currentState!.validate()) {
                Navigator.pop(context); // Close dialog
                _performPasswordChange(_oldPassController.text, _newPassController.text);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _performPasswordChange(String oldPass, String newPass) async {
    setState(() => _isChangingPassword = true);
    
    try {
      if (user != null && user!.email != null) {
        // 1. Re-authenticate
        AuthCredential credential = EmailAuthProvider.credential(
          email: user!.email!, 
          password: oldPass
        );
        await user!.reauthenticateWithCredential(credential);

        // 2. Update Password
        await user!.updatePassword(newPass);

        // 3. Update Firestore Flag
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'requiresPasswordChange': false
        });

        // 4. Navigate to correct dashboard
        String? role = await _auth.getUserRole(user!.uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password updated! Redirecting..."), backgroundColor: Colors.green),
          );
          
          // Delay briefly to show success
          await Future.delayed(const Duration(seconds: 1));
          
          if (mounted) {
            if (role == 'admin') {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.adminDashboard, (route) => false);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.employeeDashboard, (route) => false);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: _isChangingPassword
        ? const LoadingWidget(message: "Updating Password...")
        : ListView(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(user?.email?.split('@')[0] ?? "User"),
                accountEmail: Text(user?.email ?? "No Email"),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.grey),
                ),
                decoration: const BoxDecoration(color: Colors.deepPurple),
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text("Change Password"),
                subtitle: const Text("Update your login password"),
                onTap: _showChangePasswordDialog,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text("About"),
                subtitle: const Text("Susu App v1.0.0"),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout", style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await _auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login, 
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
    );
  }
}
