import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

/// A file part for a multipart upload: raw bytes plus the field name and
/// filename. Vendor-neutral (bytes, not a path) so the client stays free of
/// `dart:io` and still compiles for web.
class MultipartPart {
  final String field;
  final List<int> bytes;
  final String filename;

  const MultipartPart({
    required this.field,
    required this.bytes,
    required this.filename,
  });
}

/// Thin HTTP client over the EDV backend: JSON in/out, multipart uploads, bearer
/// auth, and error mapping to [ApiException] carrying the backend's Spanish
/// message. Kept free of `dart:io` so it also compiles for web.
class ApiClient {
  ApiClient({http.Client? client, String baseUrl = AppConfig.apiBaseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async =>
      _asMap(await _send('POST', path, body: body, token: token));

  Future<Map<String, dynamic>> get(String path, {String? token}) async =>
      _asMap(await _send('GET', path, token: token));

  /// Partial update — the driver editing his own data.
  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async =>
      _asMap(await _send('PATCH', path, body: body, token: token));

  /// GET whose payload is a JSON array (e.g. the requirement / payment catalogs).
  Future<List<dynamic>> getList(String path, {String? token}) async =>
      (await _send('GET', path, token: token)) as List<dynamic>? ?? const [];

  /// Multipart POST: string [fields] + [files]. The content type is intentionally
  /// not set — the backend validates every file by magic number, not by the
  /// declared type.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    List<MultipartPart> files = const [],
    String? token,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    for (final f in files) {
      request.files.add(http.MultipartFile.fromBytes(f.field, f.bytes, filename: f.filename));
    }
    try {
      final streamed = await _client.send(request).timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      return _asMap(_parse(response));
    } on http.ClientException {
      throw const ApiException('No se pudo contactar el servidor. Revisa tu conexión.');
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder.');
    } on FormatException {
      throw const ApiException('Respuesta inválida del servidor.');
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers['Content-Type'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await _client.send(request).timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);
      return _parse(response);
    } on http.ClientException {
      throw const ApiException('No se pudo contactar el servidor. Revisa tu conexión.');
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder.');
    } on FormatException {
      throw const ApiException('Respuesta inválida del servidor.');
    }
  }

  dynamic _parse(http.Response response) {
    final status = response.statusCode;
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (status >= 200 && status < 300) return decoded;
    final message = decoded is Map && decoded['message'] is String
        ? decoded['message'] as String
        : 'Error inesperado ($status).';
    throw ApiException(message, statusCode: status);
  }

  Map<String, dynamic> _asMap(dynamic decoded) =>
      decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
}
