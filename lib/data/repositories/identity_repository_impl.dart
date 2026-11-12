import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../domain/entities/identity.dart';
import '../../domain/entities/picked_image.dart';
import '../../domain/repositories/identity_repository.dart';
import 'session_bound_repository.dart';

/// `/driver-auth/me/identity` or `/client-auth/me/identity`, with that
/// channel's own session. The same server routes are mounted under both
/// prefixes: only the token kind changes.
class IdentityRepositoryImpl extends SessionBoundRepository implements IdentityRepository {
  const IdentityRepositoryImpl(this._client, TokenStorage tokenStorage, {required this.prefix})
      : super(tokenStorage);

  final ApiClient _client;

  /// `/driver-auth` or `/client-auth`.
  final String prefix;

  @override
  Future<IdentityView> load() async =>
      IdentityView.fromJson(await _client.get('$prefix/me/identity', token: await requireToken()));

  @override
  Future<IdentityView> upload(IdentityKind kind, PickedImage image) async {
    final json = await _client.postMultipart(
      '$prefix/me/identity/${kind.apiValue}',
      files: [part(image)],
      token: await requireToken(),
    );
    return IdentityView.fromJson(json);
  }
}
