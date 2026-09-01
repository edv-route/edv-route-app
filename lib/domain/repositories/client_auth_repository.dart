import '../entities/client.dart';
import '../entities/picked_image.dart';
import '../../data/models/client_register_request.dart';

/// Contract for the passenger's session and own account, mirroring the driver's
/// [AuthRepository] + [AccountRepository] pair in ONE interface: the client side
/// is small enough that splitting it today would be structure without content.
abstract interface class ClientAuthRepository {
  /// Signs in with email OR phone (whichever he remembers) + password, persists
  /// the session token, and returns the profile. Throws [ApiException] on bad
  /// credentials or transport errors.
  Future<Client> login({required String identifier, required String password});

  /// Step 0 of the registration (cédula-first): which form does this cédula
  /// deserve? Returns `new`, `attachable` or `exists`.
  Future<String> checkCedula(String nationalId);

  /// FULL registration (new person) — persists the returned session token.
  Future<Client> register(ClientRegisterRequest request);

  /// SHORT registration: an existing person (an affiliate) gains the client
  /// side, proving it is him with the password he already has and bringing
  /// this role's own email, phone and password.
  Future<Client> attach({
    required String nationalId,
    required String currentPassword,
    required String email,
    required String phone,
    required String password,
  });

  /// The current session's profile (GET /me) when a valid token is stored, or
  /// null when there is no session or it expired (the token is then cleared).
  /// Rethrows [ApiException] on transport errors so the caller can distinguish
  /// "no session" from "couldn't reach the server".
  Future<Client?> currentClient();

  /// Partial self-service edit. Only the fields passed travel; changing the
  /// password requires [currentPassword].
  Future<Client> updateProfile({
    String? firstName,
    String? middleName,
    String? lastName,
    String? secondLastName,
    String? phone,
    String? email,
    String? address,
    String? password,
    String? currentPassword,
  });

  /// Replaces the profile photo and returns its (signed, temporary) URL.
  Future<String?> uploadProfilePhoto(PickedImage image);

  /// Clears the stored session.
  Future<void> logout();
}
