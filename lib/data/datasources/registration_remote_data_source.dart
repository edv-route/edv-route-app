import '../../core/network/api_client.dart';

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

  /// Authenticated: the applicant's "completa tu solicitud" checklist (documents +
  /// vehicles with their per-item review state).
  Future<Map<String, dynamic>> checklist({required String token}) =>
      _client.get('/driver-auth/me/checklist', token: token);

  /// Authenticated: create a document slot on the applicant's OWN solicitud
  /// (born pending). The file is attached afterwards via /documents/:id/file.
  Future<Map<String, dynamic>> addDocument(Map<String, dynamic> body, {required String token}) =>
      _client.post('/driver-auth/me/documents', body, token: token);

  /// Authenticated: register a vehicle on the applicant's OWN solicitud (born
  /// pending). Photos are uploaded afterwards via /vehicles/:vehicleId/images.
  Future<Map<String, dynamic>> addVehicle(Map<String, dynamic> body, {required String token}) =>
      _client.post('/driver-auth/me/vehicles', body, token: token);

  /// Authenticated: the driver's alta/arrears debt (for the deferred payment).
  Future<Map<String, dynamic>> debt({required String token}) =>
      _client.get('/driver-auth/me/debt', token: token);

  /// Authenticated: the driver's account standing (coverage, next charge, arrears).
  Future<Map<String, dynamic>> account({required String token}) =>
      _client.get('/driver-auth/me/account', token: token);

  /// Authenticated: the edit form's fields that do not travel in /me (address).
  Future<Map<String, dynamic>> editableData({required String token}) =>
      _client.get('/driver-auth/me/editable', token: token);

  /// Authenticated: self-service edit (phone / email / address / password).
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body, {required String token}) =>
      _client.patch('/driver-auth/me', body, token: token);

  /// Authenticated: replaces the profile photo; returns the new signed URL.
  Future<Map<String, dynamic>> uploadPhoto(MultipartPart file, {required String token}) =>
      _client.postMultipart('/driver-auth/me/photo', files: [file], token: token);

  Future<void> uploadDocumentFile(String documentId, MultipartPart file, {required String token}) =>
      _client.postMultipart('/driver-auth/documents/$documentId/file', files: [file], token: token);

  /// Authenticated: signed URL (~60s) to PREVIEW one of the driver's OWN document
  /// files. Returns `{ url, expiresIn }`.
  Future<Map<String, dynamic>> documentFileUrl(String documentId, {required String token}) =>
      _client.get('/driver-auth/documents/$documentId/file', token: token);

  /// Authenticated: the driver's vehicles with full detail + signed photo URLs.
  Future<List<dynamic>> vehicles({required String token}) =>
      _client.getList('/driver-auth/me/vehicles', token: token);

  Future<void> uploadVehicleImage(String vehicleId, MultipartPart file, {required String token}) =>
      _client.postMultipart('/driver-auth/vehicles/$vehicleId/images', files: [file], token: token);

  Future<void> submitPayment(Map<String, String> fields, MultipartPart receipt, {required String token}) =>
      _client.postMultipart('/driver-auth/payment-submissions', fields: fields, files: [receipt], token: token);
}
