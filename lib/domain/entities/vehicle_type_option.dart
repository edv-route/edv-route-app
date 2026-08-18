/// A vehicle type offered at registration (from `GET /driver-auth/vehicle-types`).
/// The [id] must be a real backend row so the register FK holds.
class VehicleTypeOption {
  final int id;
  final String name;

  const VehicleTypeOption({required this.id, required this.name});

  factory VehicleTypeOption.fromJson(Map<String, dynamic> json) => VehicleTypeOption(
        id: json['id'] as int,
        // Backend stores it lowercase ("moto"); present it title-cased ("Moto").
        name: _titleCase(json['name'] as String? ?? ''),
      );
}

String _titleCase(String s) => s
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');
