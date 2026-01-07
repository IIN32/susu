import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../routes/app_routes.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _auth = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isProcessing = false;

  void _confirmApplyInterest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Apply Monthly Interest"),
        content: const Text(
          "This will calculate 0.16% interest for ALL active accounts and add it to their balance.\n\nAre you sure you want to proceed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyInterest();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text("Apply Interest", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _applyInterest() async {
    setState(() => _isProcessing = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Applying interest... Please wait.")),
    );

    try {
      int updatedCount = await _firestoreService.applyMonthlyInterest();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Success! Interest applied to $updatedCount accounts."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _AdminMenuCard(
                  icon: Icons.person_add,
                  title: "Create User",
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.createUser);
                  },
                ),
                _AdminMenuCard(
                  icon: Icons.add_card,
                  title: "Add Contribution",
                  color: Colors.lightGreen,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.addContribution);
                  },
                ),
                _AdminMenuCard(
                  icon: Icons.history,
                  title: "Historical Entry",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.manualEntry);
                  },
                ),
                _AdminMenuCard(
                  icon: Icons.people,
                  title: "Manage Susu Accounts",
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.userList);
                  },
                ),
                _AdminMenuCard(
                  icon: Icons.badge,
                  title: "Manage Staff",
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.staffList);
                  },
                ),
                _AdminMenuCard(
                  icon: Icons.monetization_on,
                  title: "Withdrawals",
                  color: Colors.green,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.withdrawalApproval);
                  },
                ),
                 _AdminMenuCard(
                  icon: Icons.trending_up,
                  title: "Apply Interest",
                  color: Colors.purple,
                  onTap: _confirmApplyInterest,
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
