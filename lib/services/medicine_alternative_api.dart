import 'dart:convert';

import 'api_client.dart';

class AlternativeMatchType {
  static const sameIngredient = 'SAME_INGREDIENT';
  static const partialIngredient = 'PARTIAL_INGREDIENT';
  static const sameEfficacyGroup = 'SAME_EFFICACY_GROUP';
  static const aiSuggested = 'AI_SUGGESTED';
}

class AlternativeTarget {
  final int? id;
  final String medicineName;
  final String? manufacturer;
  final List<String> ingredients;
  final bool permitActive;
  final String? permitStatus;
  final String? cancelDate;

  AlternativeTarget({
    required this.id,
    required this.medicineName,
    this.manufacturer,
    required this.ingredients,
    required this.permitActive,
    this.permitStatus,
    this.cancelDate,
  });

  factory AlternativeTarget.fromJson(Map<String, dynamic> json) {
    return AlternativeTarget(
      id: (json['id'] as num?)?.toInt(),
      medicineName: json['medicineName'] as String? ?? '이름 없음',
      manufacturer: json['manufacturer'] as String?,
      ingredients: _stringList(json['ingredients']),
      permitActive: json['permitActive'] as bool? ?? true,
      permitStatus: json['permitStatus'] as String?,
      cancelDate: json['cancelDate'] as String?,
    );
  }
}

class MedicineAlternative {
  final int? id;
  final String medicineName;
  final String? manufacturer;
  final String matchType;
  final List<String> sharedIngredients;
  final List<String> ingredientSummaries;
  final bool dosageDiffers;
  final bool hasCabinetConflict;
  final List<String> conflictReasons;
  final bool isAiSuggested;
  final bool isVerifiedInDb;
  final String? aiReason;

  MedicineAlternative({
    required this.id,
    required this.medicineName,
    this.manufacturer,
    required this.matchType,
    required this.sharedIngredients,
    required this.ingredientSummaries,
    this.dosageDiffers = false,
    required this.hasCabinetConflict,
    required this.conflictReasons,
    this.isAiSuggested = false,
    this.isVerifiedInDb = false,
    this.aiReason,
  });

  factory MedicineAlternative.fromJson(Map<String, dynamic> json) {
    final isAi = json['aiSuggested'] as bool? ?? false;
    return MedicineAlternative(
      id: (json['id'] as num?)?.toInt(),
      medicineName: json['medicineName'] as String? ?? '이름 없음',
      manufacturer: json['manufacturer'] as String?,
      matchType:
          json['matchType'] as String? ??
          (isAi
              ? AlternativeMatchType.aiSuggested
              : AlternativeMatchType.sameIngredient),
      sharedIngredients: _stringList(json['sharedIngredients']),
      ingredientSummaries: _stringList(json['ingredientSummaries']),
      dosageDiffers: json['dosageDiffers'] as bool? ?? false,
      hasCabinetConflict: json['hasCabinetConflict'] as bool? ?? false,
      conflictReasons: _stringList(json['conflictReasons']),
      isAiSuggested: isAi,
      isVerifiedInDb: json['verifiedInDb'] as bool? ?? false,
      aiReason: json['aiReason'] as String?,
    );
  }
}

class AlternativeResult {
  final AlternativeTarget target;
  final List<MedicineAlternative> alternatives;
  final bool aiUnavailable;

  AlternativeResult({
    required this.target,
    required this.alternatives,
    required this.aiUnavailable,
  });

  factory AlternativeResult.fromJson(Map<String, dynamic> json) {
    return AlternativeResult(
      target: AlternativeTarget.fromJson(
        json['target'] as Map<String, dynamic>? ?? const {},
      ),
      alternatives: (json['alternatives'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                MedicineAlternative.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      aiUnavailable: json['aiUnavailable'] as bool? ?? false,
    );
  }
}

List<String> _stringList(dynamic value) {
  return (value as List<dynamic>? ?? []).map((item) => item.toString()).toList();
}

class MedicineAlternativeApi {
  MedicineAlternativeApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AlternativeResult> getAlternatives(int medicineId) async {
    final response = await _apiClient.get(
      '/api/medicines/$medicineId/alternatives',
      auth: true,
    );
    return AlternativeResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
