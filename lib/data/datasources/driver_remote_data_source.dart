import '../../core/network/api_client.dart';

/// Every call the driver app makes to the backend: public catalogs, the
/// solicitud, the driver's own account and the multipart uploads. One HTTP
/// surface per backend module — the repositories on top slice it by domain.
class DriverRemoteDataSource {
  DriverRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<dynamic>> paymentMethods() => _client.getList('/driver-auth/payment-methods');

  Future<List<dynamic>> vehicleTypes() => _client.getList('/driver-auth/vehicle-types');

  /// Active document requirements (driver + vehicle), public: the draft needs the
  /// vehicle ones before the vehicle exists on the server.
  Future<List<dynamic>> requirements() => _client.getList('/driver-auth/requirements');

  /// Current active membership (name + price), or an empty map when none exists.
  Future<Map<String, dynamic>> membership() => _client.get('/driver-auth/membership');

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

  /// Authenticated: the driver's alta/arrears debt (for the deferred payment).
  Future<Map<String, dynamic>> debt({required String token}) =>
      _client.get('/driver-auth/me/debt', token: token);

  /// Authenticated: the driver's account standing (coverage, next charge, arrears).
  Future<Map<String, dynamic>> account({required String token}) =>
      _client.get('/driver-auth/me/account', token: token);

  /// Authenticated: one page of his inbox, newest first. Only notices that have
  /// already happened — a reminder scheduled for Sunday is not in there yet.
  Future<Map<String, dynamic>> notifications({
    required String token,
    int limit = 20,
    String? before,
  }) =>
      _client.get(
        '/driver-auth/me/notifications?limit=$limit${before == null ? '' : '&before=$before'}',
        token: token,
      );

  /// Authenticated: marks one notice as read. The backend always answers 204,
  /// even for an id that is not his — it must not reveal whether it exists.
  Future<void> markNotificationRead(String id, {required String token}) =>
      _client.post('/driver-auth/me/notifications/$id/read', const {}, token: token);

  Future<Map<String, dynamic>> markAllNotificationsRead({required String token}) =>
      _client.post('/driver-auth/me/notifications/read-all', const {}, token: token);

  /// Authenticated: registers this phone's FCM token (upsert on the server).
  Future<Map<String, dynamic>> registerDeviceToken(
    String deviceToken, {
    required String token,
    String platform = 'android',
  }) =>
      _client.post(
        '/driver-auth/me/device-tokens',
        {'token': deviceToken, 'platform': platform},
        token: token,
      );

  /// Authenticated: logout — this phone stops receiving HIS notices.
  Future<void> revokeDeviceToken(String deviceToken, {required String token}) =>
      _client.delete(
        '/driver-auth/me/device-tokens',
        {'token': deviceToken},
        token: token,
      );

  /// Authenticated: the edit form's fields that do not travel in /me (address).
  Future<Map<String, dynamic>> editableData({required String token}) =>
      _client.get('/driver-auth/me/editable', token: token);

  /// Authenticated: self-service edit (phone / email / address / password).
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body, {required String token}) =>
      _client.patch('/driver-auth/me', body, token: token);

  /// Authenticated: picks the vehicle the driver operates with.
  Future<Map<String, dynamic>> setPrimaryVehicle(String vehicleId, {required String token}) =>
      _client.patch('/driver-auth/me/vehicles/$vehicleId/primary', const {}, token: token);

  /// Authenticated: puts the driver on or off duty.
  Future<Map<String, dynamic>> setAvailability(bool available, {required String token}) =>
      _client.patch('/driver-auth/me/availability', {'available': available}, token: token);

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

  /// A whole vehicle in one multipart call: its data as fields, the picture in
  /// the "photo" field and each paper in `document_<requirementId>`. With
  /// [resubmitVehicleId] it goes to the rejected vehicle instead of creating one.
  Future<Map<String, dynamic>> submitVehicle(
    Map<String, String> fields,
    List<MultipartPart> files, {
    required String token,
    String? resubmitVehicleId,
  }) =>
      _client.postMultipart(
        resubmitVehicleId == null
            ? '/driver-auth/me/vehicles/submit'
            : '/driver-auth/me/vehicles/$resubmitVehicleId/resubmit',
        fields: fields,
        files: files,
        token: token,
      );

  Future<void> submitPayment(Map<String, String> fields, MultipartPart receipt, {required String token}) =>
      _client.postMultipart('/driver-auth/payment-submissions', fields: fields, files: [receipt], token: token);
}
