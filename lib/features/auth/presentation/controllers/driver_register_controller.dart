import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/register_request.dart';
import '../../domain/entities/enrollment_cost.dart';
import '../../domain/entities/payment_method_option.dart';
import '../../domain/entities/registration_drafts.dart';
import '../../domain/entities/requirement.dart';
import '../../domain/entities/vehicle_type_option.dart';
import '../../domain/repositories/registration_repository.dart';

/// Owns the driver registration wizard: step navigation, the catalogs loaded from
/// the backend, and the drafts accumulated across the four steps — a list of
/// driver documents, a list of vehicles (each with its own photos and documents)
/// and one payment. Steps 2/3/4 follow the admin's "list + add → modal" pattern,
/// so everything here is a list the screen renders and the modals feed.
class DriverRegisterController extends ChangeNotifier {
  DriverRegisterController(this._repository);

  final RegistrationRepository _repository;

  static const int stepCount = 4;

  int _step = 0;
  bool _loading = false; // catalogs loading
  bool _submitting = false; // final submit in progress
  String? _error;

  List<Requirement> _driverRequirements = const [];
  List<Requirement> _vehicleRequirements = const [];
  List<PaymentMethodOption> _paymentMethods = const [];
  List<VehicleTypeOption> _vehicleTypes = const [];

  // Step 4 cost catalog (membership + weekly tariff) and the number of prepaid
  // weeks. The alta charges membership + tariff × periods, computed server-side;
  // these mirror it for the on-screen summary. Tariff is weekly-only for now.
  MembershipInfo? _membership;
  TariffPlan? _tariff;
  int _periods = 1;

  final List<DocDraft> _driverDocs = []; // step 2
  final List<VehicleItemDraft> _vehicles = []; // step 3
  PaymentDraftItem? _payment; // step 4

  int get step => _step;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  bool get isFirstStep => _step == 0;
  bool get isLastStep => _step == stepCount - 1;

  List<Requirement> get driverRequirements => _driverRequirements;
  List<Requirement> get vehicleRequirements => _vehicleRequirements;
  List<PaymentMethodOption> get paymentMethods => _paymentMethods;
  List<VehicleTypeOption> get vehicleTypes => _vehicleTypes;

  List<DocDraft> get driverDocs => List.unmodifiable(_driverDocs);
  List<VehicleItemDraft> get vehicles => List.unmodifiable(_vehicles);
  PaymentDraftItem? get payment => _payment;

  MembershipInfo? get membership => _membership;
  TariffPlan? get tariff => _tariff;
  int get periods => _periods;

  /// Whether the alta cost is known (membership + weekly tariff both loaded).
  /// The payment step needs it to show the total and to be payable.
  bool get hasEnrollCost => _membership != null && _tariff != null;

  /// Total to charge: membership + tariff × weeks. Null until the cost loads.
  double? get totalUsd =>
      hasEnrollCost ? _membership!.priceUsd + _tariff!.priceUsd * _periods : null;

  /// "$185.00" for the summary / payment sheet header, or null when unknown.
  String? get totalLabel {
    final t = totalUsd;
    return t == null ? null : '\$${t.toStringAsFixed(2)}';
  }

  /// Step 2 done: every REQUIRED driver requirement is covered by a document
  /// (optional ones are offered but never block advancing).
  bool get driverDocsComplete {
    final have = _driverDocs.map((d) => d.requirementId).toSet();
    return _driverRequirements.where((r) => r.isRequired).every((r) => have.contains(r.id));
  }

  /// Step 3 done: at least one vehicle, and each vehicle covers all its REQUIRED
  /// documents (optional ones don't block).
  bool get vehiclesComplete {
    if (_vehicles.isEmpty) return false;
    for (final v in _vehicles) {
      final have = v.documents.map((d) => d.requirementId).toSet();
      if (!_vehicleRequirements.where((r) => r.isRequired).every((r) => have.contains(r.id))) {
        return false;
      }
    }
    return true;
  }

  bool get hasPayment => _payment != null;

  /// Required driver requirements still selectable (not already added); [keepId]
  /// keeps the one being edited in the list.
  List<Requirement> availableDriverRequirements({int? keepId}) {
    final used = _driverDocs.map((d) => d.requirementId).toSet();
    return _driverRequirements.where((r) => r.id == keepId || !used.contains(r.id)).toList();
  }

  /// Documents (required + optional) still selectable for the given vehicle.
  List<Requirement> availableVehicleRequirements(int vehicleIndex, {int? keepId}) {
    if (vehicleIndex < 0 || vehicleIndex >= _vehicles.length) return const [];
    final used = _vehicles[vehicleIndex].documents.map((d) => d.requirementId).toSet();
    return _vehicleRequirements.where((r) => r.id == keepId || !used.contains(r.id)).toList();
  }

  /// Required vehicle documents still missing (drives the "Faltan…" hint); optional
  /// ones are offered but never counted as missing.
  List<Requirement> pendingRequiredVehicleRequirements(int vehicleIndex) {
    if (vehicleIndex < 0 || vehicleIndex >= _vehicles.length) return const [];
    final have = _vehicles[vehicleIndex].documents.map((d) => d.requirementId).toSet();
    return _vehicleRequirements.where((r) => r.isRequired && !have.contains(r.id)).toList();
  }

  /// Loads the catalogs (requirements + payment methods + vehicle types) once.
  Future<void> init() async {
    if (_driverRequirements.isNotEmpty || _paymentMethods.isNotEmpty) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final reqs = await _repository.loadRequirements();
      // Offer every active requirement (required + optional), like the admin; the
      // required/optional split is enforced by the completeness getters below.
      _driverRequirements = reqs.where((r) => r.isDriver).toList();
      _vehicleRequirements = reqs.where((r) => r.isVehicle).toList();
      _paymentMethods = await _repository.loadPaymentMethods();
      // Vehicle types are an optional field; a failure (e.g. the endpoint not yet
      // deployed) must not block registration — degrade to an empty selector.
      try {
        _vehicleTypes = await _repository.loadVehicleTypes();
      } catch (_) {
        _vehicleTypes = const [];
      }
      // Enrollment cost (membership + weekly tariff) for the payment summary. A
      // failure must not crash the wizard; the payment step shows a notice and
      // blocks paying until the cost is available (hasEnrollCost is false).
      try {
        _membership = await _repository.loadMembership();
        _tariff = _pickWeekly(await _repository.loadPlans());
      } catch (_) {
        _membership = null;
        _tariff = null;
      }
      _loading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('No se pudieron cargar los datos. Revisa tu conexión.');
    }
  }

  // --- Step 2: driver documents ---

  void saveDriverDoc(DocDraft draft, {int? editIndex}) {
    if (editIndex != null && editIndex >= 0 && editIndex < _driverDocs.length) {
      _driverDocs[editIndex] = draft;
    } else {
      _driverDocs.add(draft);
    }
    _error = null;
    notifyListeners();
  }

  void removeDriverDoc(int index) {
    if (index >= 0 && index < _driverDocs.length) {
      _driverDocs.removeAt(index);
      notifyListeners();
    }
  }

  // --- Step 3: vehicles + their documents ---

  void saveVehicle(VehicleItemDraft draft, {int? editIndex}) {
    if (editIndex != null && editIndex >= 0 && editIndex < _vehicles.length) {
      _vehicles[editIndex] = draft;
    } else {
      _vehicles.add(draft);
    }
    _error = null;
    notifyListeners();
  }

  void removeVehicle(int index) {
    if (index >= 0 && index < _vehicles.length) {
      _vehicles.removeAt(index);
      notifyListeners();
    }
  }

  void saveVehicleDoc(int vehicleIndex, DocDraft draft, {int? editDocIndex}) {
    if (vehicleIndex < 0 || vehicleIndex >= _vehicles.length) return;
    final v = _vehicles[vehicleIndex];
    final docs = List<DocDraft>.of(v.documents);
    if (editDocIndex != null && editDocIndex >= 0 && editDocIndex < docs.length) {
      docs[editDocIndex] = draft;
    } else {
      docs.add(draft);
    }
    _vehicles[vehicleIndex] = v.copyWith(documents: docs);
    _error = null;
    notifyListeners();
  }

  void removeVehicleDoc(int vehicleIndex, int docIndex) {
    if (vehicleIndex < 0 || vehicleIndex >= _vehicles.length) return;
    final v = _vehicles[vehicleIndex];
    final docs = List<DocDraft>.of(v.documents);
    if (docIndex < 0 || docIndex >= docs.length) return;
    docs.removeAt(docIndex);
    _vehicles[vehicleIndex] = v.copyWith(documents: docs);
    notifyListeners();
  }

  // --- Step 4: payment ---

  /// Picks the weekly tariff (the one the alta charges); falls back to the first
  /// active plan if none is weekly, or null when there are no plans.
  TariffPlan? _pickWeekly(List<TariffPlan> plans) {
    for (final p in plans) {
      if (p.billingPeriod == 'weekly') return p;
    }
    return plans.isEmpty ? null : plans.first;
  }

  /// Number of prepaid tariff weeks the alta covers (1 = base, N = advance).
  /// Clamped to [1, 999], mirroring the panel.
  void setPeriods(int value) {
    final v = value < 1 ? 1 : (value > 999 ? 999 : value);
    if (v == _periods) return;
    _periods = v;
    _error = null;
    notifyListeners();
  }

  void savePayment(PaymentDraftItem draft) {
    _payment = draft;
    _error = null;
    notifyListeners();
  }

  void removePayment() {
    _payment = null;
    notifyListeners();
  }

  // --- Navigation ---

  void next() {
    if (_step < stepCount - 1) {
      _step++;
      _error = null;
      notifyListeners();
    }
  }

  void back() {
    if (_step > 0) {
      _step--;
      _error = null;
      notifyListeners();
    }
  }

  void setError(String message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Runs the full submit: register (metadata) → upload driver docs → per vehicle
  /// upload its docs + photos → submit payment. Files are matched to the ids the
  /// backend returns BY ORDER — [request]'s `documents[]`/`vehicles[]` are built
  /// from the same lists, in the same order, used here. Returns true on success.
  Future<bool> submit(RegisterRequest request) async {
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repository.register(request);

      for (var i = 0; i < _driverDocs.length; i++) {
        if (i < result.createdDocumentIds.length) {
          await _repository.uploadDocument(result.createdDocumentIds[i], _driverDocs[i].image);
        }
      }

      for (var i = 0; i < _vehicles.length; i++) {
        if (i >= result.createdVehicles.length) break;
        final created = result.createdVehicles[i];
        final v = _vehicles[i];
        for (var j = 0; j < v.documents.length; j++) {
          if (j < created.documentIds.length) {
            await _repository.uploadDocument(created.documentIds[j], v.documents[j].image);
          }
        }
        for (final photo in v.photos) {
          await _repository.uploadVehicleImage(created.id, photo);
        }
      }

      final p = _payment;
      if (p != null) {
        await _repository.submitPayment(
          PaymentCapture(
            paymentMethodId: p.paymentMethodId,
            reference: p.reference,
            payerBank: p.payerBank,
            paidOn: p.paidOn,
            payerPhone: p.payerPhone,
            payerId: p.payerId,
            payerAccount: p.payerAccount,
            receipt: p.receipt,
          ),
          periods: _periods,
        );
      }

      _submitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _failSubmit(e.message);
      return false;
    } catch (_) {
      _failSubmit('No se pudo completar el registro. Intenta de nuevo.');
      return false;
    }
  }

  void _fail(String message) {
    _error = message;
    _loading = false;
    notifyListeners();
  }

  void _failSubmit(String message) {
    _error = message;
    _submitting = false;
    notifyListeners();
  }
}
