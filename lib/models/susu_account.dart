import 'package:cloud_firestore/cloud_firestore.dart';

class SusuAccount {
  final String id;
  final String name;
  final String accountNumber; // Unique ID from CSV/Excel
  final double balance;
  final double interestEarned;
  final String status; // 'active', 'suspended', 'deleted'
  final DateTime createdAt;

  SusuAccount({
    required this.id,
    required this.name,
    required this.accountNumber,
    this.balance = 0.0,
    this.interestEarned = 0.0,
    this.status = 'active',
    required this.createdAt,
  });

  factory SusuAccount.fromMap(Map<String, dynamic> data, String id) {
    // Handle migration from old 'isActive' boolean to new 'status' string
    String status = 'active';
    if (data.containsKey('status')) {
      status = data['status'];
    } else if (data.containsKey('isActive')) {
      status = data['isActive'] == true ? 'active' : 'suspended';
    }

    return SusuAccount(
      id: id,
      name: data['name'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      interestEarned: (data['interestEarned'] ?? 0.0).toDouble(),
      status: status,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'accountNumber': accountNumber,
      'balance': balance,
      'interestEarned': interestEarned,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
