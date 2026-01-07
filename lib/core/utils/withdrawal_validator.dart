class WithdrawalValidator {
  
  static String? validateAmount(String? value, double currentBalance) {
    if (value == null || value.isEmpty) {
      return "Amount is required";
    }
    
    final amount = double.tryParse(value);
    if (amount == null) {
      return "Invalid amount format";
    }
    
    if (amount <= 0) {
      return "Amount must be positive";
    }
    
    if (amount > currentBalance) {
      return "Insufficient funds (Balance: \$${currentBalance.toStringAsFixed(2)})";
    }
    
    return null; // Valid
  }

  static String? validateAccountId(String? value) {
     if (value == null || value.isEmpty) {
      return "Account Number is required";
    }
    return null;
  }
}
