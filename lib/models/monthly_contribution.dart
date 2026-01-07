import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyContribution {
  final String id;
  final String susuAccountId;
  final String month; // Format: "YYYY-MM" (e.g., "2024-05")
  final double amount;
  final DateTime datePaid;

  MonthlyContribution({
    required this.id,
    required this.susuAccountId,
    required this.month,
    required this.amount,
    required this.datePaid,
  });

  factory MonthlyContribution.fromMap(Map<String, dynamic> data, String id) {
    return MonthlyContribution(
      id: id,
      susuAccountId: data['susuAccountId'] ?? '',
      month: data['month'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      datePaid: (data['datePaid'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'susuAccountId': susuAccountId,
      'month': month,
      'amount': amount,
      'datePaid': Timestamp.fromDate(datePaid),
    };
  }
}
