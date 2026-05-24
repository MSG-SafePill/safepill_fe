import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import 'api_client.dart';

class PillIdentifyCandidate {
  final String pillName;
  final double confidence;
  final String? matchedText;

  PillIdentifyCandidate({
    required this.pillName,
    required this.confidence,
    this.matchedText,
  });
}

class PrescriptionOcrItem {
  final String medicineName;
  final String rawText;
  final String? dosage;
  final String? frequency;
  final String? mealTiming;
  final String? days;
  final List<OcrScheduleSuggestion> scheduleSuggestions;

  PrescriptionOcrItem({
    required this.medicineName,
    required this.rawText,
    this.dosage,
    this.frequency,
    this.mealTiming,
    this.days,
    this.scheduleSuggestions = const [],
  });
}

class OcrScheduleSuggestion {
  final String takeTime;
  final List<String> daysOfWeek;
  final String dosage;
  final String? mealTiming;

  OcrScheduleSuggestion({
    required this.takeTime,
    required this.daysOfWeek,
    required this.dosage,
    this.mealTiming,
  });

  factory OcrScheduleSuggestion.fromJson(Map<String, dynamic> json) {
    return OcrScheduleSuggestion(
      takeTime: json['takeTime'] as String? ?? '',
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      dosage: json['dosage'] as String? ?? '',
      mealTiming: json['mealTiming'] as String?,
    );
  }
}

class VisionApi {
  VisionApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<PillIdentifyCandidate>> identifyPill(XFile image) async {
    final response = await _apiClient.postMultipart(
      '/api/vision/identify',
      auth: true,
      fileBytes: await image.readAsBytes(),
      fileName: image.name,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] ?? data['identifiedPills'] ?? [];
    return (candidates as List<dynamic>).map((item) {
      final map = item as Map<String, dynamic>;
      return PillIdentifyCandidate(
        pillName:
            map['pillName'] as String? ??
            map['medicineName'] as String? ??
            '이름 없음',
        confidence: ((map['confidence'] as num?) ?? 0).toDouble(),
        matchedText: map['matchedText'] as String?,
      );
    }).toList();
  }

  Future<List<PrescriptionOcrItem>> scanPrescription(XFile image) async {
    final response = await _apiClient.postMultipart(
      '/api/ocr/prescription',
      auth: true,
      fileBytes: await image.readAsBytes(),
      fileName: image.name,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] ?? data['medications'] ?? [];
    return (items as List<dynamic>).map((item) {
      final map = item as Map<String, dynamic>;
      return PrescriptionOcrItem(
        medicineName: map['medicineName'] as String? ?? '이름 없음',
        rawText: map['rawText'] as String? ?? '',
        dosage: map['dosage'] as String?,
        frequency: map['frequency'] as String?,
        mealTiming: map['mealTiming'] as String?,
        days: map['days'] as String?,
        scheduleSuggestions:
            (map['scheduleSuggestions'] as List<dynamic>? ?? [])
                .map((item) =>
                    OcrScheduleSuggestion.fromJson(item as Map<String, dynamic>))
                .toList(),
      );
    }).toList();
  }
}
