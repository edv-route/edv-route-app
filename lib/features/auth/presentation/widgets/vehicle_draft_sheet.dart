import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/brand_text_field.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/picked_image.dart';
import '../../domain/entities/registration_drafts.dart';
import '../../domain/entities/vehicle_type_option.dart';
import 'draft_sheet_scaffold.dart';
import 'media_picker.dart';
import 'registration_fields.dart';

/// Add/edit-vehicle modal for the wizard. Mirrors the admin's `vehicle-draft-modal`:
/// vehicle DATA + PHOTOS only (its documents are added from the vehicle card, so
/// they are preserved across an edit). On confirm it pops a [VehicleItemDraft].
class VehicleDraftSheet extends StatefulWidget {
  final List<VehicleTypeOption> vehicleTypes;
  final VehicleItemDraft? initial;

  const VehicleDraftSheet({super.key, required this.vehicleTypes, this.initial});

  @override
  State<VehicleDraftSheet> createState() => _VehicleDraftSheetState();
}

class _VehicleDraftSheetState extends State<VehicleDraftSheet> {
  static const int _maxPhotos = 3;
  static final _brandModelRegex =
      RegExp(r'^[\p{L}\p{N}]+(?:[ -][\p{L}\p{N}]+)*$', unicode: true);
  static final _colorRegex = RegExp(r"^\p{L}+(?:[ '-]\p{L}+)*$", unicode: true);

  final _formKey = GlobalKey<FormState>();
  int? _typeId;
  final _brand = TextEditingController();
  final _model = TextEditingController();
  int? _year;
  final _color = TextEditingController();
  final _plate = TextEditingController();
  final List<PickedImage> _photos = [];
  List<DocDraft> _documents = const [];

  @override
  void initState() {
    super.initState();
    final v = widget.initial;
    if (v != null) {
      _typeId = v.vehicleTypeId;
      _brand.text = v.brand;
      _model.text = v.model;
      _year = v.year;
      _color.text = v.color;
      _plate.text = v.plate;
      _photos.addAll(v.photos);
      _documents = v.documents;
    }
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _color.dispose();
    _plate.dispose();
    super.dispose();
  }

  String? _typeName(int? id) {
    if (id == null) return null;
    for (final t in widget.vehicleTypes) {
      if (t.id == id) return t.name;
    }
    return null;
  }

  List<int> _years() {
    final top = DateTime.now().year + 1;
    return [for (var y = top; y >= top - 101; y--) y];
  }

  Future<void> _pickType() async {
    final chosen = await pickFromSheet<VehicleTypeOption>(
      context,
      title: 'Tipo de vehículo',
      items: widget.vehicleTypes,
      labelOf: (t) => t.name,
    );
    if (chosen != null) setState(() => _typeId = chosen.id);
  }

  Future<void> _pickYear() async {
    final chosen = await pickFromSheet<int>(
      context,
      title: 'Año del vehículo',
      items: _years(),
      labelOf: (y) => '$y',
    );
    if (chosen != null) setState(() => _year = chosen);
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= _maxPhotos) return;
    final img = await pickPhoto(context);
    if (img != null) setState(() => _photos.add(img));
  }

  String? _validateBrandModel(String? v, String field) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Ingresa $field.';
    if (t.length > 60) return 'Máximo 60 caracteres.';
    if (!_brandModelRegex.hasMatch(t)) return 'Solo letras, números, espacio y guion.';
    return null;
  }

  String? _validateColor(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    if (t.length > 30) return 'Máximo 30 letras.';
    if (!_colorRegex.hasMatch(t)) return 'Solo letras.';
    return null;
  }

  String? _validatePlate(String? v) {
    final t = (v ?? '').trim().toUpperCase();
    if (t.isEmpty) return 'Ingresa la placa.';
    // 5-15 alphanumeric: aligns with the backend cap (max 15) so valid VE plates
    // (moto/auto formats longer than 8) are not rejected client-side.
    if (!RegExp(r'^[A-Z0-9]{5,15}$').hasMatch(t)) return 'Placa inválida (5 a 15 letras/números).';
    return null;
  }

  String _titleCase(String s) => s
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  void _confirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      VehicleItemDraft(
        vehicleTypeId: _typeId,
        vehicleTypeName: _typeName(_typeId),
        brand: _titleCase(_brand.text),
        model: _titleCase(_model.text),
        year: _year,
        color: _titleCase(_color.text),
        plate: _plate.text.trim().toUpperCase(),
        photos: List.of(_photos),
        documents: _documents,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return DraftSheetScaffold(
      title: editing ? 'Editar vehículo' : 'Agregar vehículo',
      subtitle: 'Datos y fotos del vehículo',
      confirmLabel: editing ? 'Guardar' : 'Agregar vehículo',
      canConfirm: true,
      onConfirm: _confirm,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.vehicleTypes.isNotEmpty) ...[
              PickerField(
                label: 'Tipo de vehículo (opcional)',
                value: _typeName(_typeId),
                hint: 'Selecciona el tipo',
                onTap: _pickType,
              ),
              const SizedBox(height: 14),
            ],
            BrandTextField(
              label: 'Marca',
              controller: _brand,
              hintText: 'Ej. Toyota',
              textCapitalization: TextCapitalization.words,
              inputFormatters: alnumDashInputFormatters(60),
              validator: (v) => _validateBrandModel(v, 'la marca'),
            ),
            const SizedBox(height: 14),
            BrandTextField(
              label: 'Modelo',
              controller: _model,
              hintText: 'Ej. Corolla',
              textCapitalization: TextCapitalization.words,
              inputFormatters: alnumDashInputFormatters(60),
              validator: (v) => _validateBrandModel(v, 'el modelo'),
            ),
            const SizedBox(height: 14),
            PickerField(
              label: 'Año (opcional)',
              value: _year?.toString(),
              hint: 'Selecciona el año',
              onTap: _pickYear,
            ),
            const SizedBox(height: 14),
            BrandTextField(
              label: 'Color (opcional)',
              controller: _color,
              hintText: 'Ej. Blanco',
              textCapitalization: TextCapitalization.words,
              inputFormatters: letterInputFormatters(30),
              validator: _validateColor,
            ),
            const SizedBox(height: 14),
            BrandTextField(
              label: 'Placa',
              controller: _plate,
              hintText: 'Ej. AB123CD',
              textInputAction: TextInputAction.done,
              inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(15)],
              validator: _validatePlate,
            ),
            const SizedBox(height: 18),
            Text(
              'Fotos del vehículo (opcional, hasta $_maxPhotos)',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary900),
            ),
            const SizedBox(height: 12),
            PhotoGrid(
              photos: _photos,
              canAdd: _photos.length < _maxPhotos,
              onAdd: _addPhoto,
              onRemove: (i) => setState(() => _photos.removeAt(i)),
            ),
          ],
        ),
      ),
    );
  }
}
