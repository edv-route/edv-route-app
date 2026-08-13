import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/brand_text_field.dart';
import '../../../../shared/widgets/password_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';
import '../../data/models/register_request.dart';
import '../../domain/entities/registration_drafts.dart';
import '../../domain/entities/requirement.dart';
import '../controllers/driver_register_controller.dart';
import '../widgets/document_draft_sheet.dart';
import '../widgets/draft_sheet_scaffold.dart';
import '../widgets/enrollment_summary_card.dart';
import '../widgets/national_id_field.dart';
import '../widgets/operator_phone_field.dart';
import '../widgets/payment_draft_sheet.dart';
import '../widgets/registration_fields.dart';
import '../widgets/vehicle_draft_sheet.dart';
import 'registration_done_screen.dart';

/// Driver self-registration wizard (4 steps: personal data, documents, vehicle,
/// payment). Steps 2/3/4 follow the admin's flow: a list of added items + an
/// "Agregar…" button that opens a modal (the draft sheets). Field rules, order and
/// formats mirror the admin panel so the client rejects bad input before the API.
class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  late final DriverRegisterController _controller =
      DriverRegisterController(Dependencies.instance.registrationRepository);

  // Step 1 — personal data (mirrors the admin person form's fields and order)
  final _step1Key = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _secondLastName = TextEditingController();
  DateTime? _birthDate;
  bool _birthDateError = false;
  String _docType = 'V';
  final _idDigits = TextEditingController();
  String _phoneOperator = kPhoneOperators.first.code;
  final _phoneNumber = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  static final _nameRegex = RegExp(r"^\p{L}+(?:[ '-]\p{L}+)*$", unicode: true);
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _secondLastName.dispose();
    _idDigits.dispose();
    _phoneNumber.dispose();
    _email.dispose();
    _address.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  void _onNext() {
    final step = _controller.step;
    if (step == 0) {
      final formOk = _step1Key.currentState?.validate() ?? false;
      final birthMissing = _birthDate == null;
      if (birthMissing) setState(() => _birthDateError = true);
      if (!formOk || birthMissing) return;
    } else if (step == 1) {
      if (!_controller.driverDocsComplete) {
        _controller.setError('Agrega la foto de cada documento requerido.');
        return;
      }
    } else if (step == 2) {
      if (!_controller.vehiclesComplete) {
        _controller.setError(
          _controller.vehicles.isEmpty
              ? 'Agrega al menos un vehículo.'
              : 'Completa los documentos requeridos de cada vehículo.',
        );
        return;
      }
    } else if (step == 3) {
      // Last step: the payment is captured in its sheet and held in the
      // controller; sending validates it is present (see _submit).
      _submit();
      return;
    }
    _controller.next();
  }

  // --- validators (step 1; mirror the backend rules) ---
  String? _validateName(String? v, {required bool required, required String field}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return required ? 'Ingresa $field.' : null;
    // Optional names (middle / second last) accept a single letter, matching the
    // backend (NAME_PATTERN has no minLength); required ones keep the 2-char floor.
    if (required && t.length < 2) return 'Debe tener entre 2 y 80 letras.';
    if (t.length > 80) return 'Máximo 80 letras.';
    if (!_nameRegex.hasMatch(t)) return 'Solo se admiten letras.';
    return null;
  }

  String? _validateId(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Ingresa tu documento.';
    if (t.length < 5 || t.length > 9) return 'El documento debe tener entre 5 y 9 dígitos.';
    return null;
  }

  String? _validatePassword(String? v) {
    final t = v ?? '';
    if (t.isEmpty) return 'Crea una clave.';
    if (t.length < 6 || t.length > 72) return 'Entre 6 y 72 caracteres.';
    return null;
  }

  String? _validatePasswordConfirm(String? v) {
    final t = v ?? '';
    if (t.isEmpty) return 'Repite tu clave.';
    if (t != _password.text) return 'Las claves no coinciden.';
    return null;
  }

  String? _validatePhone(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    if (t.length != 7) return 'El teléfono debe tener 7 dígitos (ej. 1234567).';
    return null;
  }

  String? _validateEmail(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    if (!_emailRegex.hasMatch(t)) return 'Correo inválido.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final step = _controller.step;
          return Column(
            children: [
              AuthHeader(
                showBack: true,
                title: 'Registro de conductor',
                subtitle: 'Paso ${step + 1} de ${DriverRegisterController.stepCount}',
              ),
              WizardProgressBar(step: step, total: DriverRegisterController.stepCount),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: _buildStep(step),
                ),
              ),
              _buildNav(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _buildPersonalData();
      case 1:
        return _buildDocuments();
      case 2:
        return _buildVehicles();
      default:
        return _buildPayment();
    }
  }

  // --- Step 1: personal data ---

  Widget _buildPersonalData() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrandTextField(
            label: 'Primer nombre',
            controller: _firstName,
            hintText: 'Tu primer nombre',
            textCapitalization: TextCapitalization.words,
            inputFormatters: letterInputFormatters(80),
            validator: (v) => _validateName(v, required: true, field: 'tu primer nombre'),
          ),
          const SizedBox(height: 14),
          BrandTextField(
            label: 'Segundo nombre (opcional)',
            controller: _middleName,
            hintText: 'Tu segundo nombre',
            textCapitalization: TextCapitalization.words,
            inputFormatters: letterInputFormatters(80),
            validator: (v) => _validateName(v, required: false, field: 'tu segundo nombre'),
          ),
          const SizedBox(height: 14),
          BrandTextField(
            label: 'Primer apellido',
            controller: _lastName,
            hintText: 'Tu primer apellido',
            textCapitalization: TextCapitalization.words,
            inputFormatters: letterInputFormatters(80),
            validator: (v) => _validateName(v, required: true, field: 'tu primer apellido'),
          ),
          const SizedBox(height: 14),
          BrandTextField(
            label: 'Segundo apellido (opcional)',
            controller: _secondLastName,
            hintText: 'Tu segundo apellido',
            textCapitalization: TextCapitalization.words,
            inputFormatters: letterInputFormatters(80),
            validator: (v) => _validateName(v, required: false, field: 'tu segundo apellido'),
          ),
          const SizedBox(height: 14),
          DateField(
            label: 'Fecha de nacimiento (mayor de 18)',
            value: _birthDate,
            onTap: _pickBirthDate,
            errorText: _birthDateError ? 'Selecciona tu fecha de nacimiento.' : null,
          ),
          const SizedBox(height: 14),
          NationalIdField(
            label: 'Documento de identidad',
            hintText: '12345678',
            locked: true,
            type: _docType,
            onTypeChanged: (t) => setState(() => _docType = t),
            controller: _idDigits,
            validator: _validateId,
          ),
          const SizedBox(height: 14),
          OperatorPhoneField(
            label: 'Teléfono (opcional)',
            operator: _phoneOperator,
            onOperatorChanged: (o) => setState(() => _phoneOperator = o),
            controller: _phoneNumber,
            validator: _validatePhone,
          ),
          const SizedBox(height: 14),
          BrandTextField(
            label: 'Correo (opcional)',
            controller: _email,
            hintText: 'correo@ejemplo.com',
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 14),
          BrandTextField(
            label: 'Dirección (opcional)',
            controller: _address,
            hintText: 'Tu dirección',
            inputFormatters: [LengthLimitingTextInputFormatter(500)],
          ),
          const SizedBox(height: 14),
          PasswordField(
            label: 'Crea tu clave',
            controller: _password,
            textInputAction: TextInputAction.next,
            validator: _validatePassword,
          ),
          const SizedBox(height: 14),
          PasswordField(
            label: 'Repite tu clave',
            controller: _passwordConfirm,
            validator: _validatePasswordConfirm,
          ),
          const SizedBox(height: 6),
          const Text(
            'Tu usuario será tu número de documento. Con esta clave entrarás a la '
            'app (mínimo 6 caracteres; puede ser solo números).',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final maxBirth = DateTime(now.year - 18, now.month, now.day);
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(maxBirth) ? maxBirth : initial,
      firstDate: DateTime(1920),
      lastDate: maxBirth,
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateError = false;
      });
    }
  }

  // --- Step 2: driver documents (list + Agregar → modal) ---

  Widget _buildDocuments() {
    if (_controller.loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_controller.driverRequirements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Text(
          'No se requieren documentos en este momento. Continúa al siguiente paso.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }
    final docs = _controller.driverDocs;
    final canAdd = _controller.availableDriverRequirements().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Agrega la foto de cada documento. Los marcados con * son obligatorios; los demás, opcionales.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < docs.length; i++) ...[
          DraftRow(
            icon: Icons.description_outlined,
            iconColor: AppColors.gold700,
            title: docs[i].requirementName,
            subtitle: 'Documento cargado',
            onEdit: () => _editDriverDoc(i),
            onRemove: () => _controller.removeDriverDoc(i),
          ),
          const SizedBox(height: 10),
        ],
        if (canAdd)
          AddTile(label: 'Agregar documento', onTap: _addDriverDoc)
        else
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Ya agregaste todos los documentos disponibles.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Future<void> _addDriverDoc() async {
    final available = _controller.availableDriverRequirements();
    if (available.isEmpty) return;
    final draft = await showDraftSheet<DocDraft>(
      context,
      (_) => DocumentDraftSheet(ownerLabel: 'del chofer', available: available),
    );
    if (draft != null) _controller.saveDriverDoc(draft);
  }

  Future<void> _editDriverDoc(int index) async {
    final current = _controller.driverDocs[index];
    final available = _controller.availableDriverRequirements(keepId: current.requirementId);
    final draft = await showDraftSheet<DocDraft>(
      context,
      (_) => DocumentDraftSheet(ownerLabel: 'del chofer', available: available, initial: current),
    );
    if (draft != null) _controller.saveDriverDoc(draft, editIndex: index);
  }

  // --- Step 3: vehicles (list + Agregar → modal; docs per card) ---

  Widget _buildVehicles() {
    if (_controller.loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final vehicles = _controller.vehicles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Agrega tu vehículo (uno o más) con sus documentos.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < vehicles.length; i++) ...[
          _VehicleCard(
            vehicle: vehicles[i],
            pending: _controller.pendingRequiredVehicleRequirements(i),
            canAddDoc: _controller.availableVehicleRequirements(i).isNotEmpty,
            onEdit: () => _editVehicle(i),
            onRemove: () => _controller.removeVehicle(i),
            onAddDoc: () => _addVehicleDoc(i),
            onEditDoc: (j) => _editVehicleDoc(i, j),
            onRemoveDoc: (j) => _controller.removeVehicleDoc(i, j),
          ),
          const SizedBox(height: 12),
        ],
        AddTile(label: 'Agregar vehículo', onTap: _addVehicle),
      ],
    );
  }

  Future<void> _addVehicle() async {
    final draft = await showDraftSheet<VehicleItemDraft>(
      context,
      (_) => VehicleDraftSheet(vehicleTypes: _controller.vehicleTypes),
    );
    if (draft != null) _controller.saveVehicle(draft);
  }

  Future<void> _editVehicle(int index) async {
    final draft = await showDraftSheet<VehicleItemDraft>(
      context,
      (_) => VehicleDraftSheet(vehicleTypes: _controller.vehicleTypes, initial: _controller.vehicles[index]),
    );
    if (draft != null) _controller.saveVehicle(draft, editIndex: index);
  }

  Future<void> _addVehicleDoc(int vehicleIndex) async {
    final available = _controller.availableVehicleRequirements(vehicleIndex);
    if (available.isEmpty) return;
    final draft = await showDraftSheet<DocDraft>(
      context,
      (_) => DocumentDraftSheet(ownerLabel: 'del vehículo', available: available),
    );
    if (draft != null) _controller.saveVehicleDoc(vehicleIndex, draft);
  }

  Future<void> _editVehicleDoc(int vehicleIndex, int docIndex) async {
    final current = _controller.vehicles[vehicleIndex].documents[docIndex];
    final available =
        _controller.availableVehicleRequirements(vehicleIndex, keepId: current.requirementId);
    final draft = await showDraftSheet<DocDraft>(
      context,
      (_) => DocumentDraftSheet(ownerLabel: 'del vehículo', available: available, initial: current),
    );
    if (draft != null) _controller.saveVehicleDoc(vehicleIndex, draft, editDocIndex: docIndex);
  }

  // --- Step 4: cost summary + payment (Agregar → sheet) ---

  Widget _buildPayment() {
    if (_controller.loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_controller.paymentMethods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Text(
          'No hay métodos de pago disponibles ahora. Intenta más tarde.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }
    if (!_controller.hasEnrollCost) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Text(
          'No se pudo cargar el costo del alta (membresía y tarifa). Intenta más tarde.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }
    final membership = _controller.membership!;
    final tariff = _controller.tariff!;
    final payment = _controller.payment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Revisa el total del alta y registra tu pago. Un administrador lo revisará.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        // Cost summary (membership + tariff × weeks + total), mirrors the panel.
        EnrollmentSummaryCard(
          membershipName: membership.name,
          membershipPrice: membership.priceUsd,
          tariffName: tariff.name,
          tariffPrice: tariff.priceUsd,
          periods: _controller.periods,
          total: _controller.totalUsd!,
          locked: _controller.hasPayment,
          onPeriodsChanged: _controller.setPeriods,
        ),
        const SizedBox(height: 16),
        // The payment itself: a summary row once added, else the "Agregar pago"
        // tile that opens the payment sheet (with the total pinned on top).
        if (payment != null)
          DraftRow(
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.gold700,
            title: payment.methodLabel,
            subtitle: _paymentSubtitle(payment),
            onEdit: _addPayment,
            onRemove: _controller.removePayment,
          )
        else
          AddTile(label: 'Agregar pago', onTap: _addPayment),
      ],
    );
  }

  /// One-line description of the captured payment for its summary row.
  String _paymentSubtitle(PaymentDraftItem p) {
    final parts = <String>[
      if (p.reference != null && p.reference!.isNotEmpty) 'Ref. ${p.reference}',
      if (p.payerBank != null && p.payerBank!.isNotEmpty) p.payerBank!,
    ];
    return parts.isEmpty ? 'Comprobante adjunto' : parts.join(' · ');
  }

  /// Opens the payment sheet (add or edit) and stores the captured payment.
  Future<void> _addPayment() async {
    final item = await showPaymentSheet(
      context,
      methods: _controller.paymentMethods,
      totalLabel: _controller.totalLabel,
      initial: _controller.payment,
    );
    if (item != null) _controller.savePayment(item);
  }

  // --- Submit ---

  Future<void> _submit() async {
    if (!_controller.hasPayment) {
      _controller.setError('Agrega el pago del alta para enviar la solicitud.');
      return;
    }
    final request = _buildRequest();
    final ok = await _controller.submit(request);
    if (ok && mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RegistrationDoneScreen()),
      );
    }
  }

  RegisterRequest _buildRequest() {
    return RegisterRequest(
      firstName: _titleCase(_firstName.text),
      middleName: _titleCase(_middleName.text),
      lastName: _titleCase(_lastName.text),
      secondLastName: _titleCase(_secondLastName.text),
      birthDate: _birthDate == null ? null : _formatDate(_birthDate!),
      phone: _composePersonPhone(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      nationalId: '$_docType-${_idDigits.text.trim()}',
      password: _password.text,
      documents: [
        for (final d in _controller.driverDocs) DocumentRef(requirementId: d.requirementId),
      ],
      vehicles: [
        for (final v in _controller.vehicles)
          VehicleDraft(
            vehicleTypeId: v.vehicleTypeId,
            brand: v.brand,
            model: v.model,
            year: v.year,
            color: v.color,
            plate: v.plate,
            documents: [
              for (final d in v.documents) DocumentRef(requirementId: d.requirementId),
            ],
          ),
      ],
    );
  }

  /// Composes the step-1 phone from the operator selector + a 7-digit local
  /// number into E.164 (+58 + operator + 7 digits). Returns null when blank.
  String? _composePersonPhone() {
    final local = _phoneNumber.text.trim();
    if (local.isEmpty) return null;
    if (local.length != 7) return null; // the validator already blocks submit
    return '+58$_phoneOperator$local';
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Capitalizes the first letter of each word, leaving the rest untouched (so
  /// acronyms like "BMW" survive). Empty input stays empty.
  String _titleCase(String s) => s
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  Widget _buildNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_controller.error != null) ...[
            Text(
              _controller.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              if (!_controller.isFirstStep) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _controller.submitting ? null : _controller.back,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary900,
                      side: const BorderSide(color: AppColors.fieldBorder),
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Atrás'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: PrimaryButton(
                  label: _controller.isLastStep ? 'Enviar solicitud' : 'Siguiente',
                  loading: _controller.submitting,
                  onPressed: _onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A vehicle card in step 3: the vehicle summary (Editar/Quitar) plus its
/// documents list and a per-card "Agregar documento" button — mirrors the admin's
/// wizard vehicle card.
class _VehicleCard extends StatelessWidget {
  final VehicleItemDraft vehicle;
  final List<Requirement> pending;
  final bool canAddDoc;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onAddDoc;
  final void Function(int) onEditDoc;
  final void Function(int) onRemoveDoc;

  const _VehicleCard({
    required this.vehicle,
    required this.pending,
    required this.canAddDoc,
    required this.onEdit,
    required this.onRemove,
    required this.onAddDoc,
    required this.onEditDoc,
    required this.onRemoveDoc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: vehicle.photos.isEmpty
                      ? Container(
                          color: AppColors.cardGrey,
                          child: const Icon(Icons.directions_car_outlined, color: AppColors.muted),
                        )
                      : Image.memory(
                          Uint8List.fromList(vehicle.photos.first.bytes),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (vehicle.plate.isNotEmpty) vehicle.plate,
                        '${vehicle.photos.length} foto(s)',
                        '${vehicle.documents.length} doc(s)',
                      ].join(' · '),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Vehicle actions in a kebab (⋮) menu — mirrors the admin's
              // action-menu so they don't blend with the document rows below.
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.muted),
                tooltip: 'Acciones del vehículo',
                onSelected: (v) {
                  if (v == 'edit') {
                    onEdit();
                  } else if (v == 'remove') {
                    onRemove();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar vehículo')),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Quitar vehículo', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          const Text(
            'Documentos del vehículo',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary900, fontSize: 13),
          ),
          const SizedBox(height: 8),
          for (var j = 0; j < vehicle.documents.length; j++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vehicle.documents[j].requirementName,
                      style: const TextStyle(color: AppColors.ink, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onEditDoc(j),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Editar'),
                  ),
                  TextButton(
                    onPressed: () => onRemoveDoc(j),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Quitar'),
                  ),
                ],
              ),
            ),
          if (pending.isNotEmpty) ...[
            Text(
              'Faltan: ${pending.map((r) => r.name).join(', ')}',
              style: const TextStyle(color: AppColors.gold800, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
          ],
          if (canAddDoc)
            OutlinedButton.icon(
              onPressed: onAddDoc,
              icon: const Icon(Icons.add, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.fieldBorder),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text('Agregar documento'),
            ),
        ],
      ),
    );
  }
}
