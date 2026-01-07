import 'package:csv/csv.dart';

class CsvParser {
  /// Parses a CSV string into a List of Lists (Rows)
  List<List<dynamic>> parseCsvString(String csvData) {
    return const CsvToListConverter().convert(csvData, eol: '\n');
  }
}
