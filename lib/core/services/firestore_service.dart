import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/susu_account.dart';
import '../../models/monthly_contribution.dart';
import '../../models/withdrawal_request.dart';
import '../utils/interest_calculator.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Susu Accounts ---

  Future<void> saveSusuAccount(SusuAccount account) async {
    await _db.collection('susu_accounts').doc(account.id).set(account.toMap());
  }

  Stream<List<SusuAccount>> getSusuAccounts() {
    return _db.collection('susu_accounts').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => SusuAccount.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<SusuAccount?> getSusuAccount(String id) async {
    DocumentSnapshot doc = await _db.collection('susu_accounts').doc(id).get();
    if (doc.exists) {
      return SusuAccount.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }
  
  Future<void> updateAccountStatus(String id, String status) async {
    await _db.collection('susu_accounts').doc(id).update({'status': status});
  }

  // --- Contributions ---

  Future<void> addContribution(MonthlyContribution contribution) async {
    await _db.collection('contributions').add(contribution.toMap());
  }

  Stream<List<MonthlyContribution>> getContributions(String accountId) {
    return _db
        .collection('contributions')
        .where('susuAccountId', isEqualTo: accountId)
        .orderBy('datePaid', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MonthlyContribution.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> editContribution(String contributionId, String accountId, double oldAmount, double newAmount) async {
    WriteBatch batch = _db.batch();
    double difference = newAmount - oldAmount;
    DocumentReference contributionRef = _db.collection('contributions').doc(contributionId);
    batch.update(contributionRef, {'amount': newAmount});
    DocumentReference accountRef = _db.collection('susu_accounts').doc(accountId);
    batch.update(accountRef, {'balance': FieldValue.increment(difference)});
    await batch.commit();
  }

  Future<void> deleteContribution(String contributionId, String accountId, double amountToDelete) async {
    WriteBatch batch = _db.batch();
    DocumentReference contributionRef = _db.collection('contributions').doc(contributionId);
    batch.delete(contributionRef);
    DocumentReference accountRef = _db.collection('susu_accounts').doc(accountId);
    batch.update(accountRef, {'balance': FieldValue.increment(-amountToDelete)});
    await batch.commit();
  }

  // --- Withdrawals ---

  Future<void> requestWithdrawal(WithdrawalRequest request) async {
    await _db.collection('withdrawals').add(request.toMap());
  }

  Stream<List<WithdrawalRequest>> getPendingWithdrawals() {
    return _db
        .collection('withdrawals')
        .where('status', whereIn: ['pending', 'processing'])
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WithdrawalRequest.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<WithdrawalRequest>> getAllWithdrawals() { // New Method
    return _db
        .collection('withdrawals')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WithdrawalRequest.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<WithdrawalRequest>> getWithdrawalsForAccount(String accountId) {
    return _db
        .collection('withdrawals')
        .where('susuAccountId', isEqualTo: accountId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WithdrawalRequest.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> approveWithdrawal(String requestId, String accountId, double amount, {DateTime? availabilityDate, String? notes}) async {
    WriteBatch batch = _db.batch();

    DocumentReference withdrawalRef = _db.collection('withdrawals').doc(requestId);
    batch.update(withdrawalRef, {
      'status': 'approved',
      'availabilityDate': availabilityDate != null ? Timestamp.fromDate(availabilityDate) : null,
      'adminNotes': notes,
    });

    DocumentReference accountRef = _db.collection('susu_accounts').doc(accountId);
    batch.update(accountRef, {
      'balance': FieldValue.increment(-amount)
    });

    await batch.commit();
  }

  Future<void> updateWithdrawalStatus(String requestId, {required String status, String? notes, DateTime? availabilityDate}) async {
    await _db.collection('withdrawals').doc(requestId).update({
      'status': status,
      'adminNotes': notes,
      'availabilityDate': availabilityDate != null ? Timestamp.fromDate(availabilityDate) : null,
    });
  }

  // --- Interest ---

  Future<int> applyMonthlyInterest() async {
    QuerySnapshot snapshot = await _db.collection('susu_accounts').get();
    WriteBatch batch = _db.batch();
    int count = 0;
    for (var doc in snapshot.docs) {
      SusuAccount account = SusuAccount.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (account.status == 'active') {
        double interest = InterestCalculator.calculateMonthlyInterest(account.balance);
        if (interest > 0) {
          batch.update(doc.reference, {
            'balance': FieldValue.increment(interest),
            'interestEarned': FieldValue.increment(interest),
          });
          count++;
        }
      }
    }
    if (count > 0) {
      await batch.commit();
    }
    return count;
  }
}
