import 'package:equatable/equatable.dart';

class Department extends Equatable {
  final int id;
  final String name;
  final String description;

  const Department({
    required this.id,
    required this.name,
    required this.description,
  });

  @override
  List<Object?> get props => [id, name, description];

  Department copyWith({
    int? id,
    String? name,
    String? description,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
} 