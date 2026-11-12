import '../entities/identity.dart';
import '../entities/picked_image.dart';

/// The person's identity photos. ONE contract for both apps (affiliate and
/// passenger) — the photos belong to the person — with one implementation per
/// channel, each talking to its own session and endpoints.
abstract interface class IdentityRepository {
  /// Current photos and the overall status.
  Future<IdentityView> load();

  /// Sends one photo. Allowed only for an empty or rejected slot; the server
  /// answers with the updated view.
  Future<IdentityView> upload(IdentityKind kind, PickedImage image);
}
