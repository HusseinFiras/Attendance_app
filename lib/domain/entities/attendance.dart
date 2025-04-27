import 'package:equatable/equatable.dart';

class Attendance extends Equatable {
  final int id;
  final int employeeId;
  final DateTime timestamp;
  final String type;
  final String? notes;

  const Attendance({
    required this.id,
    required this.employeeId,
    required this.timestamp,
    required this.type,
    this.notes,
  });

  @override
  List<Object?> get props => [id, employeeId, timestamp, type, notes];

  Attendance copyWith({
    int? id,
    int? employeeId,
    DateTime? timestamp,
    String? type,
    String? notes,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      notes: notes ?? this.notes,
    );
  }
} 