import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/domain/entities/account_status.dart';
import '../../../auth/domain/entities/alta_debt.dart';
import '../../../auth/domain/entities/enrollment_cost.dart';
import '../../../auth/domain/entities/picked_image.dart';
import '../../../auth/domain/repositories/registration_repository.dart';

/// Loads the operating driver's account data for the profile tab: the debt
/// breakdown (GET /me/debt), the account standing (GET /me/account) and the
/// membership benefits (GET /membership). It also owns the profile photo upload,
/// so the screen stays free of network work.
/// The documents/vehicles sections are driven separately by a ChecklistController.
class ProfileController extends ChangeNotifier {
  ProfileController(this._repository);

  final RegistrationRepository _repository;

  bool _loading = true;
  String? _error;
  AltaDebt? _debt;
  AccountStatus? _account;
  MembershipInfo? _membership;
  bool _uploadingPhoto = false;

  bool get loading => _loading;
  String? get error => _error;
  AltaDebt? get debt => _debt;
  AccountStatus? get account => _account;
  MembershipInfo? get membership => _membership;
  bool get uploadingPhoto => _uploadingPhoto;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _debt = await _repository.loadDebt();
      // Standing and benefits are extra detail on top of the debt: if either
      // fails the account card still renders what it owes, which is the part
      // the driver acts on.
      try {
        _account = await _repository.loadAccount();
      } catch (_) {
        _account = null;
      }
      try {
        _membership = await _repository.loadMembership();
      } catch (_) {
        _membership = null;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo cargar tu cuenta. Intenta de nuevo.';
    }
    _loading = false;
    notifyListeners();
  }

  /// Uploads the new profile photo and returns its signed URL, or throws an
  /// [ApiException] with the backend's message for the screen to show.
  Future<String?> uploadPhoto(PickedImage image) async {
    _uploadingPhoto = true;
    notifyListeners();
    try {
      return await _repository.uploadProfilePhoto(image);
    } finally {
      _uploadingPhoto = false;
      notifyListeners();
    }
  }
}
