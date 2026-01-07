import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../models/susu_account.dart';
import '../../routes/app_routes.dart';
import '../shared/account_details_screen.dart';
import 'withdrawal_request_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final AuthService _auth = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  String? _linkedAccountId;
  String? _accountStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLinkedAccount();
  }

  void _fetchLinkedAccount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
         var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
         if (userDoc.exists) {
            String? linkedId = userDoc.data()?['susuAccountId'];
            if (linkedId != null) {
               SusuAccount? account = await _firestoreService.getSusuAccount(linkedId);
               if (account != null) {
                 setState(() {
                   _linkedAccountId = linkedId;
                   _accountStatus = account.status;
                 });
               }
            }
         }
      } catch (e) {
        // ignore
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _handleViewHistory() async {
    if (_linkedAccountId != null) {
      _fetchAndNavigate(_linkedAccountId!);
    } else {
      _showAccountSearchDialog();
    }
  }
  
  void _handleRequestWithdrawal() {
    if (_linkedAccountId != null) {
      if (_accountStatus != 'active') {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Account is ${_accountStatus?.toUpperCase()}. Withdrawal restricted."), backgroundColor: Colors.red),
         );
         return;
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WithdrawalRequestScreen(initialAccountId: _linkedAccountId),
        ),
      );
    } else {
      Navigator.pushNamed(context, AppRoutes.withdrawalRequest);
    }
  }

  void _showAccountSearchDialog() {
    final TextEditingController _searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("View Account History"),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(labelText: "Enter Account Number"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => _fetchAndNavigate(_searchController.text.trim()),
            child: const Text("Search"),
          ),
        ],
      ),
    );
  }

  void _fetchAndNavigate(String accountId) async {
    if (accountId.isEmpty) return;
    
    if (_linkedAccountId == null) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Searching...")),
    );

    try {
      SusuAccount? account = await _firestoreService.getSusuAccount(accountId);
      
      if (mounted) {
        if (account != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AccountDetailsScreen(account: account),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account not found.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_linkedAccountId != null)
                  // Status Banner

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _EmployeeMenuCard(
                        icon: Icons.money_off,
                        title: "Request Withdrawal",
                        color: _accountStatus == 'active' ? Colors.redAccent : Colors.grey,
                        onTap: _handleRequestWithdrawal,
                      ),
                      _EmployeeMenuCard(
                        icon: Icons.history,
                        title: "Track Requests", // New Card
                        color: Colors.amber,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.myRequests);
                        },
                      ),
                      _EmployeeMenuCard(
                        icon: Icons.receipt_long,
                        title: "My History",
                        color: Colors.blue,
                        onTap: _handleViewHistory,
                      ),
                       _EmployeeMenuCard(
                        icon: Icons.account_circle,
                        title: "My Profile",
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.settings);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _EmployeeMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _EmployeeMenuCard({
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
