import 'dart:convert';

import 'api_client.dart';

class NotificationSetting {
  final bool allAlarmEnabled;
  final bool soundVibrateEnabled;
  final bool refillAlarmEnabled;
  final int snoozeMinutes;
  final String morningTime;
  final String lunchTime;
  final String dinnerTime;
  final String nightTime;

  NotificationSetting({
    required this.allAlarmEnabled,
    required this.soundVibrateEnabled,
    required this.refillAlarmEnabled,
    required this.snoozeMinutes,
    required this.morningTime,
    required this.lunchTime,
    required this.dinnerTime,
    required this.nightTime,
  });

  factory NotificationSetting.fromJson(Map<String, dynamic> json) {
    return NotificationSetting(
      allAlarmEnabled: json['allAlarmEnabled'] as bool? ?? true,
      soundVibrateEnabled: json['soundVibrateEnabled'] as bool? ?? false,
      refillAlarmEnabled: json['refillAlarmEnabled'] as bool? ?? true,
      snoozeMinutes: (json['snoozeMinutes'] as num?)?.toInt() ?? 10,
      morningTime: json['morningTime'] as String? ?? '08:30',
      lunchTime: json['lunchTime'] as String? ?? '13:00',
      dinnerTime: json['dinnerTime'] as String? ?? '19:00',
      nightTime: json['nightTime'] as String? ?? '23:30',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allAlarmEnabled': allAlarmEnabled,
      'soundVibrateEnabled': soundVibrateEnabled,
      'refillAlarmEnabled': refillAlarmEnabled,
      'snoozeMinutes': snoozeMinutes,
      'morningTime': morningTime,
      'lunchTime': lunchTime,
      'dinnerTime': dinnerTime,
      'nightTime': nightTime,
    };
  }
}

class NotificationSettingApi {
  NotificationSettingApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<NotificationSetting> getSettings() async {
    final response = await _apiClient.get(
      '/api/notifications/settings',
      auth: true,
    );
    return NotificationSetting.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<NotificationSetting> saveSettings(NotificationSetting setting) async {
    final response = await _apiClient.put(
      '/api/notifications/settings',
      auth: true,
      body: setting.toJson(),
    );
    return NotificationSetting.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
