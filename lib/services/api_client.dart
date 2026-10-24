import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;

  ApiException(this.statusCode, this.message, {this.code});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? httpClient, FlutterSecureStorage? storage})
    : _httpClient = httpClient ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const String tokenKey = 'jwt_token';
  static const int maxImageBytes = 30 * 1024 * 1024;

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

  Future<http.Response> patch(
    String path, {
    Object? body,
    bool auth = false,
  }) async {
    final uri = _buildUri(path);
    final response = await _httpClient.patch(
      uri,
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    _throwIfFailed(response);
    return response;
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    bool auth = false,
  }) async {
    final uri = _buildUri(path);
    final response = await _httpClient.put(
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
    Duration timeout = const Duration(seconds: 90),
  }) async {
    if (fileBytes.isEmpty) {
      throw ApiException(400, '이미지를 선택해주세요.', code: 'EMPTY_IMAGE');
    }
    if (fileBytes.length > maxImageBytes) {
      throw ApiException(413, '이미지는 30MB 이하로 선택해주세요.', code: 'IMAGE_TOO_LARGE');
    }
    final abort = Completer<void>();
    final request = http.AbortableMultipartRequest(
      'POST',
      _buildUri(path),
      abortTrigger: abort.future,
    );
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
    final stopwatch = Stopwatch()..start();
    String? requestId;
    int? statusCode;
    try {
      // A single deadline covers both the upload and the complete response body.
      final response = await (() async {
        final streamed = await _httpClient.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(timeout);
      requestId = response.headers['x-request-id'];
      statusCode = response.statusCode;
      _throwIfFailed(response);
      return response;
    } on TimeoutException {
      abort.complete();
      throw ApiException(
        504,
        '이미지 분석 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.',
        code: 'AI_TIMEOUT',
      );
    } on http.ClientException {
      throw ApiException(
        503,
        '이미지 분석 서버에 연결할 수 없습니다. 네트워크를 확인해주세요.',
        code: 'AI_CONNECTION_FAILED',
      );
    } finally {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('vision stage=client_total path=$path '
            'request_id=$requestId status=$statusCode '
            'elapsed_ms=${stopwatch.elapsedMilliseconds} bytes=${fileBytes.length}');
      }
    }
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
    String message = response.body.isEmpty ? '요청에 실패했습니다.' : response.body;
    String? code;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        code = decoded['code'] as String?;
        message = decoded['message'] as String? ?? message;
      }
    } catch (_) {
      // Keep raw response body for legacy string error responses.
    }
    throw ApiException(response.statusCode, message, code: code);
  }
}
