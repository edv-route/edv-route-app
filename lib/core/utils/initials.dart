/// First letters of the first two words of a full name, uppercased — the
/// fallback every avatar in the app shows when there is no photo. Extracted
/// because the client side needed it in three screens and a third copy is
/// where the drift starts.
String initialsOf(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
  return letters.isEmpty ? '?' : letters.toUpperCase();
}
