import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'api_client.dart';

class GoogleAuthApi {
  GoogleAuthApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  static Future<void>? _initializeFuture;
  static String? _initializedClientId;

  final ApiClient _apiClient;

  Future<void> initialize() async {
    final webClientId = await _resolveWebClientId();
    if (webClientId.isEmpty) {
      throw ApiException(400, 'Google Web Client ID가 설정되지 않았습니다.');
    }

    await _ensureInitialized(GoogleSignIn.instance, webClientId);
  }

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      GoogleSignIn.instance.authenticationEvents;

  Future<String> login() async {
    final webClientId = await _resolveWebClientId();
    if (webClientId.isEmpty) {
      throw ApiException(400, 'Google Web Client ID가 설정되지 않았습니다.');
    }

    final signIn = GoogleSignIn.instance;
    await _ensureInitialized(signIn, webClientId);

    if (!signIn.supportsAuthenticate()) {
      throw ApiException(400, '현재 플랫폼에서는 Google 로그인 버튼 연동 설정이 필요합니다.');
    }

    final account = await signIn.authenticate(scopeHint: const ['email']);
    return loginWithAccount(account);
  }

  Future<String> loginWithAccount(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw ApiException(400, 'Google ID 토큰을 가져오지 못했습니다.');
    }

    final response = await _apiClient.post(
      '/api/users/oauth/google',
      body: {'idToken': idToken},
    );
    await _apiClient.saveToken(response.body);
    return account.email;
  }

  Future<String> _resolveWebClientId() async {
    if (_webClientId.isNotEmpty) {
      return _webClientId;
    }
    try {
      final raw = await rootBundle.loadString('assets/app_config.json');
      final config = jsonDecode(raw) as Map<String, dynamic>;
      return config['googleWebClientId'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _ensureInitialized(
    GoogleSignIn signIn,
    String webClientId,
  ) async {
    if (_initializeFuture != null) {
      await _initializeFuture;
      return;
    }

    _initializedClientId = webClientId;
    _initializeFuture = signIn
        .initialize(
          clientId: kIsWeb ? webClientId : null,
          serverClientId: kIsWeb ? null : webClientId,
        )
        .catchError((Object error) {
          final message = error.toString();
          if (error is StateError && message.contains('init() has already been called')) {
            return;
          }
          _initializeFuture = null;
          _initializedClientId = null;
          throw error;
        });

    await _initializeFuture;
    if (_initializedClientId != webClientId) {
      throw ApiException(400, 'Google Client ID 설정이 실행 중 변경되었습니다. 앱을 재시작해주세요.');
    }
  }
}
