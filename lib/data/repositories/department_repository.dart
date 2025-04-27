import 'package:drift/drift.dart';
import '../database/database.dart';

class DepartmentRepository {
  final AppDatabase _db;

  DepartmentRepository(this._db);

  Future<List<Department>> getAllDepartments() => _db.getAllDepartments();

  Future<int> addDepartment({
    required String name,
    required String description,
  }) {
    return _db.addDepartment(
      DepartmentsCompanion.insert(
        name: name,
        description: description,
      ),
    );
  }

  Future<bool> updateDepartment(Department department) =>
      _db.updateDepartment(department);

  Future<int> deleteDepartment(int id) => _db.deleteDepartment(id);

  Future<List<Department>> searchDepartments(String query) {
    return (_db.select(_db.departments)
          ..where((d) =>
              d.name.like('%$query%') |
              d.description.like('%$query%')))
        .get();
  }

  Future<int> getEmployeeCount(int departmentId) async {
    final department = await (_db.select(_db.departments)
          ..where((d) => d.id.equals(departmentId)))
        .getSingle();

    final employees = await (_db.select(_db.employees)
          ..where((e) => e.department.equals(department.name)))
        .get();

    return employees.length;
  }
} 