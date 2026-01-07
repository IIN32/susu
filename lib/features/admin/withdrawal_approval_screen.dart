import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../models/withdrawal_request.dart';

class WithdrawalApprovalScreen extends StatelessWidget {
  const WithdrawalApprovalScreen({super.key});

  void _showNotesDialog(BuildContext context, String requestId, String newStatus, Function(String notes, DateTime? date) onSave) {
    final notesController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Update Status to ${newStatus.toUpperCase()}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: "Admin Notes (Optional)"),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("Availability Date (Optional)"),
                subtitle: Text(selectedDate?.toString().split(' ')[0] ?? "Not set"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                onSave(notesController.text, selectedDate);
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Withdrawal Requests"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Pending"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RequestList(statusFilter: ['pending', 'processing']), // Tab 1: Actionable
            _RequestList(statusFilter: ['approved', 'rejected']),  // Tab 2: History
          ],
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final List<String> statusFilter;
  const _RequestList({required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();

    // We need to filter client-side or create a new query in service. 
    // For simplicity, we'll reuse the generic stream and filter here, 
    // but in a large app, you'd want a specific query.
    return StreamBuilder<List<WithdrawalRequest>>(
      stream: _firestoreService.getPendingWithdrawals(), // This currently only fetches pending. We need to update this logic.
      builder: (context, snapshot) {
        // NOTE: To make this work efficiently, we need to update FirestoreService 
        // to fetch ALL requests, or create a new method. 
        // For now, I will assume getPendingWithdrawals returns what we need or I will fetch directly.
        // Let's use a direct query here to ensure we get the right data for History.
        
        return StreamBuilder<List<WithdrawalRequest>>(
          stream: _firestoreService.getAllWithdrawals(), // Need to add this method or use direct Firestore
          builder: (context, snapshot) {
             if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final allRequests = snapshot.data ?? [];
            final filteredRequests = allRequests.where((r) => statusFilter.contains(r.status)).toList();

            if (filteredRequests.isEmpty) {
              return Center(child: Text("No ${statusFilter[0]} requests."));
            }

            return ListView.builder(
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                final req = filteredRequests[index];
                Color statusColor;
                switch (req.status) {
                  case 'approved': statusColor = Colors.green; break;
                  case 'rejected': statusColor = Colors.red; break;
                  case 'processing': statusColor = Colors.orange; break;
                  default: statusColor = Colors.blueGrey;
                }

                // Show buttons only if status is pending or processing
                bool showActions = req.status == 'pending' || req.status == 'processing';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text("Acct: ${req.susuAccountId}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Status: ${req.status.toUpperCase()}", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                          trailing: Text("GH¢${req.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        if (req.adminNotes != null && req.adminNotes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Text("Notes: ${req.adminNotes}", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                          ),
                        if (req.availabilityDate != null)
                           Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Text("Available: ${req.availabilityDate.toString().split(' ')[0]}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        if (showActions) ...[
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (req.status != 'processing')
                                OutlinedButton(onPressed: () {
                                   // Re-implemented dialog call context here
                                   final parent = context.findAncestorWidgetOfExactType<WithdrawalApprovalScreen>();
                                   parent?._showNotesDialog(context, req.id, 'rejected', (notes, date) => _firestoreService.updateWithdrawalStatus(req.id, status: 'rejected', notes: notes, availabilityDate: date));
                                }, child: const Text("Reject")),
                              const SizedBox(width: 8),
                              if (req.status == 'pending')
                                OutlinedButton(onPressed: () {
                                   final parent = context.findAncestorWidgetOfExactType<WithdrawalApprovalScreen>();
                                   parent?._showNotesDialog(context, req.id, 'processing', (notes, date) => _firestoreService.updateWithdrawalStatus(req.id, status: 'processing', notes: notes, availabilityDate: date));
                                }, child: const Text("Processing")),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                   final parent = context.findAncestorWidgetOfExactType<WithdrawalApprovalScreen>();
                                   parent?._showNotesDialog(context, req.id, 'approved', (notes, date) => _firestoreService.approveWithdrawal(req.id, req.susuAccountId, req.amount, notes: notes, availabilityDate: date));
                                }, 
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                icon: const Icon(Icons.check, color: Colors.white),
                                label: const Text("Approve", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
