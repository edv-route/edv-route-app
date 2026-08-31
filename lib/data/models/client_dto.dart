import '../../domain/entities/client.dart';

/// Maps the backend client JSON (`/client-auth` payloads) to the domain [Client].
Client clientFromJson(Map<String, dynamic> json) => Client(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String? ?? '',
      secondLastName: json['secondLastName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      birthDate: json['birthDate'] as String?,
      address: json['address'] as String?,
      status: json['status'] as String? ?? 'active',
      nationalId: json['nationalId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
