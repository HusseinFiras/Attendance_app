import 'package:flutter/material.dart';
import '../../data/database/database.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/department_repository.dart';
import '../../data/repositories/settings_repository.dart';

class RepositoryProvider extends ChangeNotifier {
  final AppDatabase _db;
  late final EmployeeRepository employeeRepository;
  late final AttendanceRepository attendanceRepository;
  late final DepartmentRepository departmentRepository;
  late final SettingsRepository settingsRepository;

  RepositoryProvider(this._db) {
    employeeRepository = EmployeeRepository(_db);
    attendanceRepository = AttendanceRepository(_db);
    departmentRepository = DepartmentRepository(_db);
    settingsRepository = SettingsRepository(_db);
  }
} 