import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/employee.dart';

class CompanyInfo {
  final String name;
  final String? address;
  final String? phone;
  final String? email;

  const CompanyInfo({
    required this.name,
    this.address,
    this.phone,
    this.email,
  });
}

class AttendanceReportRecord {
  final Attendance attendance;
  final Employee employee;

  const AttendanceReportRecord({
    required this.attendance,
    required this.employee,
  });
}

class ReportService {
  static Future<File> generateAttendancePDF({
    required List<AttendanceReportRecord> records,
    required CompanyInfo companyInfo,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          header: (context) => _buildPDFHeader(companyInfo, startDate, endDate),
          build: (context) => [
            _buildPDFAttendanceTable(records),
          ],
        ),
      );

      final output = await getApplicationDocumentsDirectory();
      final fileName = 'attendance_report_${DateFormat('yyyyMMdd').format(startDate)}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      throw Exception('Failed to generate PDF report: $e');
    }
  }

  static Future<File> generateAttendanceExcel({
    required List<AttendanceReportRecord> records,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Attendance Report'];

      // Add headers
      sheet.appendRow([
        'Date',
        'Employee ID',
        'Name',
        'Department',
        'Check-in Time',
        'Check-out Time',
        'Status',
      ]);

      // Add data
      for (var record in records) {
        sheet.appendRow([
          DateFormat('yyyy-MM-dd').format(record.attendance.timestamp),
          record.attendance.employeeId.toString(),
          record.employee.name,
          record.employee.department,
          record.attendance.type == 'check-in'
              ? DateFormat('HH:mm').format(record.attendance.timestamp)
              : '',
          record.attendance.type == 'check-out'
              ? DateFormat('HH:mm').format(record.attendance.timestamp)
              : '',
          record.attendance.type,
        ]);
      }

      final output = await getApplicationDocumentsDirectory();
      final fileName = 'attendance_report_${DateFormat('yyyyMMdd').format(startDate)}.xlsx';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(excel.encode()!);

      return file;
    } catch (e) {
      throw Exception('Failed to generate Excel report: $e');
    }
  }

  static pw.Widget _buildPDFHeader(
    CompanyInfo companyInfo,
    DateTime startDate,
    DateTime endDate,
  ) {
    return pw.Header(
      level: 0,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            companyInfo.name,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          if (companyInfo.address != null) pw.Text(companyInfo.address!),
          if (companyInfo.phone != null) pw.Text(companyInfo.phone!),
          if (companyInfo.email != null) pw.Text(companyInfo.email!),
          pw.SizedBox(height: 20),
          pw.Text(
            'Attendance Report',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Period: ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}',
          ),
          pw.Divider(),
        ],
      ),
    );
  }

  static pw.Widget _buildPDFAttendanceTable(List<AttendanceReportRecord> records) {
    return pw.Table.fromTextArray(
      headers: [
        'Date',
        'Employee ID',
        'Name',
        'Department',
        'Check-in Time',
        'Check-out Time',
        'Status',
      ],
      data: records.map((record) => [
        DateFormat('yyyy-MM-dd').format(record.attendance.timestamp),
        record.attendance.employeeId.toString(),
        record.employee.name,
        record.employee.department,
        record.attendance.type == 'check-in'
            ? DateFormat('HH:mm').format(record.attendance.timestamp)
            : '',
        record.attendance.type == 'check-out'
            ? DateFormat('HH:mm').format(record.attendance.timestamp)
            : '',
        record.attendance.type,
      ]).toList(),
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(
        color: PdfColors.grey300,
      ),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.center,
      },
    );
  }
} 