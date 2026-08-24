/// "Olvidé mi clave": the three steps a driver walks when he cannot log in.
///
/// Nothing here takes a session token — the whole point is that he has none.
/// What authorises the final step is the [resetToken] the server mints once the
/// emailed code checks out, and that token is good for setting a password and
/// nothing else.
abstract interface class PasswordResetRepository {
  /// Step 1. Cédula and email must match the SAME account; the server mails a
  /// 6-digit code to that address. Throws with the reason if they do not match,
  /// if he asked too often, or if mail is down.
  Future<void> requestCode({required String nationalId, required String email});

  /// Step 2. Returns the single-purpose token. Throws with how many tries are
  /// left when the code is wrong.
  Future<String> verifyCode({
    required String nationalId,
    required String email,
    required String code,
  });

  /// Step 3. Sets the new password and spends the token.
  Future<void> confirm({required String resetToken, required String password});
}
