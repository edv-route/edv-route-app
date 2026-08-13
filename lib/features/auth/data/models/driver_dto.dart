import '../../domain/entities/driver.dart';

/// Maps the backend driver JSON (`/driver-auth` payloads) to the domain [Driver].
Driver driverFromJson(Map<String, dynamic> json) => Driver(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      nationalId: json['nationalId'] as String?,
      status: DriverStatus.fromApi(json['status'] as String?),
      registrationStep: json['registrationStep'] as int?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? false,
    );
