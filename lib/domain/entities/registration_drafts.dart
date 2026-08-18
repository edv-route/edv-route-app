import './picked_image.dart';

/// A driver- or vehicle-document captured in the registration wizard: the
/// requirement it satisfies plus its photo/PDF. Unlike the admin (where the file
/// is optional), the app always captures the file — the whole point is the photo.
class DocDraft {
  final int requirementId;
  final String requirementName;
  final PickedImage image;

  const DocDraft({
    required this.requirementId,
    required this.requirementName,
    required this.image,
  });
}

/// A vehicle accumulated in the wizard: its data, its photos and its documents.
/// Built in the vehicle modal (data + photos); its documents are added from the
/// vehicle card afterwards — the same split as the admin's `vehicle-draft-modal`.
class VehicleItemDraft {
  final int? vehicleTypeId;
  final String? vehicleTypeName;
  final String brand;
  final String model;
  final int? year;
  final String color;
  final String plate;
  final List<PickedImage> photos;
  final List<DocDraft> documents;

  const VehicleItemDraft({
    this.vehicleTypeId,
    this.vehicleTypeName,
    required this.brand,
    required this.model,
    this.year,
    required this.color,
    required this.plate,
    this.photos = const [],
    this.documents = const [],
  });

  /// A short one-line label for the card: "Tipo · Marca Modelo".
  String get title {
    final parts = <String>[
      if (vehicleTypeName != null && vehicleTypeName!.isNotEmpty) vehicleTypeName!,
      [brand, model].where((s) => s.isNotEmpty).join(' '),
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? 'Vehículo' : parts.join(' · ');
  }

  VehicleItemDraft copyWith({List<DocDraft>? documents}) => VehicleItemDraft(
        vehicleTypeId: vehicleTypeId,
        vehicleTypeName: vehicleTypeName,
        brand: brand,
        model: model,
        year: year,
        color: color,
        plate: plate,
        photos: photos,
        documents: documents ?? this.documents,
      );
}

/// A payment captured in the wizard: the method + payer metadata + one receipt.
/// [methodLabel] is kept so the summary card can show the method without a lookup.
class PaymentDraftItem {
  final int paymentMethodId;
  final String methodLabel;
  final String? reference;
  final String? payerBank;
  final String paidOn; // ISO yyyy-MM-dd
  final String? payerPhone;
  final String? payerId;
  final String? payerAccount;
  final PickedImage receipt;

  const PaymentDraftItem({
    required this.paymentMethodId,
    required this.methodLabel,
    this.reference,
    this.payerBank,
    required this.paidOn,
    this.payerPhone,
    this.payerId,
    this.payerAccount,
    required this.receipt,
  });
}
