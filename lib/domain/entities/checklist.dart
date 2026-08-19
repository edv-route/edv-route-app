// The "completa tu solicitud" checklist the app renders after the applicant logs
// in: for every active requirement (driver + per vehicle), the document's review
// state, plus each vehicle's own state — so the app can guide the applicant to
// finish (upload what's missing, fix what was rejected). Mirrors the backend
// `AppChecklist` (driver-auth.repository).

/// Review state of a single requirement's document in the checklist.
enum DocReview {
  /// No document has been created for this requirement yet.
  missing,

  /// A document exists and is awaiting admin review.
  pending,

  /// Approved by the admin.
  approved,

  /// Rejected by the admin (see [ChecklistDocument.rejectionReason]).
  rejected,
}

/// One document slot in the checklist. `documentId == null` = not created yet.
class ChecklistDocument {
  final int requirementId;
  final String requirementName;
  final bool isRequired;
  final String? documentId;
  final bool hasFile;
  final String? approvalStatus; // pending | approved | rejected | null
  final String? rejectionReason;

  const ChecklistDocument({
    required this.requirementId,
    required this.requirementName,
    required this.isRequired,
    required this.documentId,
    required this.hasFile,
    required this.approvalStatus,
    required this.rejectionReason,
  });

  DocReview get review {
    if (documentId == null) return DocReview.missing;
    switch (approvalStatus) {
      case 'approved':
        return DocReview.approved;
      case 'rejected':
        return DocReview.rejected;
      default:
        return DocReview.pending;
    }
  }

  bool get isMissing => review == DocReview.missing;
  bool get isRejected => review == DocReview.rejected;
  bool get isApproved => review == DocReview.approved;

  /// A slot exists but its file hasn't been uploaded yet (created via /me/documents
  /// without attaching the file). Still needs the applicant to upload it.
  bool get needsFile => documentId != null && !hasFile;

  /// The applicant can upload/replace the file at any time UNTIL it is approved:
  /// missing, without a file, under review (pending) or rejected. Once approved it
  /// is locked in the app — replacing it would invalidate the verdict, so that's
  /// the office's job (the backend still guards this server-side).
  bool get canUpload => !isApproved;

  /// The applicant still has to act on this item: a required document missing or
  /// without its file, or any document that was rejected.
  bool get needsAction => (isRequired && (isMissing || needsFile)) || isRejected;

  factory ChecklistDocument.fromJson(Map<String, dynamic> json) => ChecklistDocument(
        requirementId: json['requirementId'] as int,
        requirementName: (json['requirementName'] as String?) ?? 'Documento',
        isRequired: json['isRequired'] as bool? ?? false,
        documentId: json['documentId'] as String?,
        hasFile: json['hasFile'] as bool? ?? false,
        approvalStatus: json['approvalStatus'] as String?,
        rejectionReason: (json['rejectionReason'] as String?)?.trim(),
      );
}

/// A vehicle in the checklist, with its own review state and its document slots.
class ChecklistVehicle {
  final String id;
  final String? brand;
  final String? model;
  final String? plate;
  final String approvalStatus; // pending | approved | rejected
  final String? rejectionReason;
  final List<ChecklistDocument> documents;

  /// The vehicle he is operating with. It travels WITH the checklist on purpose:
  /// asking a second endpoint for it meant that when that call failed the list
  /// silently showed none in use — and offered "use this one" on the one already
  /// in use.
  final bool isPrimary;

  const ChecklistVehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.plate,
    required this.approvalStatus,
    required this.rejectionReason,
    required this.documents,
    this.isPrimary = false,
  });

  bool get isRejected => approvalStatus == 'rejected';
  bool get isApproved => approvalStatus == 'approved';

  /// Human label for the vehicle card ("Toyota Corolla" / the plate / fallback).
  String get label {
    final parts = [brand, model].where((p) => p != null && p.trim().isNotEmpty).join(' ');
    if (parts.isNotEmpty) return parts;
    final p = plate?.trim();
    return (p != null && p.isNotEmpty) ? p : 'Vehículo';
  }

  /// The vehicle or any of its documents still need the applicant to act.
  bool get needsAction => isRejected || documents.any((d) => d.needsAction);

  factory ChecklistVehicle.fromJson(Map<String, dynamic> json) => ChecklistVehicle(
        id: json['id'] as String,
        brand: (json['brand'] as String?)?.trim(),
        model: (json['model'] as String?)?.trim(),
        plate: (json['plate'] as String?)?.trim(),
        approvalStatus: (json['approvalStatus'] as String?) ?? 'pending',
        rejectionReason: (json['rejectionReason'] as String?)?.trim(),
        isPrimary: json['isPrimary'] as bool? ?? false,
        documents: (json['documents'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => ChecklistDocument.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

/// The applicant's whole solicitud checklist.
class Checklist {
  final List<ChecklistDocument> driverDocuments;
  final List<ChecklistVehicle> vehicles;

  const Checklist({required this.driverDocuments, required this.vehicles});

  bool get hasVehicle => vehicles.isNotEmpty;

  /// Every driver + vehicle document slot flattened, for quick counts.
  List<ChecklistDocument> get allDocuments =>
      [...driverDocuments, for (final v in vehicles) ...v.documents];

  /// Items the applicant must still act on (missing required docs, rejections,
  /// rejected vehicles). Drives the "qué te falta" guidance.
  int get pendingActions =>
      allDocuments.where((d) => d.needsAction).length +
      vehicles.where((v) => v.isRejected).length +
      (hasVehicle ? 0 : 1); // no vehicle yet is itself a pending action

  /// Nothing left for the applicant to do: has a vehicle, no required doc missing,
  /// nothing rejected. (Final approval is still the admin's call.)
  bool get isReadyForReview => pendingActions == 0;

  // --- Section summaries for the hub cards (counts only; the UI formats the
  //     Spanish label from these). --------------------------------------------
  int get driverTotal => driverDocuments.length;
  int get driverApproved => driverDocuments.where((d) => d.isApproved).length;
  int get driverRejected => driverDocuments.where((d) => d.isRejected).length;
  int get driverActionable => driverDocuments.where((d) => d.needsAction).length;

  int get vehicleCount => vehicles.length;
  int get vehiclesApproved => vehicles.where((v) => v.isApproved).length;
  int get vehiclesActionable => vehicles.where((v) => v.needsAction).length;

  factory Checklist.fromJson(Map<String, dynamic> json) => Checklist(
        driverDocuments: (json['driverDocuments'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => ChecklistDocument.fromJson(e.cast<String, dynamic>()))
            .toList(),
        vehicles: (json['vehicles'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => ChecklistVehicle.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}
