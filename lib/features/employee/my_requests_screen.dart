import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firestore_service.dart';
import '../../models/withdrawal_request.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _linkedAccountId;
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
            setState(() {
              _linkedAccountId = userDoc.data()?['susuAccountId'];
            });
         }
      } catch (e) {
        // ignore
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_linkedAccountId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Requests")),
        body: const Center(child: Text("No linked account found.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Withdrawal Requests")),
      body: StreamBuilder<List<WithdrawalRequest>>(
        stream: _firestoreService.getWithdrawalsForAccount(_linkedAccountId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text("No withdrawal requests found."));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              Color statusColor = Colors.grey;
              IconData statusIcon = Icons.help_outline;

              switch (req.status) {
                case 'approved':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case 'rejected':
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  break;
                case 'processing': // Changed from 'on hold'
                  statusColor = Colors.orange;
                  statusIcon = Icons.hourglass_top_rounded;
                  break;
                case 'pending':
                  statusColor = Colors.blue;
                  statusIcon = Icons.hourglass_empty;
                  break;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("\$${req.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Chip(
                            avatar: Icon(statusIcon, color: Colors.white, size: 16),
                            label: Text(req.status.toUpperCase(), style: const TextStyle(color: Colors.white)),
                            backgroundColor: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Requested: ${req.requestedAt.toString().split('.')[0]}", style: const TextStyle(color: Colors.grey)),
                      
                      if (req.availabilityDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available, size: 16, color: Colors.indigo),
                              const SizedBox(width: 5),
                              Text("Available on: ${req.availabilityDate.toString().split(' ')[0]}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                            ],
                          ),
                        ),

                      if (req.adminNotes != null && req.adminNotes!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.comment, size: 16, color: Colors.grey),
                              const SizedBox(width: 5),
                              Expanded(child: Text(req.adminNotes!, style: const TextStyle(fontStyle: FontStyle.italic))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
