import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../shared/loading_widget.dart';
import '../../models/susu_account.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Susu1234');
  String _role = 'employee';
  bool _isLoading = false;

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    FirebaseApp? tempApp;
    try {
      // 1. Create Auth User
      FirebaseOptions options = Firebase.app().options;
      String appName = 'SecondaryApp';
      try {
         tempApp = Firebase.app(appName);
      } catch (e) {
         tempApp = await Firebase.initializeApp(name: appName, options: options);
      }
      UserCredential cred = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());
      
      if (cred.user != null) {
        final userUid = cred.user!.uid;
        final db = FirebaseFirestore.instance;
        WriteBatch batch = db.batch();

        // 2. Create and Link Susu Account
        DocumentReference susuAccountRef = db.collection('susu_accounts').doc();
        String newAccountId = susuAccountRef.id;
        SusuAccount newAccount = SusuAccount(
          id: newAccountId,
          name: _nameController.text.trim(),
          accountNumber: newAccountId,
          createdAt: DateTime.now(),
        );
        batch.set(susuAccountRef, newAccount.toMap());

        // 3. Create App User Profile
        DocumentReference userRef = db.collection('users').doc(userUid);
        batch.set(userRef, {
          'email': _emailController.text.trim(),
          'role': _role,
          'requiresPasswordChange': true, 
          'createdAt': FieldValue.serverTimestamp(),
          'susuAccountId': newAccountId,
        });

        await batch.commit();
      }
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("User & Linked Account Created!"), backgroundColor: Colors.green),
         );
         Navigator.pop(context);
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
         );
       }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New User")),
      body: _isLoading 
        ? const LoadingWidget(message: "Creating User...")
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("This creates a login AND a linked financial account.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Full Name (for Susu Account)", border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: "Email (for Login)", border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: "Initial Password", border: OutlineInputBorder()),
                      validator: (val) => val!.length < 6 ? "Min 6 chars" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: const InputDecoration(labelText: "Role", border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'employee', child: Text("Employee")),
                        DropdownMenuItem(value: 'admin', child: Text("Admin")),
                      ],
                      onChanged: (val) => setState(() => _role = val!),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _createUser,
                        icon: const Icon(Icons.person_add),
                        label: const Text("Create User & Account"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
