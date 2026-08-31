/// A passenger's profile as returned by the `/client-auth` endpoints.
///
/// Thin on purpose, mirroring the backend's `clientPublicSchema`: the person
/// lives in `users` (shared with the driver side), and the client side only
/// adds a status. No trips, ratings or payment methods yet — those fields
/// appear when the thing they refer to exists.
class Client {
  final String userId;
  final String fullName;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? secondLastName;
  final String? email;
  final String? phone;
  final String? photoUrl;

  /// `yyyy-MM-dd`, as the backend stores it. Kept as a string: the app only
  /// ever displays or resends it.
  final String? birthDate;
  final String? address;

  /// `active` / `suspended`. A suspended client cannot LOG IN (the backend
  /// refuses); an already-open session is only cut off per feature, later.
  final String status;

  /// Present only when this person is ALSO an affiliate — it lives on
  /// `drivers`, not on `users`.
  final String? nationalId;

  /// When the client side of the account was created ("Cliente desde …").
  final DateTime? createdAt;

  const Client({
    required this.userId,
    required this.fullName,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.secondLastName,
    this.email,
    this.phone,
    this.photoUrl,
    this.birthDate,
    this.address,
    required this.status,
    this.nationalId,
    this.createdAt,
  });

  /// Locally applies what an edit (or a new photo) returned, so the profile
  /// repaints without a full re-login.
  Client copyWith({String? photoUrl}) => Client(
        userId: userId,
        fullName: fullName,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        secondLastName: secondLastName,
        email: email,
        phone: phone,
        photoUrl: photoUrl ?? this.photoUrl,
        birthDate: birthDate,
        address: address,
        status: status,
        nationalId: nationalId,
        createdAt: createdAt,
      );
}
