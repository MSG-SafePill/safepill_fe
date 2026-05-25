import 'dart:convert';

import 'api_client.dart';

enum IntakeStatus {
  taken,
  skipped,
}

class IntakeSchedule {
  final int scheduleId;
  final int regId;
  final String itemName;
  final String takeTime;
  final String dayOfWeek;
  final String dosage;

  IntakeSchedule({
    required this.scheduleId,
    required this.regId,
    required this.itemName,
    required this.takeTime,
    required this.dayOfWeek,
    required this.dosage,
  });

  factory IntakeSchedule.fromJson(Map<String, dynamic> json) {
    return IntakeSchedule(
      scheduleId: (json['scheduleId'] as num).toInt(),
      regId: (json['regId'] as num).toInt(),
      itemName: json['itemName'] as String? ?? '이름 없음',
      takeTime: json['takeTime'] as String? ?? '',
      dayOfWeek: json['dayOfWeek'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
    );
  }
}

class IntakeLog {
  final int logId;
  final int scheduleId;
  final int regId;
  final String itemName;
  final String takeTime;
  final String dosage;
  final IntakeStatus status;
  final DateTime? actualTime;

  IntakeLog({
    required this.logId,
    required this.scheduleId,
    required this.regId,
    required this.itemName,
    required this.takeTime,
    required this.dosage,
    required this.status,
    this.actualTime,
  });

  factory IntakeLog.fromJson(Map<String, dynamic> json) {
    return IntakeLog(
      logId: (json['logId'] as num).toInt(),
      scheduleId: (json['scheduleId'] as num).toInt(),
      regId: (json['regId'] as num).toInt(),
      itemName: json['itemName'] as String? ?? '이름 없음',
      takeTime: json['takeTime'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      status: _parseIntakeStatus(json['status'] as String?),
      actualTime: _parseDateTime(json['actualTime'] as String?),
    );
  }
}

class ScheduleApi {
  ScheduleApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<IntakeSchedule>> createSchedule({
    required int regId,
    required String takeTime,
    required List<String> daysOfWeek,
    required String dosage,
  }) async {
    final response = await _apiClient.post(
      '/api/schedules/$regId',
      auth: true,
      body: {
        'takeTime': takeTime,
        'daysOfWeek': daysOfWeek,
        'dosage': dosage,
      },
    );
    return _parseScheduleList(response.body);
  }

  Future<List<IntakeSchedule>> getTodaySchedules() async {
    final response = await _apiClient.get('/api/schedules/today', auth: true);
    return _parseScheduleList(response.body);
  }

  Future<List<IntakeSchedule>> getSchedulesByDay(String dayOfWeek) async {
    final response = await _apiClient.get(
      '/api/schedules',
      auth: true,
      query: {'day': dayOfWeek},
    );
    return _parseScheduleList(response.body);
  }

  Future<void> deleteSchedule(int scheduleId) async {
    await _apiClient.delete('/api/schedules/$scheduleId', auth: true);
  }

  Future<IntakeSchedule> updateSchedule({
    required int scheduleId,
    String? takeTime,
    List<String>? daysOfWeek,
    String? dosage,
  }) async {
    final response = await _apiClient.patch(
      '/api/schedules/$scheduleId',
      auth: true,
      body: {
        if (takeTime != null) 'takeTime': takeTime,
        if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
        if (dosage != null) 'dosage': dosage,
      },
    );
    return IntakeSchedule.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<IntakeLog> createLog({
    required int scheduleId,
    IntakeStatus status = IntakeStatus.taken,
    DateTime? actualTime,
  }) async {
    final response = await _apiClient.post(
      '/api/intake-logs/$scheduleId',
      auth: true,
      body: {
        'status': _statusToRequest(status),
        if (actualTime != null) 'actualTime': actualTime.toIso8601String(),
      },
    );
    return IntakeLog.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<IntakeLog> updateLog({
    required int logId,
    IntakeStatus? status,
    DateTime? actualTime,
  }) async {
    final response = await _apiClient.patch(
      '/api/intake-logs/$logId',
      auth: true,
      body: {
        if (status != null) 'status': _statusToRequest(status),
        if (actualTime != null) 'actualTime': actualTime.toIso8601String(),
      },
    );
    return IntakeLog.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<IntakeLog>> getLogsByDate(DateTime date) async {
    final response = await _apiClient.get(
      '/api/intake-logs',
      auth: true,
      query: {'date': _dateOnly(date)},
    );
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => IntakeLog.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteLog(int logId) async {
    await _apiClient.delete('/api/intake-logs/$logId', auth: true);
  }

  List<IntakeSchedule> _parseScheduleList(String body) {
    final items = jsonDecode(body) as List<dynamic>;
    return items
        .map((item) => IntakeSchedule.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

IntakeStatus _parseIntakeStatus(String? value) {
  return value == 'SKIPPED' ? IntakeStatus.skipped : IntakeStatus.taken;
}

String _statusToRequest(IntakeStatus status) {
  return status == IntakeStatus.skipped ? 'SKIPPED' : 'TAKEN';
}

DateTime? _parseDateTime(String? value) {
  return value == null || value.isEmpty ? null : DateTime.tryParse(value);
}

String _dateOnly(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
