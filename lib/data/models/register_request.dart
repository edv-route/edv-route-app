import '../../domain/entities/driver.dart';
import './driver_dto.dart';

/// Step-1 registration payload for `POST /driver-auth/register` (solicitudes-app):
/// personal data + privacy consent ONLY. Documents, vehicles and payment are added
/// afterwards from the checklist (/me/* endpoints), never here — the backend
/// rejects any extra field (the register body is `additionalProperties: false`).
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
  final bool acceptedPrivacy;

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
    required this.acceptedPrivacy,
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
        'acceptedPrivacy': acceptedPrivacy,
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
