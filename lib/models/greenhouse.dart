import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple data holder for a greenhouse folder with its assigned devices.
class Greenhouse {
  final String id;
  final String name;
  final List<String> devices;
  final Timestamp? createdAt;

  const Greenhouse({
    required this.id,
    required this.name,
    required this.devices,
    this.createdAt,
  });

  Greenhouse copyWith({
    String? id,
    String? name,
    List<String>? devices,
    Timestamp? createdAt,
  }) {
    return Greenhouse(
      id: id ?? this.id,
      name: name ?? this.name,
      devices: devices ?? this.devices,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Greenhouse.fromMap(Map<String, dynamic> map) {
    return Greenhouse(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed greenhouse',
      devices: List<String>.from(map['devices'] ?? <String>[]),
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'] as Timestamp : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'devices': devices,
      'createdAt': createdAt ?? Timestamp.now(),
    };
  }
}
