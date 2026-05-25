import 'dart:convert';

import 'api_client.dart';

class InteractionRuleResult {
  final String? itemNameA;
  final String? itemNameB;
  final String? itemTypeA;
  final String? itemTypeB;
  final String? ingredientNameA;
  final String? ingredientNameB;
  final String riskLevel;
  final String description;

  InteractionRuleResult({
    this.itemNameA,
    this.itemNameB,
    this.itemTypeA,
    this.itemTypeB,
    this.ingredientNameA,
    this.ingredientNameB,
    required this.riskLevel,
    required this.description,
  });

  factory InteractionRuleResult.fromJson(Map<String, dynamic> json) {
    return InteractionRuleResult(
      itemNameA:
          json['itemNameA'] as String? ?? json['medicineNameA'] as String?,
      itemNameB:
          json['itemNameB'] as String? ?? json['medicineNameB'] as String?,
      itemTypeA: json['itemTypeA'] as String?,
      itemTypeB: json['itemTypeB'] as String?,
      ingredientNameA: json['ingredientNameA'] as String?,
      ingredientNameB: json['ingredientNameB'] as String?,
      riskLevel: json['riskLevel'] as String? ?? 'CAUTION',
      description: json['description'] as String? ?? '',
    );
  }
}

class AiInteractionWarning {
  final String? title;
  final String? severity;
  final List<String> items;
  final String? reason;

  AiInteractionWarning({
    this.title,
    this.severity,
    this.items = const [],
    this.reason,
  });

  factory AiInteractionWarning.fromJson(Map<String, dynamic> json) {
    return AiInteractionWarning(
      title: json['title'] as String?,
      severity: json['severity'] as String?,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      reason: json['reason'] as String?,
    );
  }
}

class AiInteractionEvidence {
  final String? source;
  final String? text;

  AiInteractionEvidence({this.source, this.text});

  factory AiInteractionEvidence.fromJson(Map<String, dynamic> json) {
    return AiInteractionEvidence(
      source: json['source'] as String?,
      text: json['text'] as String?,
    );
  }
}

class AiInteractionAnalysis {
  final String requestId;
  final String status;
  final String riskLevel;
  final String summary;
  final List<AiInteractionWarning> warnings;
  final List<String> recommendations;
  final List<AiInteractionEvidence> evidence;
  final String disclaimer;

  AiInteractionAnalysis({
    required this.requestId,
    required this.status,
    required this.riskLevel,
    required this.summary,
    this.warnings = const [],
    this.recommendations = const [],
    this.evidence = const [],
    required this.disclaimer,
  });

  factory AiInteractionAnalysis.fromJson(Map<String, dynamic> json) {
    return AiInteractionAnalysis(
      requestId: json['requestId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      riskLevel: json['riskLevel'] as String? ?? 'NONE',
      summary: json['summary'] as String? ?? '',
      warnings: (json['warnings'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                AiInteractionWarning.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      evidence: (json['evidence'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                AiInteractionEvidence.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}

class InteractionApi {
  InteractionApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<InteractionRuleResult>> analyzeMyCabinetRules() async {
    final response = await _apiClient.get(
      '/api/interactions/my-cabinet/analyze',
      auth: true,
    );
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map(
          (item) =>
              InteractionRuleResult.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<AiInteractionAnalysis> analyzeMyCabinetWithAi() async {
    final response = await _apiClient.get(
      '/api/interactions/my-cabinet/analyze/ai',
      auth: true,
    );
    return AiInteractionAnalysis.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
