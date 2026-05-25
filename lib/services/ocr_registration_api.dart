import 'dart:convert';

import 'medication_api.dart';
import 'schedule_api.dart';
import 'vision_api.dart';
import 'api_client.dart';

class MedicationMatchCandidate {
  final SearchItemType itemType;
  final int itemId;
  final String itemName;
  final String? manufacturer;
  final double score;
  final bool registered;

  MedicationMatchCandidate({
    required this.itemType,
    required this.itemId,
    required this.itemName,
    this.manufacturer,
    required this.score,
    this.registered = false,
  });

  factory MedicationMatchCandidate.fromJson(Map<String, dynamic> json) {
    return MedicationMatchCandidate(
      itemType: json['itemType'] == 'SUPPLEMENT'
          ? SearchItemType.supplement
          : SearchItemType.medicine,
      itemId: (json['itemId'] as num).toInt(),
      itemName: json['itemName'] as String? ?? '이름 없음',
      manufacturer: json['manufacturer'] as String?,
      score: ((json['score'] as num?) ?? 0).toDouble(),
      registered: json['registered'] as bool? ?? false,
    );
  }

  String get requestType =>
      itemType == SearchItemType.supplement ? 'SUPPLEMENT' : 'MEDICINE';

  String get selectionKey => '$requestType:$itemId';
}

class MedicationMatchResult {
  final String keyword;
  final List<MedicationMatchCandidate> candidates;

  MedicationMatchResult({required this.keyword, required this.candidates});

  factory MedicationMatchResult.fromJson(Map<String, dynamic> json) {
    return MedicationMatchResult(
      keyword: json['keyword'] as String? ?? '',
      candidates: (json['candidates'] as List<dynamic>? ?? [])
          .map((item) =>
              MedicationMatchCandidate.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OcrRegisteredItem {
  final int regId;
  final SearchItemType itemType;
  final int itemId;
  final String itemName;
  final bool alreadyRegistered;
  final List<IntakeSchedule> schedules;

  OcrRegisteredItem({
    required this.regId,
    required this.itemType,
    required this.itemId,
    required this.itemName,
    required this.alreadyRegistered,
    this.schedules = const [],
  });

  factory OcrRegisteredItem.fromJson(Map<String, dynamic> json) {
    return OcrRegisteredItem(
      regId: (json['regId'] as num).toInt(),
      itemType: json['itemType'] == 'SUPPLEMENT'
          ? SearchItemType.supplement
          : SearchItemType.medicine,
      itemId: (json['itemId'] as num).toInt(),
      itemName: json['itemName'] as String? ?? '이름 없음',
      alreadyRegistered: json['alreadyRegistered'] as bool? ?? false,
      schedules: (json['schedules'] as List<dynamic>? ?? [])
          .map((item) => IntakeSchedule.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OcrRegistrationApi {
  OcrRegistrationApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<MedicationMatchResult>> matchKeywords(
    List<String> keywords, {
    int topK = 5,
  }) async {
    final response = await _apiClient.post(
      '/api/medication-matches',
      auth: true,
      body: {'keywords': keywords, 'topK': topK},
    );
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => MedicationMatchResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<OcrRegisteredItem>> registerSelections(
    List<OcrRegistrationSelection> selections,
  ) async {
    final response = await _apiClient.post(
      '/api/ocr/register',
      auth: true,
      body: {
        'items': selections.map((selection) => selection.toJson()).toList(),
      },
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['items'] as List<dynamic>? ?? [])
        .map((item) => OcrRegisteredItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class OcrRegistrationSelection {
  final MedicationMatchCandidate candidate;
  final List<OcrScheduleSuggestion> schedules;

  OcrRegistrationSelection({
    required this.candidate,
    required this.schedules,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemType': candidate.requestType,
      'itemId': candidate.itemId,
      'schedules': schedules
          .map(
            (schedule) => {
              'takeTime': schedule.takeTime,
              'daysOfWeek': schedule.daysOfWeek.isEmpty
                  ? ['EVERYDAY']
                  : schedule.daysOfWeek,
              'dosage': schedule.dosage,
            },
          )
          .toList(),
    };
  }
}
