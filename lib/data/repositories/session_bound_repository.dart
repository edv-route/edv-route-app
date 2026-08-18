import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../domain/entities/picked_image.dart';

/// Shared plumbing for the repositories whose endpoints need the driver's
/// session: reading the token and turning a picked photo into an upload part.
/// It exists so splitting the old god-repository did not mean copying these
/// four lines into three files.
abstract class SessionBoundRepository {
  const SessionBoundRepository(this.tokenStorage);

  final TokenStorage tokenStorage;

  /// The stored session token, or a clear error when there is none.
  Future<String> requireToken() async {
    final token = await tokenStorage.readToken();
    if (token == null) {
      throw const ApiException('Sesión no iniciada. Vuelve a empezar el registro.');
    }
    return token;
  }

  /// The picked image as the multipart field every upload endpoint expects.
  MultipartPart part(PickedImage image) =>
      MultipartPart(field: 'file', bytes: image.bytes, filename: image.filename);
}
