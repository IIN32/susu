import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firestore_service.dart';
import '../../models/monthly_contribution.dart';
import '../shared/loading_widget.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _bfController = TextEditingController();
  final _monthControllers = List.generate(12, (_) => TextEditingController());

  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  final _firestoreService = FirestoreService();

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String accountNumber = _accountNumberController.text.trim();

      // 1. Verify account exists
      var accountDoc = await _firestoreService.getSusuAccount(accountNumber);
      if (accountDoc == null) {
        throw Exception("Account Number not found.");
      }

      // 2. Calculate total of NEW contributions
      double newContributionsTotal = double.tryParse(_bfController.text) ?? 0.0;
      for (var controller in _monthControllers) {
        newContributionsTotal += double.tryParse(controller.text) ?? 0.0;
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 3. Create contribution docs
      for (int i = 0; i < _monthControllers.length; i++) {
        double amount = double.tryParse(_monthControllers[i].text) ?? 0.0;
        if (amount > 0) {
          DocumentReference contributionRef = FirebaseFirestore.instance.collection('contributions').doc();
          MonthlyContribution contribution = MonthlyContribution(
            id: contributionRef.id,
            susuAccountId: accountNumber,
            month: "$_selectedYear-${(i + 1).toString().padLeft(2, '0')}",
            amount: amount,
            datePaid: DateTime(_selectedYear, i + 1, 1),
          );
          batch.set(contributionRef, contribution.toMap());
        }
      }
      
      // Also add B/F as a contribution for the record
      double bfAmount = double.tryParse(_bfController.text) ?? 0.0;
      if (bfAmount > 0) {
        DocumentReference bfRef = FirebaseFirestore.instance.collection('contributions').doc();
        MonthlyContribution bfContribution = MonthlyContribution(
            id: bfRef.id,
            susuAccountId: accountNumber,
            month: "$_selectedYear-BF", // Special month for Brought Forward
            amount: bfAmount,
            datePaid: DateTime(_selectedYear, 1, 1),
          );
          batch.set(bfRef, bfContribution.toMap());
      }

      // 4. Update the account balance by incrementing it
      DocumentReference accountRef = FirebaseFirestore.instance.collection('susu_accounts').doc(accountNumber);
      batch.update(accountRef, {'balance': FieldValue.increment(newContributionsTotal)});

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Historical data for $_selectedYear added successfully!"), backgroundColor: Colors.green),
        );
        _formKey.currentState?.reset();
        _accountNumberController.clear();
        _bfController.clear();
        for (var c in _monthControllers) { c.clear(); }
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
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Scaffold(
      appBar: AppBar(title: const Text("Historical Data Entry")),
      body: _isLoading
          ? const LoadingWidget(message: "Saving Data...")
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(controller: _accountNumberController, decoration: const InputDecoration(labelText: "Account Number to Update", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Required" : null),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(labelText: "Select Year for these Contributions", border: OutlineInputBorder()),
                      items: List.generate(10, (i) => DateTime.now().year - i).map((year) => 
                        DropdownMenuItem(value: year, child: Text(year.toString()))
                      ).toList(),
                      onChanged: (val) => setState(() => _selectedYear = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: _bfController, decoration: const InputDecoration(labelText: "B/F Balance for this Year", border: OutlineInputBorder()), keyboardType: TextInputType.number),
                    const SizedBox(height: 24),
                    Text("$_selectedYear Contributions", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    GridView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.5, crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemCount: months.length,
                      itemBuilder: (c, i) => TextFormField(controller: _monthControllers[i], decoration: InputDecoration(labelText: months[i], border: const OutlineInputBorder()), keyboardType: TextInputType.number),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton.icon(onPressed: _submitData, icon: const Icon(Icons.save), label: const Text("Save Historical Data")),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
