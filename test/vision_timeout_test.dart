import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:safepill_frontend/services/api_client.dart';

class StreamingClient extends http.BaseClient {
  StreamingClient(this.respond);
  final Future<http.StreamedResponse> Function(http.BaseRequest) respond;
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    lastRequest = request;
    return respond(request);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<http.Response> upload(ApiClient client) => client.postMultipart(
    '/api/vision/identify',
    fileBytes: [1, 2, 3],
    fileName: 'fixture.jpg',
    timeout: const Duration(milliseconds: 20),
  );

  test('missing response headers time out and abort the request', () async {
    final client = StreamingClient((_) => Completer<http.StreamedResponse>().future);
    await expectLater(
      upload(ApiClient(httpClient: client)),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'AI_TIMEOUT')),
    );
    final request = client.lastRequest! as http.AbortableMultipartRequest;
    await expectLater(request.abortTrigger!, completes);
  });

  test('stalled response body shares the same deadline', () async {
    final body = StreamController<List<int>>();
    final client = StreamingClient((_) async => http.StreamedResponse(body.stream, 200));
    await expectLater(
      upload(ApiClient(httpClient: client)),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 504)),
    );
    await expectLater(
      (client.lastRequest! as http.AbortableMultipartRequest).abortTrigger!,
      completes,
    );
    await body.close();
  });

  test('backend error code and Korean message reach the screen caller', () async {
    final client = StreamingClient((_) async => http.StreamedResponse(
      Stream.value(utf8.encode('{"code":"AI_UNAVAILABLE","message":"잠시 후 다시 시도해주세요."}')),
      503,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ));
    await expectLater(
      upload(ApiClient(httpClient: client)),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', 'AI_UNAVAILABLE')
          .having((e) => e.message, 'message', '잠시 후 다시 시도해주세요.')),
    );
    client.close();
  });

  test('oversized image is rejected before network transmission', () async {
    final client = StreamingClient((_) => throw StateError('must not send'));
    await expectLater(
      ApiClient(httpClient: client).postMultipart(
        '/api/vision/identify',
        fileBytes: Uint8List(ApiClient.maxImageBytes + 1),
        fileName: 'large.jpg',
      ),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 413)),
    );
    expect(client.lastRequest, isNull);
  });

  test('connection errors have a readable failure message', () async {
    final client = StreamingClient((_) async => throw http.ClientException('offline'));
    await expectLater(
      upload(ApiClient(httpClient: client)),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'AI_CONNECTION_FAILED')),
    );
  });
}
