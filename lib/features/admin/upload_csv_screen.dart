import 'package:flutter/material.dart';
import '../../core/services/csv_upload_service.dart';
import '../shared/loading_widget.dart';

class UploadCsvScreen extends StatefulWidget {
  const UploadCsvScreen({super.key});

  @override
  State<UploadCsvScreen> createState() => _UploadCsvScreenState();
}

class _UploadCsvScreenState extends State<UploadCsvScreen> {
  final CsvUploadService _csvUploadService = CsvUploadService();
  String _statusMessage = "Select a standard CSV file to upload contributions.";
  bool _isUploading = false;

  void _uploadCsv() async {
    setState(() {
      _isUploading = true;
      _statusMessage = "Processing...";
    });

    String result = await _csvUploadService.pickAndProcessCsv();

    setState(() {
      _isUploading = false;
      _statusMessage = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload CSV")),
      body: _isUploading
          ? const LoadingWidget(message: "Processing CSV & Updating Database...")
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload_file, size: 80, color: Colors.blueGrey),
                    const SizedBox(height: 20),
                    const Text(
                      "Required Format:",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "NAME,AccountNumber,Email,B/F GHC,JAN GHC,...,TOTAL GHC,",
                      style: TextStyle(fontFamily: 'monospace'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: _uploadCsv,
                      icon: const Icon(Icons.file_upload),
                      label: const Text("Pick CSV File"),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusMessage.contains("Error") ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
