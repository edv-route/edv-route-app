import '../entities/account_status.dart';
import '../entities/alta_debt.dart';
import '../entities/driver.dart';
import '../entities/picked_image.dart';

/// The driver's own account: what he owes, how he stands, and the data he is
/// allowed to change about himself. Everything here needs his session.
abstract interface class AccountRepository {
  /// What he owes right now, broken down by line (membership, week, penalty).
  Future<AltaDebt> loadDebt();

  /// How he stands: until when he is covered, which charge comes next and how
  /// deep his arrears are.
  Future<AccountStatus> loadAccount();

  /// His address, to prefill the edit form (the rest already travels in the profile).
  Future<String?> loadAddress();

  /// Self-service edit. ONLY these fields: his name and national id are the
  /// identity an admin verified against his documents. Changing the password
  /// requires [currentPassword].
  Future<Driver> updateOwnProfile({
    String? phone,
    String? email,
    String? address,
    String? password,
    String? currentPassword,
  });

  /// Puts him on or off duty. Going OFF is always allowed; going ON is refused
  /// by the backend when his status does not let him operate (penalized/paused).
  Future<bool> setAvailability(bool available);

  /// Replaces his profile photo and returns its (signed, temporary) URL.
  Future<String?> uploadProfilePhoto(PickedImage image);
}
