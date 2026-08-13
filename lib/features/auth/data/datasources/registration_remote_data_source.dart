import '../../../../core/network/api_client.dart';

/// Raw registration API calls for the driver app: the catalogs (public), the
/// alta (JSON), and the file uploads + payment submission (multipart, bearer).
class RegistrationRemoteDataSource {
  RegistrationRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<dynamic>> requirements() => _client.getList('/driver-auth/requirements');

  Future<List<dynamic>> paymentMethods() => _client.getList('/driver-auth/payment-methods');

  Future<List<dynamic>> vehicleTypes() => _client.getList('/driver-auth/vehicle-types');

  /// Current active membership (name + price), or an empty map when none exists.
  Future<Map<String, dynamic>> membership() => _client.get('/driver-auth/membership');

  /// Active tariffs (the app charges the weekly one at the alta).
  Future<List<dynamic>> subscriptionPlans() => _client.getList('/driver-auth/subscription-plans');

  Future<Map<String, dynamic>> register(Map<String, dynamic> body) =>
      _client.post('/driver-auth/register', body);

  Future<void> uploadDocumentFile(String documentId, MultipartPart file, {required String token}) =>
      _client.postMultipart('/driver-auth/documents/$documentId/file', files: [file], token: token);

  Future<void> uploadVehicleImage(String vehicleId, MultipartPart file, {required String token}) =>
      _client.postMultipart('/driver-auth/vehicles/$vehicleId/images', files: [file], token: token);

  Future<void> submitPayment(Map<String, String> fields, MultipartPart receipt, {required String token}) =>
      _client.postMultipart('/driver-auth/payment-submissions', fields: fields, files: [receipt], token: token);
}
