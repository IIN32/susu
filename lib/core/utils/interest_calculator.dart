import '../constants/app_constants.dart';

class InterestCalculator {
  /// Calculates interest based on balance.
  /// Rate is defined in AppConstants (0.0016 for 0.16%)
  static double calculateMonthlyInterest(double balance) {
    if (balance <= 0) return 0.0;
    // Round to 2 decimal places to match currency
    double rawInterest = balance * AppConstants.monthlyInterestRate; 
    return double.parse(rawInterest.toStringAsFixed(2));
  }
}
