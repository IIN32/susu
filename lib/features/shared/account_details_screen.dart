import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import '../../core/services/firestore_service.dart';
import '../../models/susu_account.dart';
import '../../models/monthly_contribution.dart';
import '../../models/withdrawal_request.dart';

class AccountDetailsScreen extends StatelessWidget {
  final SusuAccount account;
  final bool isAdminView;

  const AccountDetailsScreen({super.key, required this.account, this.isAdminView = false});

  Future<void> _exportToCsv(BuildContext context, List<MonthlyContribution> contributions, List<WithdrawalRequest> withdrawals) async {
    List<List<dynamic>> rows = [];
    rows.add(["Date", "Type", "Amount", "Status/Month"]);

    for (var c in contributions) {
      rows.add([c.datePaid.toString().split(' ')[0], "Contribution", c.amount, c.month]);
    }
    for (var w in withdrawals) {
      rows.add([w.requestedAt.toString().split(' ')[0], "Withdrawal", -w.amount, w.status]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final Uint8List fileData = Uint8List.fromList(csv.codeUnits);

    final XFile file = XFile.fromData(fileData, name: '${account.accountNumber}_report.csv', mimeType: 'text/csv');
    await Share.shareXFiles([file], subject: 'Susu Report for ${account.name}');
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(account.name),
          actions: [
            if (isAdminView)
              IconButton(
                icon: const Icon(Icons.share), // The Export button
                tooltip: 'Export to CSV',
                onPressed: () async {
                  var contributions = await firestoreService.getContributions(account.id).first;
                  var withdrawals = await firestoreService.getWithdrawalsForAccount(account.id).first;
                  if (context.mounted) _exportToCsv(context, contributions, withdrawals);
                },
              ),
          ],
          bottom: const TabBar(tabs: [Tab(text: "Contributions"), Tab(text: "Withdrawals")]),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.deepPurple.shade50,
              width: double.infinity,
              child: Column(
                children: [
                  Text("Current Balance", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 5),
                  Text(
                    "GH¢${account.balance.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text("Account #: ${account.accountNumber}", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ContributionsList(accountId: account.accountNumber, isAdmin: isAdminView, account: account),
                  _WithdrawalsList(accountId: account.accountNumber),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributionsList extends StatelessWidget {
  final String accountId;
  final bool isAdmin;
  final SusuAccount account;
  const _ContributionsList({required this.accountId, required this.isAdmin, required this.account});

  void _showEditDialog(BuildContext context, MonthlyContribution c) {
    final controller = TextEditingController(text: c.amount.toString());
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text("Edit for ${c.month}"),
      content: TextFormField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "New Amount")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async {
          double newAmount = double.parse(controller.text);
          await FirestoreService().editContribution(c.id, accountId, c.amount, newAmount);
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text("Save")),
      ],
    ));
  }

  void _confirmDelete(BuildContext context, MonthlyContribution c) {
     showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Confirm Delete"),
      content: Text("Are you sure you want to delete the contribution of GH¢${c.amount} for ${c.month}?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () async {
          await FirestoreService().deleteContribution(c.id, accountId, c.amount);
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text("Delete")),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MonthlyContribution>>(
      stream: FirestoreService().getContributions(accountId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final contributions = snapshot.data ?? [];
        if (contributions.isEmpty) return const Center(child: Text("No contributions."));

        final groupedByYear = groupBy(contributions, (c) => c.month.split('-')[0]);
        final sortedYears = groupedByYear.keys.sorted((a, b) => b.compareTo(a));

        return ListView.builder(
          itemCount: sortedYears.length,
          itemBuilder: (context, index) {
            final year = sortedYears[index];
            final yearContributions = groupedByYear[year]!;
            return ExpansionTile(
              title: Text(year, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              initiallyExpanded: true,
              children: yearContributions.map((c) => ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                title: Text(c.month),
                subtitle: isAdmin ? Text("Entered: ${c.datePaid.toString().split(' ')[0]}") : null,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text("+GH¢${c.amount.toStringAsFixed(2)}"),
                  if (isAdmin) ...[
                    IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showEditDialog(context, c)),
                    IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _confirmDelete(context, c)),
                  ]
                ]),
              )).toList(),
            );
          },
        );
      },
    );
  }
}

class _WithdrawalsList extends StatelessWidget {
  final String accountId;
  const _WithdrawalsList({required this.accountId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WithdrawalRequest>>(
      stream: FirestoreService().getWithdrawalsForAccount(accountId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No withdrawal history."));
        }
        
        final withdrawals = snapshot.data!;
        final groupedByYear = groupBy(withdrawals, (w) => w.requestedAt.year);
        final sortedYears = groupedByYear.keys.sorted((a, b) => b.compareTo(a));

        return ListView.builder(
          itemCount: sortedYears.length,
          itemBuilder: (context, index) {
            final year = sortedYears[index];
            final yearWithdrawals = groupedByYear[year]!;

            return ExpansionTile(
              title: Text(year.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              initiallyExpanded: true,
              children: yearWithdrawals.map((w) {
                Color statusColor;
                switch (w.status) {
                  case 'approved': statusColor = Colors.green; break;
                  case 'rejected': statusColor = Colors.red; break;
                  case 'processing': statusColor = Colors.orange; break;
                  default: statusColor = Colors.blue;
                }
                return ListTile(
                  leading: Icon(Icons.remove_circle_outline, color: statusColor),
                  title: Text("GH¢${w.amount.toStringAsFixed(2)}"),
                  subtitle: Text("Requested: ${w.requestedAt.toString().split(' ')[0]}"),
                  trailing: Chip(
                    label: Text(w.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                    backgroundColor: statusColor,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
