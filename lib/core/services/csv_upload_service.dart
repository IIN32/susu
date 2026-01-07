import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../../models/susu_account.dart';
import '../../models/monthly_contribution.dart';

class CsvUploadService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> pickAndProcessCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null) {
        final path = result.files.single.path;
        if (path == null) return "No file path found";

        final input = File(path).openRead();
        final fields = await input
            .transform(utf8.decoder)
            .transform(const CsvToListConverter()) // Use standard comma delimiter
            .toList();

        int successCount = 0;
        int linkCount = 0;
        
        // Skip Header (Row 0)
        for (var i = 1; i < fields.length; i++) {
          var row = fields[i];
          // EXPECTED CSV FORMAT:
          // 0: NAME, 1: AccountNumber, 2: Email, 3: B/F, 4: JAN, ..., 14: NOV, 15: PRINCIPAL, 16: INTEREST, 17: TOTAL
          if (row.length < 18) continue;

          String name = row[0].toString();
          String accountNumber = row[1].toString();
          String email = row[2].toString().trim();
          double totalBalanceFromCsv = double.tryParse(row[17].toString()) ?? 0.0;
          double interestFromCsv = double.tryParse(row[16].toString()) ?? 0.0;

          // 1. Create or Update SusuAccount
          SusuAccount account = SusuAccount(
            id: accountNumber,
            name: name,
            accountNumber: accountNumber,
            balance: totalBalanceFromCsv, 
            interestEarned: interestFromCsv, 
            status: 'active',
            createdAt: DateTime.now(), 
          );
          await _firestoreService.saveSusuAccount(account);

          // 2. Loop through months and create MonthlyContribution records
          final year = DateTime.now().year;
          for (int monthIndex = 4; monthIndex <= 14; monthIndex++) { // JAN is at 4, NOV is at 14
            double amount = double.tryParse(row[monthIndex].toString()) ?? 0.0;
            if (amount > 0) {
              String monthString = "$year-${(monthIndex - 3).toString().padLeft(2, '0')}";
              
              MonthlyContribution contribution = MonthlyContribution(
                id: '',
                susuAccountId: accountNumber,
                month: monthString,
                amount: amount,
                datePaid: DateTime(year, monthIndex - 3, 1),
              );
              await _firestoreService.addContribution(contribution);
            }
          }
          successCount++;

          // 3. Auto-Link User via Email
          if (email.isNotEmpty) {
            var userQuery = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();
            if (userQuery.docs.isNotEmpty) {
              await _db.collection('users').doc(userQuery.docs.first.id).update({'susuAccountId': accountNumber});
              linkCount++;
            }
          }
        }
        return "Successfully processed $successCount rows.\n$linkCount users were auto-linked.";
      } else {
        return "No file selected.";
      }
    } catch (e) {
      return "Error uploading CSV: $e";
    }
  }
}
