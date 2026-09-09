import 'dart:convert';

import 'api_client.dart';

class MedicineAlternative {
  final int? id;
  final String medicineName;
  final String? manufacturer;
  final List<String> sharedIngredients;
  final bool hasCabinetConflict;
  final List<String> conflictReasons;
  final bool isAiSuggested;
  final String? aiReason;

  MedicineAlternative({
    required this.id,
    required this.medicineName,
    this.manufacturer,
    required this.sharedIngredients,
    required this.hasCabinetConflict,
    required this.conflictReasons,
    this.isAiSuggested = false,
    this.aiReason,
  });

  factory MedicineAlternative.fromJson(Map<String, dynamic> json) {
    return MedicineAlternative(
      id: (json['id'] as num?)?.toInt(),
      medicineName: json['medicineName'] as String? ?? '이름 없음',
      manufacturer: json['manufacturer'] as String?,
      sharedIngredients: (json['sharedIngredients'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      hasCabinetConflict: json['hasCabinetConflict'] as bool? ?? false,
      conflictReasons: (json['conflictReasons'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      isAiSuggested: json['aiSuggested'] as bool? ?? false,
      aiReason: json['aiReason'] as String?,
    );
  }
}

class MedicineAlternativeApi {
  MedicineAlternativeApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<MedicineAlternative>> getAlternatives(int medicineId) async {
    final response = await _apiClient.get(
      '/api/medicines/$medicineId/alternatives',
      auth: true,
    );
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map(
          (item) => MedicineAlternative.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
