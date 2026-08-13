/// Administrative status of a driver — mirrors the backend `driver_status` enum.
enum DriverStatus {
  applicant,
  pending,
  approved,
  rejected,
  suspended,
  unknown;

  static DriverStatus fromApi(String? value) => switch (value) {
        'applicant' => DriverStatus.applicant,
        'pending' => DriverStatus.pending,
        'approved' => DriverStatus.approved,
        'rejected' => DriverStatus.rejected,
        'suspended' => DriverStatus.suspended,
        _ => DriverStatus.unknown,
      };
}

/// A driver's public profile as returned by the auth endpoints.
class Driver {
  final String userId;
  final String fullName;
  final String? nationalId;
  final DriverStatus status;
  final int? registrationStep;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final bool isAvailable;

  const Driver({
    required this.userId,
    required this.fullName,
    required this.nationalId,
    required this.status,
    required this.registrationStep,
    required this.phone,
    required this.email,
    required this.photoUrl,
    required this.isAvailable,
  });
}
