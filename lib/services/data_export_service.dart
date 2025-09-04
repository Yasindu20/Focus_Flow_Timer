import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/analytics_data.dart';
import '../models/session_analytics.dart';

class DataExportService {
  static const List<String> firestoreCollections = [
    'users',
    'sessions', 
    'tasks',
    'analytics',
    'goals',
    'productivity_scores',
    'daily_stats',
    'task_analytics',
    'timer_sessions',
    'pomodoro_sessions'
  ];

  Future<Map<String, dynamic>> exportAllUserData(String userId) async {
    final Map<String, dynamic> userData = {};
    
    userData['export_info'] = {
      'export_date': DateTime.now().toIso8601String(),
      'user_id': userId,
      'app_name': 'Focus Flow Timer',
      'data_format_version': '1.0'
    };

    userData['account_info'] = await _getAccountInfo();
    userData['firestore_data'] = await _getFirestoreData(userId);
    userData['local_preferences'] = await _getLocalPreferences();
    
    return userData;
  }

  Future<String> exportAllUserDataAsJson(String userId) async {
    final userData = await exportAllUserData(userId);
    return const JsonEncoder.withIndent('  ').convert(userData);
  }

  Future<String?> exportUserDataToFile(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/user_data_export_$timestamp.json';

      final jsonData = await exportAllUserDataAsJson(userId);
      
      final file = File(filePath);
      await file.writeAsString(jsonData);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export user data: $e');
    }
  }

  Future<Map<String, dynamic>> _getAccountInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    return {
      'uid': user.uid,
      'email': user.email,
      'display_name': user.displayName,
      'email_verified': user.emailVerified,
      'phone_number': user.phoneNumber,
      'photo_url': user.photoURL,
      'creation_time': user.metadata.creationTime?.toIso8601String(),
      'last_sign_in_time': user.metadata.lastSignInTime?.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _getFirestoreData(String userId) async {
    final Map<String, dynamic> firestoreData = {};
    final firestore = FirebaseFirestore.instance;

    for (final collection in firestoreCollections) {
      try {
        final List<Map<String, dynamic>> collectionData = [];
        
        final querySnapshot = await firestore
            .collection(collection)
            .where('userId', isEqualTo: userId)
            .get();

        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          data['document_id'] = doc.id;
          data['created_at'] = doc.get('createdAt')?.toString() ?? '';
          data['updated_at'] = doc.get('updatedAt')?.toString() ?? '';
          collectionData.add(data);
        }

        final userDocRef = firestore.collection(collection).doc(userId);
        final userDocSnapshot = await userDocRef.get();
        if (userDocSnapshot.exists) {
          final userData = userDocSnapshot.data() as Map<String, dynamic>;
          userData['document_id'] = userDocSnapshot.id;
          userData['created_at'] = userData['createdAt']?.toString() ?? '';
          userData['updated_at'] = userData['updatedAt']?.toString() ?? '';
          collectionData.add(userData);
        }

        if (collectionData.isNotEmpty) {
          firestoreData[collection] = collectionData;
        }
      } catch (e) {
        firestoreData['${collection}_error'] = 'Failed to export: $e';
      }
    }

    return firestoreData;
  }

  Future<Map<String, dynamic>> _getLocalPreferences() async {
    final Map<String, dynamic> preferences = {};
    final prefs = await SharedPreferences.getInstance();

    final keys = prefs.getKeys();
    for (final key in keys) {
      try {
        final value = prefs.get(key);
        preferences[key] = value;
      } catch (e) {
        preferences['${key}_error'] = 'Failed to export: $e';
      }
    }

    return preferences;
  }
  Future<String?> exportToCSV(DashboardData data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/focus_analytics_$timestamp.csv';

      // Prepare CSV data
      final csvData = <List<String>>[];
      
      // Headers
      csvData.add([
        'Date',
        'Start Time',
        'End Time',
        'Duration (minutes)',
        'Status',
        'Day of Week',
        'Hour of Day',
      ]);

      // Combine all sessions for export
      final allSessions = <SessionAnalytics>[];
      allSessions.addAll(data.monthlySessions);

      // Sort by date
      allSessions.sort((a, b) => a.startTime.compareTo(b.startTime));

      // Add session data
      for (final session in allSessions) {
        csvData.add([
          DateFormat('yyyy-MM-dd').format(session.startTime),
          DateFormat('HH:mm:ss').format(session.startTime),
          session.endTime != null 
              ? DateFormat('HH:mm:ss').format(session.endTime!) 
              : 'N/A',
          session.durationMinutes.toString(),
          session.status,
          DateFormat('EEEE').format(session.startTime),
          session.startTime.hour.toString(),
        ]);
      }

      // Add summary statistics
      csvData.add([]); // Empty row
      csvData.add(['SUMMARY STATISTICS']);
      csvData.add(['Total Sessions', allSessions.length.toString()]);
      csvData.add(['Completed Sessions', allSessions.where((s) => s.isCompleted).length.toString()]);
      csvData.add(['Interrupted Sessions', allSessions.where((s) => s.isInterrupted).length.toString()]);
      csvData.add(['Efficiency Rate', '${data.efficiency.toStringAsFixed(1)}%']);
      csvData.add(['Current Streak', '${data.streak} days']);
      csvData.add(['Total Focus Time', '${(data.monthlyFocusMinutes / 60).toStringAsFixed(1)} hours']);

      // Add goals if available
      if (data.goals != null) {
        csvData.add([]);
        csvData.add(['GOALS']);
        csvData.add(['Daily Sessions Target', data.goals!.dailySessions.toString()]);
        csvData.add(['Weekly Hours Target', data.goals!.weeklyHours.toString()]);
        csvData.add(['Daily Progress', '${(data.dailyProgress * 100).toStringAsFixed(1)}%']);
        csvData.add(['Weekly Progress', '${(data.weeklyProgress * 100).toStringAsFixed(1)}%']);
      }

      // Write CSV file
      final csvString = const ListToCsvConverter().convert(csvData);
      final file = File(filePath);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  Future<String?> exportToPDF(DashboardData data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/focus_analytics_$timestamp.pdf';

      final pdf = pw.Document();

      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            _buildPdfHeader(),
            pw.SizedBox(height: 20),
            _buildPdfSummary(data),
            pw.SizedBox(height: 20),
            _buildPdfGoals(data),
            pw.SizedBox(height: 20),
            _buildPdfSessionsTable(data.monthlySessions),
            pw.SizedBox(height: 20),
            _buildPdfFocusPatterns(data.focusPatterns),
          ],
        ),
      );

      // Write PDF file
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  pw.Widget _buildPdfHeader() {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Focus Flow Timer - Analytics Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            DateFormat('MMM dd, yyyy').format(DateTime.now()),
            style: const pw.TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSummary(DashboardData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary Statistics',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              _buildPdfSummaryRow('Current Streak', '${data.streak} days'),
              _buildPdfSummaryRow('Efficiency Rate', '${data.efficiency.toStringAsFixed(1)}%'),
              _buildPdfSummaryRow('Today\'s Focus Time', '${(data.todayFocusMinutes / 60).toStringAsFixed(1)} hours'),
              _buildPdfSummaryRow('This Week\'s Focus Time', '${(data.weeklyFocusMinutes / 60).toStringAsFixed(1)} hours'),
              _buildPdfSummaryRow('This Month\'s Focus Time', '${(data.monthlyFocusMinutes / 60).toStringAsFixed(1)} hours'),
              _buildPdfSummaryRow('Peak Focus Hour', _formatHour(data.peakFocusHour)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfGoals(DashboardData data) {
    if (data.goals == null) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Goals & Progress',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              _buildPdfSummaryRow('Daily Sessions Target', '${data.goals!.dailySessions}'),
              _buildPdfSummaryRow('Weekly Hours Target', '${data.goals!.weeklyHours}'),
              _buildPdfSummaryRow('Daily Progress', '${(data.dailyProgress * 100).toStringAsFixed(1)}%'),
              _buildPdfSummaryRow('Weekly Progress', '${(data.weeklyProgress * 100).toStringAsFixed(1)}%'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSessionsTable(List<SessionAnalytics> sessions) {
    final recentSessions = sessions.take(20).toList(); // Show last 20 sessions

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Recent Sessions (Last 20)',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildPdfTableCell('Date', isHeader: true),
                _buildPdfTableCell('Start Time', isHeader: true),
                _buildPdfTableCell('Duration', isHeader: true),
                _buildPdfTableCell('Status', isHeader: true),
              ],
            ),
            ...recentSessions.map((session) => pw.TableRow(
              children: [
                _buildPdfTableCell(DateFormat('MMM dd').format(session.startTime)),
                _buildPdfTableCell(DateFormat('HH:mm').format(session.startTime)),
                _buildPdfTableCell('${session.durationMinutes}m'),
                _buildPdfTableCell(session.status.toUpperCase()),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildPdfFocusPatterns(Map<int, int> focusPatterns) {
    final sortedHours = focusPatterns.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topHours = sortedHours.take(5).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Top Focus Hours',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: topHours.map((entry) {
              return _buildPdfSummaryRow(
                _formatHour(entry.key),
                '${entry.value} sessions',
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour < 12) return '$hour:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${hour - 12}:00 PM';
  }
}