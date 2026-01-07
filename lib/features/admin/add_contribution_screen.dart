import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firestore_service.dart';
import '../../models/monthly_contribution.dart';
import '../shared/loading_widget.dart';

class AddContributionScreen extends StatefulWidget {
  const AddContributionScreen({super.key});

  @override
  State<AddContributionScreen> createState() => _AddContributionScreenState();
}

class _AddContributionScreenState extends State<AddContributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _isLoading = false;

  final _firestoreService = FirestoreService();

  void _submitContribution() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String accountNumber = _accountNumberController.text.trim();
      double amount = double.parse(_amountController.text.trim());

      // 1. Verify account exists
      var accountDoc = await _firestoreService.getSusuAccount(accountNumber);
      if (accountDoc == null) {
        throw Exception("Account Number not found.");
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 2. Add the contribution
      DocumentReference contributionRef = FirebaseFirestore.instance.collection('contributions').doc();
      MonthlyContribution contribution = MonthlyContribution(
        id: contributionRef.id,
        susuAccountId: accountNumber,
        month: "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}",
        amount: amount,
        datePaid: DateTime.now(),
      );
      batch.set(contributionRef, contribution.toMap());

      // 3. Update the account balance
      DocumentReference accountRef = FirebaseFirestore.instance.collection('susu_accounts').doc(accountNumber);
      batch.update(accountRef, {'balance': FieldValue.increment(amount)});

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contribution added successfully!"), backgroundColor: Colors.green),
        );
        _formKey.currentState?.reset();
        _accountNumberController.clear();
        _amountController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Monthly Contribution")),
      body: _isLoading
          ? const LoadingWidget(message: "Saving Contribution...")
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(labelText: "Account Number", border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: "Amount", border: OutlineInputBorder()),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text("Contribution Month"),
                      subtitle: Text("${_selectedMonth.year}-${_selectedMonth.month}"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedMonth,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          initialDatePickerMode: DatePickerMode.year, // More convenient for months
                        );
                        if (picked != null) {
                          setState(() => _selectedMonth = DateTime(picked.year, picked.month, 1));
                        }
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitContribution,
                        child: const Text("Add Contribution"),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
