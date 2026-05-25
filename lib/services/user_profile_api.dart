import 'dart:convert';

import 'api_client.dart';

class UserProfile {
  final int id;
  final String loginId;
  final String username;
  final String email;
  final String? gender;
  final String? birthDate;
  final String? provider;

  UserProfile({
    required this.id,
    required this.loginId,
    required this.username,
    required this.email,
    this.gender,
    this.birthDate,
    this.provider,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num).toInt(),
      loginId: json['loginId'] as String? ?? '',
      username: json['username'] as String? ?? '사용자',
      email: json['email'] as String? ?? '',
      gender: json['gender'] as String?,
      birthDate: json['birthDate'] as String?,
      provider: json['provider'] as String?,
    );
  }
}

class UserProfileApi {
  UserProfileApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<UserProfile> getProfile() async {
    final response = await _apiClient.get('/api/users/me', auth: true);
    return UserProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<UserProfile> updateProfile({required String username}) async {
    final response = await _apiClient.patch(
      '/api/users/me',
      auth: true,
      body: {'username': username},
    );
    return UserProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.patch(
      '/api/users/me/password',
      auth: true,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
