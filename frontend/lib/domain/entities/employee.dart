import 'package:equatable/equatable.dart';

class Employee extends Equatable {
  final int id;
  final String name;
  final String phone;
  final String department;
  final DateTime hireDate;
  final String qrCodeData;
  final String status;

  const Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.department,
    required this.hireDate,
    required this.qrCodeData,
    required this.status,
  });

  @override
  List<Object> get props => [
        id,
        name,
        phone,
        department,
        hireDate,
        qrCodeData,
        status,
      ];

  Employee copyWith({
    int? id,
    String? name,
    String? phone,
    String? department,
    DateTime? hireDate,
    String? qrCodeData,
    String? status,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      hireDate: hireDate ?? this.hireDate,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      status: status ?? this.status,
    );
  }
} 