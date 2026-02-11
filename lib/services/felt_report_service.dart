import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/felt_report.dart';

class FeltReportService {
  final CollectionReference _feltReportsCollection = FirebaseFirestore.instance.collection('felt_reports');

  Future<void> addFeltReport(FeltReport report) async {
    try {
      await _feltReportsCollection.add(report.toMap());
    } catch (e) {
      print('Error adding felt report: $e');
    }
  }

  Future<List<FeltReport>> getFeltReports(String earthquakeId) async {
    try {
      final querySnapshot = await _feltReportsCollection
          .where('earthquakeId', isEqualTo: earthquakeId)
          .get();

      return querySnapshot.docs.map((doc) => FeltReport.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting felt reports: $e');
      return [];
    }
  }
}
