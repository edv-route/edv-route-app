/// Administrative status of a driver — mirrors the backend `driver_status` enum.
/// The arrears states (`overdue`, `penalized`) are written by the debt engine, not
/// by an admin: an affiliate moves between them without anyone touching the app.
enum DriverStatus {
  applicant,
  pending,
  approved,
  rejected,
  suspended,
  paused,
  overdue,
  penalized,
  scheduled,
  unknown;

  static DriverStatus fromApi(String? value) => switch (value) {
        'applicant' => DriverStatus.applicant,
        'pending' => DriverStatus.pending,
        'approved' => DriverStatus.approved,
        'rejected' => DriverStatus.rejected,
        'suspended' => DriverStatus.suspended,
        'paused' => DriverStatus.paused,
        'overdue' => DriverStatus.overdue,
        'penalized' => DriverStatus.penalized,
        'scheduled' => DriverStatus.scheduled,
        _ => DriverStatus.unknown,
      };

  /// Whether the affiliate may WORK — take trips and enjoy benefits. It does
  /// NOT gate entering the app: a driver in arrears comes in precisely to see
  /// and settle what he owes (decision 2026-08-18). `overdue` still works on
  /// purpose (he owes weeks but is under the tolerance cap); `penalized` passed
  /// the cap and stops working until he pays and the engine reactivates him.
  bool get canOperate =>
      this == DriverStatus.approved || this == DriverStatus.overdue;
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

  /// Whether the admin already set the tariff start. false = approved but not yet
  /// operating (waiting for the office to activate the account).
  final bool tariffStarted;

  /// Average driver rating (0–5), or null when there are no ratings yet.
  final double? avgRating;

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
    this.tariffStarted = false,
    this.avgRating,
  });

  /// Locally applies what an edit (or a new photo) returned, so the profile
  /// repaints without a full re-login.
  Driver copyWith({String? phone, String? email, String? photoUrl}) => Driver(
        userId: userId,
        fullName: fullName,
        nationalId: nationalId,
        status: status,
        registrationStep: registrationStep,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        isAvailable: isAvailable,
        tariffStarted: tariffStarted,
        avgRating: avgRating,
      );
}
