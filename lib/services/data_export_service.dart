import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/analytics_data.dart';
import '../models/session_analytics.dart';

class DataExportService {
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