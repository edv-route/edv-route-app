/// A document requirement the app asks for during registration
/// (from `GET /driver-auth/requirements`).
class Requirement {
  final int id;
  final String name;
  final String? description;
  final String appliesTo; // 'driver' | 'vehicle'
  final bool isRequired;

  const Requirement({
    required this.id,
    required this.name,
    required this.description,
    required this.appliesTo,
    required this.isRequired,
  });

  factory Requirement.fromJson(Map<String, dynamic> json) => Requirement(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        appliesTo: json['appliesTo'] as String? ?? 'driver',
        isRequired: json['isRequired'] as bool? ?? false,
      );

  bool get isDriver => appliesTo == 'driver';
  bool get isVehicle => appliesTo == 'vehicle';
}
