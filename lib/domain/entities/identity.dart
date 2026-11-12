/// The three identity photos everybody owes (decision by Luis, 2026-11-12):
/// a selfie with the FRONT camera and the cédula on both sides. They belong to
/// the PERSON, so an affiliate who becomes a passenger (or the other way round)
/// is never asked twice.
enum IdentityKind {
  selfie('selfie', 'Foto tipo carnet'),
  idFront('id_front', 'Cédula · frente'),
  idBack('id_back', 'Cédula · reverso');

  const IdentityKind(this.apiValue, this.label);

  /// The value the API speaks (`/me/identity/:kind`).
  final String apiValue;

  /// How the slot is titled on screen.
  final String label;

  static IdentityKind? fromApi(String? value) {
    for (final k in IdentityKind.values) {
      if (k.apiValue == value) return k;
    }
    return null;
  }
}

/// The whole identity at a glance. Precedence follows what the person has to
/// DO: missing and rejected need him, pending only needs the office.
enum IdentityStatus {
  missing,
  rejected,
  pending,
  approved;

  static IdentityStatus fromApi(String? value) => switch (value) {
        'rejected' => IdentityStatus.rejected,
        'pending' => IdentityStatus.pending,
        'approved' => IdentityStatus.approved,
        _ => IdentityStatus.missing,
      };

  /// Missing or rejected photos stop the app at the identity screen: the
  /// person can fix both himself, right now, from the phone.
  bool get needsAction => this == IdentityStatus.missing || this == IdentityStatus.rejected;
}

enum IdentityPhotoStatus {
  pending,
  approved,
  rejected;

  static IdentityPhotoStatus fromApi(String? value) => switch (value) {
        'approved' => IdentityPhotoStatus.approved,
        'rejected' => IdentityPhotoStatus.rejected,
        _ => IdentityPhotoStatus.pending,
      };
}

/// One photo the server already holds.
class IdentityPhoto {
  final IdentityKind kind;
  final IdentityPhotoStatus status;
  final String? rejectionReason;

  /// Short-lived signed link (2 min); null when it could not be signed.
  final String? url;

  const IdentityPhoto({
    required this.kind,
    required this.status,
    required this.rejectionReason,
    required this.url,
  });

  /// A slot can take a new photo only while empty or rejected: once in review
  /// or approved it is final.
  bool get canRetake => status == IdentityPhotoStatus.rejected;
}

/// What `/me/identity` answers.
class IdentityView {
  final IdentityStatus status;

  /// Whether the office already enforces the rule (`identity_required_enabled`).
  final bool required;
  final Map<IdentityKind, IdentityPhoto> photos;

  const IdentityView({required this.status, required this.required, required this.photos});

  static const empty = IdentityView(status: IdentityStatus.missing, required: false, photos: {});

  factory IdentityView.fromJson(Map<String, dynamic> json) {
    final photos = <IdentityKind, IdentityPhoto>{};
    for (final raw in (json['photos'] as List<dynamic>? ?? const []).whereType<Map>()) {
      final map = raw.cast<String, dynamic>();
      final kind = IdentityKind.fromApi(map['kind'] as String?);
      if (kind == null) continue;
      photos[kind] = IdentityPhoto(
        kind: kind,
        status: IdentityPhotoStatus.fromApi(map['status'] as String?),
        rejectionReason: map['rejectionReason'] as String?,
        url: map['url'] as String?,
      );
    }
    return IdentityView(
      status: IdentityStatus.fromApi(json['status'] as String?),
      required: json['required'] as bool? ?? false,
      photos: photos,
    );
  }

  /// Whether this slot may receive a photo: empty, or rejected by the office.
  bool canTake(IdentityKind kind) => photos[kind]?.canRetake ?? true;
}
