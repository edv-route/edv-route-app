/// Person-field validators shared by the affiliate and the client forms,
/// mirroring the backend's `personProperties` (drivers.schemas). Extracted so
/// the two registration forms literally share the same rules instead of each
/// keeping a copy that drifts — the same reason the backend imports them.
library;

final RegExp _nameRegex = RegExp(r"^\p{L}+(?:[ '-]\p{L}+)*$", unicode: true);
final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Names: 2-80 letters (accents, apostrophes and hyphens allowed).
String? validatePersonName(String? v, {required bool required, required String field}) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return required ? 'Ingresa $field.' : null;
  if (required && t.length < 2) return 'Debe tener entre 2 y 80 letras.';
  if (t.length > 80) return 'Máximo 80 letras.';
  if (!_nameRegex.hasMatch(t)) return 'Solo se admiten letras.';
  return null;
}

/// Email is REQUIRED on both channels: it is how a forgotten password is
/// recovered, so an account without one has no way back in.
String? validatePersonEmail(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return 'Ingresa tu correo electrónico.';
  if (!_emailRegex.hasMatch(t)) return 'Correo inválido.';
  return null;
}

/// The 7 local digits after the +58 + operator selector. Blank is allowed —
/// whether the phone is required is the FORM's decision, not the field's.
String? validatePersonPhone(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return null;
  if (t.length != 7) return 'El teléfono debe tener 7 dígitos (ej. 1234567).';
  return null;
}

/// New password: 6-72 characters, digits-only allowed (PIN-style).
String? validateNewPassword(String? v) {
  final t = v ?? '';
  if (t.isEmpty) return 'Crea una clave.';
  if (t.length < 6 || t.length > 72) return 'Entre 6 y 72 caracteres.';
  return null;
}

/// The confirmation field, checked against what [password] currently holds.
String? validatePasswordConfirm(String? v, String password) {
  final t = v ?? '';
  if (t.isEmpty) return 'Repite tu clave.';
  if (t != password) return 'Las claves no coinciden.';
  return null;
}

/// Capitalizes the first letter of each word, leaving the rest untouched (so
/// acronyms like "BMW" survive). Empty input stays empty.
String titleCase(String s) => s
    .trim()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');
