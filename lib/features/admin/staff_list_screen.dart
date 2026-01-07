import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {

  void _showEditDialog(BuildContext context, Map<String, dynamic> user, String docId) {
    final nameController = TextEditingController(text: user['name'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    String selectedRole = user['role'] ?? 'employee';
    bool _isProcessing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Edit Staff Member"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
                const SizedBox(height: 16),
                TextFormField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: "Role"),
                  items: const [
                    DropdownMenuItem(value: 'employee', child: Text("Employee")),
                    DropdownMenuItem(value: 'admin', child: Text("Admin")),
                  ],
                  onChanged: (val) => setState(() => selectedRole = val!),
                ),
                const SizedBox(height: 24),
                if (_isProcessing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                setState(() => _isProcessing = true);
                try {
                  await FirebaseFirestore.instance.collection('users').doc(docId).update({
                    'name': nameController.text,
                    'role': selectedRole,
                  });

                  if (emailController.text != user['email']) {
                    await _callFunction('updateUserEmail', {'uid': docId, 'email': emailController.text});
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User details updated!")));
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    showDialog(
                      context: context, 
                      builder: (ctx) => AlertDialog(
                        title: const Text("Error"),
                        content: Text(e.toString()),
                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
                      )
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callFunction(String functionName, Map<String, dynamic> params) async {
    HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable(functionName);
    await callable.call(params);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Staff")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No staff accounts found."));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final user = userDoc.data() as Map<String, dynamic>;
              final String email = user['email'] ?? 'No Email';
              final String name = user['name'] ?? 'No Name';
              final String role = user['role'] ?? 'employee';
              final String? linkedId = user['susuAccountId'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email),
                      if (linkedId != null && linkedId.isNotEmpty)
                        SelectableText(
                          "Acct ID: $linkedId", 
                          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (linkedId != null && linkedId.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: linkedId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Account ID copied to clipboard")),
                            );
                          },
                        ),
                      const Icon(Icons.edit, color: Colors.grey),
                    ],
                  ),
                  onTap: () => _showEditDialog(context, user, userDoc.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
