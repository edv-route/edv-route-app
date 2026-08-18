import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../domain/entities/alta_debt.dart';
import '../../../../domain/entities/payment_method_option.dart';
import '../../../../domain/repositories/registration_repository.dart';

/// Drives the deferred alta payment screen: loads the driver's debt (and the
/// payment methods when there is something to pay) and submits the payment
/// (purpose=`debt`) with the terms acceptance. Left pending for admin review.
class AltaPaymentController extends ChangeNotifier {
  AltaPaymentController(this._repository);

  final RegistrationRepository _repository;

  bool _loading = true;
  String? _error;
  AltaDebt? _debt;
  List<PaymentMethodOption> _methods = const [];
  bool _submitting = false;
  bool _submitted = false;

  bool get loading => _loading;
  String? get error => _error;
  AltaDebt? get debt => _debt;
  List<PaymentMethodOption> get methods => _methods;
  bool get submitting => _submitting;
  bool get submitted => _submitted;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final debt = await _repository.loadDebt();
      _debt = debt;
      if (debt.hasDebt && !debt.hasPendingPayment && _methods.isEmpty) {
        _methods = await _repository.loadPaymentMethods();
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo cargar tu pago. Intenta de nuevo.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> submit(PaymentCapture capture, {required bool acceptedTerms, int weeks = 1}) async {
    if (_submitting) return false;
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.submitPayment(capture, acceptedTerms: acceptedTerms, weeks: weeks);
      _submitted = true;
      _submitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo registrar el pago. Intenta de nuevo.';
    }
    _submitting = false;
    notifyListeners();
    return false;
  }
}
