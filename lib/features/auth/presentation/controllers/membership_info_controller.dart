import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/enrollment_cost.dart';
import '../../domain/repositories/registration_repository.dart';

/// Loads the active membership + its benefits for the informational pre-screen
/// (the first step of the join flow). Exposes loading / error / data to the UI.
class MembershipInfoController extends ChangeNotifier {
  MembershipInfoController(this._repository);

  final RegistrationRepository _repository;

  bool _loading = true;
  String? _error;
  MembershipInfo? _membership;

  bool get loading => _loading;
  String? get error => _error;
  MembershipInfo? get membership => _membership;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _membership = await _repository.loadMembership();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo cargar la información. Intenta de nuevo.';
    }
    _loading = false;
    notifyListeners();
  }
}
