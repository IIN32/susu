import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../models/withdrawal_request.dart';
import '../../models/susu_account.dart';
import '../../core/utils/withdrawal_validator.dart';
import '../shared/loading_widget.dart';

class WithdrawalRequestScreen extends StatefulWidget {
  final String? initialAccountId; // Optional pre-fill
  const WithdrawalRequestScreen({super.key, this.initialAccountId});

  @override
  State<WithdrawalRequestScreen> createState() => _WithdrawalRequestScreenState();
}

class _WithdrawalRequestScreenState extends State<WithdrawalRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _accountController;
  final _amountController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _accountController = TextEditingController(text: widget.initialAccountId ?? '');
  }

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    String accountId = _accountController.text.trim();
    double amount = double.parse(_amountController.text.trim());

    try {
      SusuAccount? account = await _firestoreService.getSusuAccount(accountId);
      
      if (account == null) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account not found")));
         setState(() => _isLoading = false);
         return;
      }

      String? logicError = WithdrawalValidator.validateAmount(_amountController.text.trim(), account.balance);
      if (logicError != null) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(logicError)));
         setState(() => _isLoading = false);
         return;
      }

      WithdrawalRequest request = WithdrawalRequest(
        id: '', 
        susuAccountId: accountId,
        amount: amount,
        status: 'pending',
        requestedAt: DateTime.now(),
      );

      await _firestoreService.requestWithdrawal(request);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Submitted")));
        Navigator.pop(context);
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Withdrawal")),
      body: _isLoading
          ? const LoadingWidget(message: "Processing Request...")
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _accountController,
                      decoration: const InputDecoration(labelText: "Susu Account Number (ID)", border: OutlineInputBorder()),
                      validator: WithdrawalValidator.validateAccountId,
                      readOnly: widget.initialAccountId != null, // Make read-only if pre-filled
                      enabled: widget.initialAccountId == null,
                    ),
                    if (widget.initialAccountId != null)
                       const Padding(
                         padding: EdgeInsets.only(top: 5),
                         child: Text("Linked to your account automatically", style: TextStyle(color: Colors.grey, fontSize: 12)),
                       ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: "Amount", border: OutlineInputBorder(), prefixText: "GH¢"),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                         if (val == null || val.isEmpty) return "Required";
                         if (double.tryParse(val) == null) return "Invalid number";
                         return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitRequest, 
                        child: const Text("Submit Request")
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
