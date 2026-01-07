import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalRequest {
  final String id;
  final String susuAccountId;
  final double amount;
  final String status; // 'pending', 'approved', 'rejected', 'processing'
  final DateTime requestedAt;
  final String? adminNotes;
  final DateTime? availabilityDate;

  WithdrawalRequest({
    required this.id,
    required this.susuAccountId,
    required this.amount,
    this.status = 'pending',
    required this.requestedAt,
    this.adminNotes,
    this.availabilityDate,
  });

  factory WithdrawalRequest.fromMap(Map<String, dynamic> data, String id) {
    return WithdrawalRequest(
      id: id,
      susuAccountId: data['susuAccountId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminNotes: data['adminNotes'],
      availabilityDate: (data['availabilityDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'susuAccountId': susuAccountId,
      'amount': amount,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'adminNotes': adminNotes,
      'availabilityDate': availabilityDate != null ? Timestamp.fromDate(availabilityDate!) : null,
    }; 
  }
}
