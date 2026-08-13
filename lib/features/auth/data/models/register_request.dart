import '../../domain/entities/driver.dart';
import 'driver_dto.dart';

/// Reference to a document the driver will provide (metadata only; the binary is
/// uploaded afterwards). Maps to the backend `documents[]` entries.
class DocumentRef {
  final int requirementId;
  final String? expiresAt;

  const DocumentRef({required this.requirementId, this.expiresAt});

  Map<String, dynamic> toJson() => {
        'requirementId': requirementId,
        if (expiresAt != null) 'expiresAt': expiresAt,
      };
}

/// A vehicle draft carried in the registration payload.
class VehicleDraft {
  final int? vehicleTypeId;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;
  final String? plate;
  final List<DocumentRef> documents;

  const VehicleDraft({
    this.vehicleTypeId,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.plate,
    this.documents = const [],
  });

  Map<String, dynamic> toJson() => {
        if (vehicleTypeId != null) 'vehicleTypeId': vehicleTypeId,
        if (brand != null && brand!.isNotEmpty) 'brand': brand,
        if (model != null && model!.isNotEmpty) 'model': model,
        if (year != null) 'year': year,
        if (color != null && color!.isNotEmpty) 'color': color,
        if (plate != null && plate!.isNotEmpty) 'plate': plate,
        'documents': documents.map((d) => d.toJson()).toList(),
      };
}

/// The full registration payload for `POST /driver-auth/register`. Payment is
/// never sent here — it goes as a separate submission after the alta.
class RegisterRequest {
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? secondLastName;
  final String? birthDate;
  final String? address;
  final String? email;
  final String? phone;
  final String nationalId;
  final String password;
  final List<VehicleDraft> vehicles;
  final List<DocumentRef> documents;

  const RegisterRequest({
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.secondLastName,
    this.birthDate,
    this.address,
    this.email,
    this.phone,
    required this.nationalId,
    required this.password,
    this.vehicles = const [],
    this.documents = const [],
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        if (middleName != null && middleName!.isNotEmpty) 'middleName': middleName,
        'lastName': lastName,
        if (secondLastName != null && secondLastName!.isNotEmpty) 'secondLastName': secondLastName,
        if (birthDate != null) 'birthDate': birthDate,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        'nationalId': nationalId,
        'password': password,
        'vehicles': vehicles.map((v) => v.toJson()).toList(),
        'documents': documents.map((d) => d.toJson()).toList(),
      };
}

/// A vehicle created by the backend, with the ids of its document records so the
/// app can upload each file against the right document id.
class CreatedVehicle {
  final String id;
  final List<String> documentIds;

  const CreatedVehicle({required this.id, required this.documentIds});

  factory CreatedVehicle.fromJson(Map<String, dynamic> json) => CreatedVehicle(
        id: json['id'] as String,
        documentIds: (json['documentIds'] as List?)?.cast<String>() ?? const [],
      );
}

/// The result of a successful `POST /driver-auth/register`.
class RegisterResult {
  final String token;
  final Driver driver;
  final List<String> createdDocumentIds;
  final List<CreatedVehicle> createdVehicles;

  const RegisterResult({
    required this.token,
    required this.driver,
    required this.createdDocumentIds,
    required this.createdVehicles,
  });

  factory RegisterResult.fromJson(Map<String, dynamic> json) => RegisterResult(
        token: json['token'] as String? ?? '',
        driver: driverFromJson((json['driver'] as Map?)?.cast<String, dynamic>() ?? const {}),
        createdDocumentIds: (json['createdDocumentIds'] as List?)?.cast<String>() ?? const [],
        createdVehicles: ((json['createdVehicles'] as List?) ?? const [])
            .map((v) => CreatedVehicle.fromJson((v as Map).cast<String, dynamic>()))
            .toList(),
      );
}
