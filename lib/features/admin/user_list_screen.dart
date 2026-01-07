import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../models/susu_account.dart';
import '../shared/account_details_screen.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  void _showStatusDialog(BuildContext context, SusuAccount account) {
    final FirestoreService _service = FirestoreService();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Manage Status: ${account.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Current Status: ${account.status.toUpperCase()}"),
            const SizedBox(height: 20),
            if (account.status != 'active')
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text("Activate / Restore"),
                onTap: () {
                  _service.updateAccountStatus(account.id, 'active');
                  Navigator.pop(context);
                },
              ),
            if (account.status == 'active')
              ListTile(
                leading: const Icon(Icons.pause, color: Colors.orange),
                title: const Text("Suspend"),
                onTap: () {
                  _service.updateAccountStatus(account.id, 'suspended');
                  Navigator.pop(context);
                },
              ),
            if (account.status != 'deleted')
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete (Soft)"),
                onTap: () {
                  _service.updateAccountStatus(account.id, 'deleted');
                  Navigator.pop(context);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Susu Accounts")),
      body: StreamBuilder<List<SusuAccount>>(
        stream: _firestoreService.getSusuAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          
          final accounts = snapshot.data ?? [];
          
          if (accounts.isEmpty) {
            return const Center(child: Text("No accounts found."));
          }

          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              Color statusColor = Colors.green;
              if (account.status == 'suspended') statusColor = Colors.orange;
              if (account.status == 'deleted') statusColor = Colors.red;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Icon(
                      account.status == 'active' ? Icons.check : (account.status == 'suspended' ? Icons.pause : Icons.close),
                      color: statusColor,
                    ),
                  ),
                  title: Text(account.name, style: TextStyle(
                    decoration: account.status == 'deleted' ? TextDecoration.lineThrough : null,
                    color: account.status == 'deleted' ? Colors.grey : Colors.black,
                    fontWeight: FontWeight.bold
                  )),
                  subtitle: Text("Status: ${account.status.toUpperCase()}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("GH¢${account.balance.toStringAsFixed(2)}"),
                      IconButton(
                        icon: const Icon(Icons.edit_attributes),
                        onPressed: () => _showStatusDialog(context, account),
                      )
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AccountDetailsScreen(account: account, isAdminView: true)), // Set Admin View
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
