import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? httpClient, FlutterSecureStorage? storage})
    : _httpClient = httpClient ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const String tokenKey = 'jwt_token';

  final http.Client _httpClient;
  final FlutterSecureStorage _storage;

  String get baseUrl =>
      kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';

  Future<String?> readToken() {
    return _storage.read(key: tokenKey);
  }

  Future<void> saveToken(String token) {
    return _storage.write(key: tokenKey, value: token);
  }

  Future<void> clearToken() {
    return _storage.delete(key: tokenKey);
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? query,
    bool auth = false,
  }) async {
    final uri = _buildUri(path, query);
    final response = await _httpClient.get(
      uri,
      headers: await _headers(auth: auth),
    );
    _throwIfFailed(response);
    return response;
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    bool auth = false,
  }) async {
    final uri = _buildUri(path);
    final response = await _httpClient.post(
      uri,
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    _throwIfFailed(response);
    return response;
  }

  Future<http.Response> postMultipart(
    String path, {
    required List<int> fileBytes,
    required String fileName,
    String fieldName = 'image',
    Map<String, String>? fields,
    bool auth = false,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri(path));
    if (fields != null) {
      request.fields.addAll(fields);
    }
    if (auth) {
      final token = await readToken();
      if (token == null || token.isEmpty) {
        throw ApiException(401, '로그인이 필요합니다.');
      }
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes(fieldName, fileBytes, filename: fileName),
    );
    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    _throwIfFailed(response);
    return response;
  }

  Future<http.Response> delete(String path, {bool auth = false}) async {
    final uri = _buildUri(path);
    final response = await _httpClient.delete(
      uri,
      headers: await _headers(auth: auth),
    );
    _throwIfFailed(response);
    return response;
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await readToken();
      if (token == null || token.isEmpty) {
        throw ApiException(401, '로그인이 필요합니다.');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw ApiException(
      response.statusCode,
      response.body.isEmpty ? '요청에 실패했습니다.' : response.body,
    );
  }
}
