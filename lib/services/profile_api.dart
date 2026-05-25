import 'dart:convert';

import 'api_client.dart';

class CustomGuide {
  final List<String> avoidIngredients;
  final List<String> recommendedIngredients;
  final List<String> dietaryPrecautions;
  final List<String> warningSideEffects;
  final String? aiSummaryComment;

  CustomGuide({
    this.avoidIngredients = const [],
    this.recommendedIngredients = const [],
    this.dietaryPrecautions = const [],
    this.warningSideEffects = const [],
    this.aiSummaryComment,
  });

  factory CustomGuide.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CustomGuide();
    }
    return CustomGuide(
      avoidIngredients: _stringList(json['avoidIngredients']),
      recommendedIngredients: _stringList(json['recommendedIngredients']),
      dietaryPrecautions: _stringList(json['dietaryPrecautions']),
      warningSideEffects: _stringList(json['warningSideEffects']),
      aiSummaryComment: json['aiSummaryComment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avoidIngredients': avoidIngredients,
      'recommendedIngredients': recommendedIngredients,
      'dietaryPrecautions': dietaryPrecautions,
      'warningSideEffects': warningSideEffects,
      'aiSummaryComment': aiSummaryComment,
    };
  }
}

class HealthProfile {
  final int? id;
  final String disease;
  final String allergy;
  final CustomGuide customGuide;

  HealthProfile({
    this.id,
    required this.disease,
    required this.allergy,
    required this.customGuide,
  });

  factory HealthProfile.fromJson(Map<String, dynamic> json) {
    return HealthProfile(
      id: (json['id'] as num?)?.toInt(),
      disease: json['disease'] as String? ?? '',
      allergy: json['allergy'] as String? ?? '',
      customGuide: CustomGuide.fromJson(
        json['customGuide'] as Map<String, dynamic>?,
      ),
    );
  }
}

class ProfileApi {
  ProfileApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<HealthProfile?> getHealthProfile() async {
    final response = await _apiClient.get('/api/profile/health', auth: true);
    if (response.statusCode == 204 || response.body.isEmpty) {
      return null;
    }
    return HealthProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<HealthProfile> saveHealthProfile({
    required String disease,
    required String allergy,
    CustomGuide? customGuide,
  }) async {
    final response = await _apiClient.put(
      '/api/profile/health',
      auth: true,
      body: {
        'disease': disease,
        'allergy': allergy,
        'customGuide': (customGuide ?? CustomGuide()).toJson(),
      },
    );
    return HealthProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteHealthProfile() async {
    await _apiClient.delete('/api/profile/health', auth: true);
  }
}

List<String> _stringList(Object? value) {
  return (value as List<dynamic>? ?? []).map((item) => item.toString()).toList();
}
