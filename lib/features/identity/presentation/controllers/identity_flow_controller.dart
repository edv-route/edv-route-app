import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../domain/entities/identity.dart';
import '../../../../domain/entities/picked_image.dart';
import '../../../../domain/repositories/identity_repository.dart';

/// What one slot shows.
enum SlotState { empty, captured, inReview, approved, rejected }

/// Drives the three identity photos, in BOTH situations the app meets them:
///
/// - **Registration** ([createAccount] given): the photos are taken before the
///   account exists and held on the phone; "Crear" creates the account first
///   and then sends them. If the account is created but a photo fails, a retry
///   sends only what is missing — it never registers twice.
/// - **Existing account** (no [createAccount]): the server already knows what
///   was sent; only empty or rejected slots take a new photo.
class IdentityFlowController extends ChangeNotifier {
  IdentityFlowController({
    required IdentityRepository repository,
    Future<void> Function()? createAccount,
    IdentityView initial = IdentityView.empty,
  })  : _repository = repository,
        _createAccount = createAccount,
        _view = initial;

  final IdentityRepository _repository;
  final Future<void> Function()? _createAccount;

  IdentityView _view;
  final Map<IdentityKind, PickedImage> _captured = {};
  bool _loading = false;
  bool _submitting = false;
  bool _accountCreated = false;
  String? _error;

  IdentityView get view => _view;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;

  /// True once the registration created the account: the form behind this
  /// screen must not be submitted again.
  bool get accountCreated => _accountCreated;

  PickedImage? capturedFor(IdentityKind kind) => _captured[kind];

  SlotState slotOf(IdentityKind kind) {
    if (_captured.containsKey(kind)) return SlotState.captured;
    final photo = _view.photos[kind];
    if (photo == null) return SlotState.empty;
    return switch (photo.status) {
      IdentityPhotoStatus.pending => SlotState.inReview,
      IdentityPhotoStatus.approved => SlotState.approved,
      IdentityPhotoStatus.rejected => SlotState.rejected,
    };
  }

  /// Slots that still need a photo from the person before sending.
  List<IdentityKind> get stillNeeded => [
        for (final k in IdentityKind.values)
          if (_view.canTake(k) && !_captured.containsKey(k)) k,
      ];

  /// Ready when every slot is either sent (in review/approved) or captured,
  /// and there is something new to send.
  bool get canSubmit => !_submitting && stillNeeded.isEmpty && _captured.isNotEmpty;

  /// Existing account: what the server holds right now.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _view = await _repository.load();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No pudimos cargar tus fotos. Revisa tu conexión.';
    }
    _loading = false;
    notifyListeners();
  }

  void capture(IdentityKind kind, PickedImage image) {
    if (!_view.canTake(kind)) return;
    _captured[kind] = image;
    _error = null;
    notifyListeners();
  }

  /// Sends what was captured (creating the account first when registering).
  /// Returns true when nothing is left to send.
  Future<bool> submit() async {
    if (!canSubmit) return false;
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      final create = _createAccount;
      if (create != null && !_accountCreated) {
        await create();
        _accountCreated = true;
      }
      for (final kind in IdentityKind.values) {
        final image = _captured[kind];
        if (image == null) continue;
        _view = await _repository.upload(kind, image);
        _captured.remove(kind);
      }
      _submitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      await _reconcile();
      _fail(e.message);
    } catch (_) {
      await _reconcile();
      _fail('No pudimos enviar tus fotos. Revisa tu conexión e inténtalo de nuevo.');
    }
    return _captured.isEmpty && _accountCreated == (_createAccount != null);
  }

  /// After a failed send, asks the server what actually arrived: an upload
  /// whose answer was lost must not be sent again (the server would refuse it
  /// as "en revisión" and the person would be stuck).
  Future<void> _reconcile() async {
    if (_createAccount != null && !_accountCreated) return; // no account yet
    try {
      _view = await _repository.load();
      _captured.removeWhere((kind, _) => !_view.canTake(kind));
    } catch (_) {
      // Keep what we have; the next attempt will try again.
    }
  }

  void _fail(String message) {
    _error = _accountCreated && _createAccount != null
        ? 'Tu cuenta ya se creó, pero faltan fotos por enviar: $message'
        : message;
    _submitting = false;
    notifyListeners();
  }
}
