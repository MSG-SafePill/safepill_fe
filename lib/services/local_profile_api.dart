import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalUserProfile {
  final String loginId;
  final String nickname;

  LocalUserProfile({
    required this.loginId,
    required this.nickname,
  });
}

class LocalProfileApi {
  LocalProfileApi({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String loginIdKey = 'profile_login_id';
  static const String nicknameKey = 'profile_nickname';

  final FlutterSecureStorage _storage;

  Future<LocalUserProfile> getProfile() async {
    final loginId = await _storage.read(key: loginIdKey) ?? '';
    final nickname = await _storage.read(key: nicknameKey);
    return LocalUserProfile(
      loginId: loginId,
      nickname: nickname == null || nickname.isEmpty
          ? _fallbackNickname(loginId)
          : nickname,
    );
  }

  Future<void> saveLoginId(String loginId) async {
    final previousLoginId = await _storage.read(key: loginIdKey);
    await _storage.write(key: loginIdKey, value: loginId);
    if (previousLoginId != null && previousLoginId != loginId) {
      await _storage.delete(key: nicknameKey);
    }
  }

  Future<void> saveNickname(String nickname) {
    return _storage.write(key: nicknameKey, value: nickname.trim());
  }

  Future<void> clear() async {
    await _storage.delete(key: loginIdKey);
    await _storage.delete(key: nicknameKey);
  }

  String _fallbackNickname(String loginId) {
    if (loginId.isEmpty) {
      return '사용자';
    }
    return loginId.contains('@') ? loginId.split('@').first : loginId;
  }
}
