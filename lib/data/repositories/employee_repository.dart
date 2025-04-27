import 'package:drift/drift.dart';
import '../database/database.dart';

class EmployeeRepository {
  final AppDatabase _db;

  EmployeeRepository(this._db);

  Future<List<Employee>> getAllEmployees() => _db.getAllEmployees();

  Future<Employee> getEmployee(int id) => _db.getEmployee(id);

  Future<int> addEmployee({
    required String name,
    required String phone,
    required String department,
    required DateTime hireDate,
    required String qrCodeData,
    String status = 'active',
  }) {
    return _db.addEmployee(
      EmployeesCompanion.insert(
        name: name,
        phone: phone,
        department: department,
        hireDate: hireDate,
        qrCodeData: qrCodeData,
        status: Value(status),
      ),
    );
  }

  Future<bool> updateEmployee(Employee employee) => _db.updateEmployee(employee);

  Future<int> deleteEmployee(int id) => _db.deleteEmployee(id);

  Future<List<Employee>> searchEmployees(String query) {
    return (_db.select(_db.employees)
          ..where((e) =>
              e.name.like('%$query%') |
              e.department.like('%$query%') |
              e.phone.like('%$query%')))
        .get();
  }

  Future<List<Employee>> getEmployeesByDepartment(String department) {
    return (_db.select(_db.employees)
          ..where((e) => e.department.equals(department)))
        .get();
  }

  Future<List<Employee>> getActiveEmployees() {
    return (_db.select(_db.employees)
          ..where((e) => e.status.equals('active')))
        .get();
  }
} 