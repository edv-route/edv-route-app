import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/vehicle_draft.dart';
import '../../../../domain/entities/vehicle_type_option.dart';
import '../../../../shared/widgets/brand_text_field.dart';
import '../../../../shared/widgets/registration_fields.dart';
import '../../../../theme/app_colors.dart';

/// The vehicle's data inside the draft screen.
///
/// Unlike the sheet it replaces, this does not "confirm" anything: every key
/// press goes straight into the draft, which is saved on the phone. There is no
/// Save button because there is nothing to save to — the vehicle does not exist
/// anywhere else until it is sent.
class VehicleDraftForm extends StatefulWidget {
  final VehicleDraft draft;
  final List<VehicleTypeOption> vehicleTypes;
  final void Function({
    int? vehicleTypeId,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? plate,
  }) onChanged;

  const VehicleDraftForm({
    super.key,
    required this.draft,
    required this.vehicleTypes,
    required this.onChanged,
  });

  @override
  State<VehicleDraftForm> createState() => _VehicleDraftFormState();
}

class _VehicleDraftFormState extends State<VehicleDraftForm> {
  static final _brandModelRegex =
      RegExp(r'^[\p{L}\p{N}]+(?:[ -][\p{L}\p{N}]+)*$', unicode: true);
  static final _colorRegex = RegExp(r"^\p{L}+(?:[ '-]\p{L}+)*$", unicode: true);

  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _color;
  late final TextEditingController _plate;

  @override
  void initState() {
    super.initState();
    _brand = TextEditingController(text: widget.draft.brand ?? '');
    _model = TextEditingController(text: widget.draft.model ?? '');
    _color = TextEditingController(text: widget.draft.color ?? '');
    _plate = TextEditingController(text: widget.draft.plate ?? '');
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

  Future<void> _pickType() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final t in widget.vehicleTypes)
              ListTile(
                title: Text(t.name),
                trailing: t.id == widget.draft.vehicleTypeId
                    ? const Icon(Icons.check, size: 18)
                    : null,
                onTap: () => Navigator.pop(ctx, t.id),
              ),
          ],
        ),
      ),
    );
    if (selected != null) widget.onChanged(vehicleTypeId: selected);
  }

  /// Year picker as a WHEEL, from the current year back to 1900.
  ///
  /// A plain list was unusable: it opened on a wall of identical rows with no
  /// title, and a Venezuelan fleet has plenty of 80s and 90s vehicles — reaching
  /// 1987 meant scrolling forever. The wheel opens ON the year already chosen
  /// (or the current one) and moves decades in one flick.
  Future<void> _pickYear() async {
    final currentYear = DateTime.now().year;
    const firstYear = 1900;
    final years = [for (var y = currentYear; y >= firstYear; y--) y];
    final initial = years.indexOf(widget.draft.year ?? currentYear);

    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _YearWheel(
        years: years,
        initialIndex: initial < 0 ? 0 : initial,
      ),
    );
    if (selected != null) widget.onChanged(year: selected);
  }

  String? _validateBrandModel(String? v, String field) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null; // optional in the draft; the plate is what identifies it
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
    // 5-15 alphanumeric: matches the backend cap so a valid Venezuelan plate
    // (motorbike formats run longer than 8) is not rejected on the phone.
    if (!RegExp(r'^[A-Z0-9]{5,15}$').hasMatch(t)) {
      return 'Placa inválida (5 a 15 letras/números).';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.vehicleTypes.isNotEmpty) ...[
          PickerField(
            label: 'Tipo de vehículo',
            value: _typeName(widget.draft.vehicleTypeId),
            hint: 'Selecciona el tipo',
            onTap: _pickType,
          ),
          const SizedBox(height: 14),
        ],
        BrandTextField(
          label: 'Placa',
          controller: _plate,
          hintText: 'Ej. AB123CD',
          inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(15)],
          validator: _validatePlate,
          onChanged: (v) => widget.onChanged(plate: v.trim().toUpperCase()),
        ),
        const SizedBox(height: 14),
        BrandTextField(
          label: 'Marca',
          controller: _brand,
          hintText: 'Ej. Toyota',
          textCapitalization: TextCapitalization.words,
          inputFormatters: alnumDashInputFormatters(60),
          validator: (v) => _validateBrandModel(v, 'la marca'),
          onChanged: (v) => widget.onChanged(brand: v.trim()),
        ),
        const SizedBox(height: 14),
        BrandTextField(
          label: 'Modelo',
          controller: _model,
          hintText: 'Ej. Corolla',
          textCapitalization: TextCapitalization.words,
          inputFormatters: alnumDashInputFormatters(60),
          validator: (v) => _validateBrandModel(v, 'el modelo'),
          onChanged: (v) => widget.onChanged(model: v.trim()),
        ),
        const SizedBox(height: 14),
        PickerField(
          label: 'Año (opcional)',
          value: widget.draft.year?.toString(),
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
          onChanged: (v) => widget.onChanged(color: v.trim()),
        ),
      ],
    );
  }
}

/// The year wheel itself: a titled sheet with the selection framed in the
/// middle, so what is being chosen is obvious without hunting for a check mark
/// on the right edge.
class _YearWheel extends StatefulWidget {
  final List<int> years;
  final int initialIndex;

  const _YearWheel({required this.years, required this.initialIndex});

  @override
  State<_YearWheel> createState() => _YearWheelState();
}

class _YearWheelState extends State<_YearWheel> {
  late final FixedExtentScrollController _wheel =
      FixedExtentScrollController(initialItem: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardGrey,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Icon(Icons.event_outlined, size: 20, color: AppColors.primary700),
                  SizedBox(width: 8),
                  Text(
                    'Año del vehículo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The frame marks the selected row; the wheel scrolls behind it.
                  Container(
                    height: 42,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary200),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    controller: _wheel,
                    itemExtent: 42,
                    perspective: 0.002,
                    diameterRatio: 1.6,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => setState(() => _index = i),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: widget.years.length,
                      builder: (context, i) {
                        final selected = i == _index;
                        return Center(
                          child: Text(
                            '${widget.years[i]}',
                            style: TextStyle(
                              fontSize: selected ? 21 : 18,
                              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                              color: selected ? AppColors.primary900 : AppColors.muted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.muted,
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, widget.years[_index]),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Listo',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
