/// A vehicle being built ON THE PHONE, before the server ever hears about it
/// (2026-08-20). It used to be assembled on the server piece by piece — create
/// the vehicle, upload a photo, create a document, attach its file — so a failed
/// call left half a vehicle stored and an incomplete record in the admin's
/// review queue. Now nothing travels until the driver says it is ready.
library;

/// One document slot of the draft: the requirement it answers and, once picked,
/// the file that lives in the app's private folder.
class DraftDocument {
  final int requirementId;
  final String requirementName;

  /// Path inside the app's own folder. Null while the driver hasn't picked it.
  final String? localPath;

  /// Original name, only to show him what he attached.
  final String? fileName;

  const DraftDocument({
    required this.requirementId,
    required this.requirementName,
    this.localPath,
    this.fileName,
  });

  bool get isFilled => localPath != null;

  DraftDocument copyWith({String? localPath, String? fileName}) => DraftDocument(
        requirementId: requirementId,
        requirementName: requirementName,
        localPath: localPath ?? this.localPath,
        fileName: fileName ?? this.fileName,
      );

  Map<String, dynamic> toJson() => {
        'requirementId': requirementId,
        'requirementName': requirementName,
        'localPath': localPath,
        'fileName': fileName,
      };

  factory DraftDocument.fromJson(Map<String, dynamic> json) => DraftDocument(
        requirementId: json['requirementId'] as int,
        requirementName: (json['requirementName'] as String?) ?? 'Documento',
        localPath: json['localPath'] as String?,
        fileName: json['fileName'] as String?,
      );
}

/// The whole draft: the vehicle's data, its single photo and one slot per active
/// vehicle requirement. Editable field by field until it is sent.
class VehicleDraft {
  final int? vehicleTypeId;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;
  final String? plate;

  /// The ONE photo (the limit dropped from three on 2026-08-20).
  final String? photoPath;

  final List<DraftDocument> documents;

  /// Set when the driver is correcting a REJECTED vehicle: the draft goes back
  /// to that vehicle instead of creating another one.
  final String? correctingVehicleId;

  const VehicleDraft({
    this.vehicleTypeId,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.plate,
    this.photoPath,
    this.documents = const [],
    this.correctingVehicleId,
  });

  bool get hasPhoto => photoPath != null;

  /// Data the admin needs to identify the vehicle. The plate is what makes it
  /// unique in the system, so it is the one field that cannot be left out.
  bool get hasRequiredData =>
      (plate?.trim().isNotEmpty ?? false) && vehicleTypeId != null;

  List<DraftDocument> get missingDocuments => documents.where((d) => !d.isFilled).toList();

  /// What the "Enviar a revisión" button waits for: the data, the photo and
  /// every document. The same three things the backend demands, so the driver
  /// never gets a rejection he could have seen coming on his own screen.
  bool get isReadyToSend =>
      hasRequiredData && hasPhoto && documents.isNotEmpty && missingDocuments.isEmpty;

  /// What is still missing, in the order it should be read out to him.
  List<String> get pendingReasons => [
        if (!hasRequiredData) 'Completa los datos del vehículo',
        if (!hasPhoto) 'Agrega la foto del vehículo',
        for (final d in missingDocuments) 'Falta ${d.requirementName}',
      ];

  VehicleDraft copyWith({
    int? vehicleTypeId,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? plate,
    String? photoPath,
    List<DraftDocument>? documents,
    String? correctingVehicleId,
  }) =>
      VehicleDraft(
        vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
        brand: brand ?? this.brand,
        model: model ?? this.model,
        year: year ?? this.year,
        color: color ?? this.color,
        plate: plate ?? this.plate,
        photoPath: photoPath ?? this.photoPath,
        documents: documents ?? this.documents,
        correctingVehicleId: correctingVehicleId ?? this.correctingVehicleId,
      );

  /// Replaces one document's file, leaving the others untouched.
  VehicleDraft withDocumentFile(int requirementId, String localPath, String fileName) =>
      copyWith(
        documents: [
          for (final d in documents)
            if (d.requirementId == requirementId)
              d.copyWith(localPath: localPath, fileName: fileName)
            else
              d,
        ],
      );

  /// Adds slots for requirements that weren't in the draft yet and drops the ones
  /// that no longer apply — the admin may change the requirement list while the
  /// driver is filling his draft, and what counts is the list at send time.
  VehicleDraft syncRequirements(List<({int id, String name})> requirements) => copyWith(
        documents: [
          for (final r in requirements)
            documents.firstWhere(
              (d) => d.requirementId == r.id,
              orElse: () => DraftDocument(requirementId: r.id, requirementName: r.name),
            ),
        ],
      );

  Map<String, dynamic> toJson() => {
        'vehicleTypeId': vehicleTypeId,
        'brand': brand,
        'model': model,
        'year': year,
        'color': color,
        'plate': plate,
        'photoPath': photoPath,
        'documents': [for (final d in documents) d.toJson()],
        'correctingVehicleId': correctingVehicleId,
      };

  factory VehicleDraft.fromJson(Map<String, dynamic> json) => VehicleDraft(
        vehicleTypeId: json['vehicleTypeId'] as int?,
        brand: json['brand'] as String?,
        model: json['model'] as String?,
        year: json['year'] as int?,
        color: json['color'] as String?,
        plate: json['plate'] as String?,
        photoPath: json['photoPath'] as String?,
        documents: (json['documents'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => DraftDocument.fromJson(e.cast<String, dynamic>()))
            .toList(),
        correctingVehicleId: json['correctingVehicleId'] as String?,
      );
}
