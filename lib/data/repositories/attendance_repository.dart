import 'package:drift/drift.dart';
import '../database/database.dart' as db;
import '../../domain/entities/attendance.dart' as domain;

class AttendanceRepository {
  final db.AppDatabase _db;

  AttendanceRepository(this._db);

  Future<List<domain.Attendance>> getAttendanceForEmployee(int employeeId) async {
    final records = await _db.getAttendanceForEmployee(employeeId);
    return records.map((data) => _mapToAttendance(data)).toList();
  }

  Future<List<domain.Attendance>> getAttendanceByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final records = await (_db.select(_db.attendance)
          ..where((a) =>
              a.timestamp.isBiggerOrEqualValue(startDate) &
              a.timestamp.isSmallerOrEqualValue(endDate)))
        .get();
    return records.map((data) => _mapToAttendance(data)).toList();
  }

  Future<List<domain.Attendance>> getTodayAttendance() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getAttendanceByDateRange(startOfDay, endOfDay);
  }

  Future<int> recordAttendance({
    required int employeeId,
    required DateTime timestamp,
    required String type,
    String? notes,
  }) {
    return _db.recordAttendance(
      db.AttendanceCompanion.insert(
        employeeId: employeeId,
        timestamp: timestamp,
        type: type,
        notes: Value(notes),
      ),
    );
  }

  Future<List<domain.Attendance>> getAttendanceByDepartment(
    String department,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final employeesInDepartment = await (_db.select(_db.employees)
          ..where((e) => e.department.equals(department)))
        .get();

    final employeeIds = employeesInDepartment.map((e) => e.id).toList();

    final records = await (_db.select(_db.attendance)
          ..where((a) =>
              a.employeeId.isIn(employeeIds) &
              a.timestamp.isBiggerOrEqualValue(startDate) &
              a.timestamp.isSmallerOrEqualValue(endDate)))
        .get();
    return records.map((data) => _mapToAttendance(data)).toList();
  }

  Future<Map<String, int>> getAttendanceSummary(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final attendanceRecords = await (_db.select(_db.attendance)
          ..where((a) =>
              a.timestamp.isBiggerOrEqualValue(startOfDay) &
              a.timestamp.isSmallerOrEqualValue(endOfDay)))
        .get();

    final totalEmployees = await _db.getAllEmployees();
    final presentEmployees = attendanceRecords
        .where((record) => record.type == 'check-in')
        .map((record) => record.employeeId)
        .toSet()
        .length;

    return {
      'total': totalEmployees.length,
      'present': presentEmployees,
      'absent': totalEmployees.length - presentEmployees,
    };
  }

  domain.Attendance _mapToAttendance(db.AttendanceData data) {
    return domain.Attendance(
      id: data.id,
      employeeId: data.employeeId,
      timestamp: data.timestamp,
      type: data.type,
      notes: data.notes,
    );
  }
} 