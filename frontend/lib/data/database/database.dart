import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get department => text()();
  DateTimeColumn get hireDate => dateTime()();
  TextColumn get qrCodeData => text().unique()();
  TextColumn get status => text().withDefault(const Constant('active'))();
}

class Attendance extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get employeeId => integer().references(Employees, #id)();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get type => text()(); // check-in or check-out
  TextColumn get notes => text().nullable()();
}

class Departments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get description => text()();
}

class Settings extends Table {
  TextColumn get key => text().withLength(min: 1, max: 50)();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Employees, Attendance, Departments, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Add migration logic here when needed
      },
    );
  }

  // Employee operations
  Future<List<Employee>> getAllEmployees() => select(employees).get();
  
  Future<Employee> getEmployee(int id) =>
      (select(employees)..where((e) => e.id.equals(id))).getSingle();
  
  Future<int> addEmployee(EmployeesCompanion employee) =>
      into(employees).insert(employee);
  
  Future<bool> updateEmployee(Employee employee) =>
      update(employees).replace(employee);
  
  Future<int> deleteEmployee(int id) =>
      (delete(employees)..where((e) => e.id.equals(id))).go();

  // Attendance operations
  Future<List<AttendanceData>> getAttendanceForEmployee(int employeeId) =>
      (select(attendance)..where((a) => a.employeeId.equals(employeeId))).get();
  
  Future<int> recordAttendance(AttendanceCompanion record) =>
      into(attendance).insert(record);

  // Department operations
  Future<List<Department>> getAllDepartments() => select(departments).get();
  
  Future<int> addDepartment(DepartmentsCompanion department) =>
      into(departments).insert(department);
  
  Future<bool> updateDepartment(Department department) =>
      update(departments).replace(department);
  
  Future<int> deleteDepartment(int id) =>
      (delete(departments)..where((d) => d.id.equals(id))).go();

  // Settings operations
  Future<String?> getSetting(String key) async {
    final result = await (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }
  
  Future<void> setSetting(String key, String value) =>
      into(settings).insert(
        SettingsCompanion.insert(key: key, value: value),
        mode: InsertMode.insertOrReplace,
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'attendance.db'));
    return NativeDatabase(file);
  });
} 