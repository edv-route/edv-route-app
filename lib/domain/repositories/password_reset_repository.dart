/// Who is recovering: the email the code lands in, plus the cédula when the
/// channel demands it. The driver proves himself with the PAIR (cédula +
/// email); the passenger has no cédula on file, so his email stands alone.
class ResetIdentity {
  final String email;
  final String? nationalId;

  const ResetIdentity({required this.email, this.nationalId});
}

/// "Olvidé mi clave": the three steps walked when someone cannot log in.
///
/// ONE contract for both channels — the flow is identical and only the
/// identity differs — with one implementation per channel (driver / client),
/// each talking to its own endpoints. Nothing here takes a session token: the
/// whole point is that the user has none. What authorises the final step is
/// the [resetToken] the server mints once the emailed code checks out, and
/// that token is good for setting a password and nothing else.
abstract interface class PasswordResetRepository {
  /// Step 1. The identity must match ONE account; the server mails a 6-digit
  /// code to its address. Throws with the reason if it does not match, if the
  /// user asked too often, or if mail is down.
  Future<void> requestCode(ResetIdentity identity);

  /// Step 2. Returns the single-purpose token. Throws with how many tries are
  /// left when the code is wrong.
  Future<String> verifyCode(ResetIdentity identity, String code);

  /// Step 3. Sets the new password and spends the token.
  Future<void> confirm({required String resetToken, required String password});
}
