// A driver's vehicle with full detail and signed photo URLs, as returned by
// GET /driver-auth/me/vehicles — for the profile's vehicle catalog/detail.
// (Richer than the ChecklistVehicle, which the applicant flow uses.)

/// One vehicle photo with a short-lived signed URL.
class VehicleImage {
  final String id;
  final int position;
  final String url;

  const VehicleImage({required this.id, required this.position, required this.url});

  factory VehicleImage.fromJson(Map<String, dynamic> json) => VehicleImage(
        id: json['id'] as String? ?? '',
        position: json['position'] as int? ?? 0,
        url: json['url'] as String? ?? '',
      );
}

/// A vehicle with its full detail + photos.
class VehicleFull {
  final String id;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;
  final String? plate;
  final String? vehicleType;
  final String approvalStatus; // pending | approved | rejected
  final String? rejectionReason;

  /// The vehicle he is operating with. Only one of his can hold it.
  final bool isPrimary;
  final List<VehicleImage> images;

  const VehicleFull({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.plate,
    required this.vehicleType,
    this.isPrimary = false,
    required this.approvalStatus,
    required this.rejectionReason,
    required this.images,
  });

  bool get isApproved => approvalStatus == 'approved';
  bool get isRejected => approvalStatus == 'rejected';

  /// Human label ("Toyota Corolla" / the plate / fallback).
  String get label {
    final parts = [brand, model].where((p) => p != null && p.trim().isNotEmpty).join(' ');
    if (parts.isNotEmpty) return parts;
    final p = plate?.trim();
    return (p != null && p.isNotEmpty) ? p : 'Vehículo';
  }

  factory VehicleFull.fromJson(Map<String, dynamic> json) => VehicleFull(
        id: json['id'] as String? ?? '',
        brand: (json['brand'] as String?)?.trim(),
        model: (json['model'] as String?)?.trim(),
        year: json['year'] as int?,
        color: (json['color'] as String?)?.trim(),
        plate: (json['plate'] as String?)?.trim(),
        vehicleType: (json['vehicleType'] as String?)?.trim(),
        approvalStatus: (json['approvalStatus'] as String?) ?? 'pending',
        rejectionReason: (json['rejectionReason'] as String?)?.trim(),
        images: (json['images'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => VehicleImage.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}
