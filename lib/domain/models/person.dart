import 'package:uuid/uuid.dart';

class Person {
  final String id;
  final String name;
  final DateTime creationDate;
  final bool isArchived;

  Person({
    String? id,
    required this.name,
    DateTime? creationDate,
    this.isArchived = false,
  })  : id = id ?? const Uuid().v4(),
        creationDate = creationDate ?? DateTime.now();

  Person copyWith({
    String? id,
    String? name,
    DateTime? creationDate,
    bool? isArchived,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      creationDate: creationDate ?? this.creationDate,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'creationDate': creationDate.toIso8601String(),
        'isArchived': isArchived,
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        name: json['name'] as String,
        creationDate: DateTime.parse(json['creationDate'] as String),
        isArchived: json['isArchived'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
