class IngredientGuide {
  final String code;
  final String ingredientName;
  final String riskType;
  final String title;
  final String summary;
  final String detail;
  final String sourceName;
  final String sourceUrl;
  final String reviewedAt;

  const IngredientGuide({
    required this.code,
    required this.ingredientName,
    required this.riskType,
    required this.title,
    required this.summary,
    required this.detail,
    required this.sourceName,
    required this.sourceUrl,
    required this.reviewedAt,
  });

  factory IngredientGuide.fromJson(Map<String, dynamic> json) =>
      IngredientGuide(
        code: json['code'] as String? ?? '',
        ingredientName: json['ingredientName'] as String? ?? '성분명 없음',
        riskType: json['riskType'] as String? ?? '',
        title: json['title'] as String? ?? '성분 주의',
        summary: json['summary'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        sourceName: json['sourceName'] as String? ?? '',
        sourceUrl: json['sourceUrl'] as String? ?? '',
        reviewedAt: json['reviewedAt'] as String? ?? '',
      );
}

class IngredientGuideAssessment {
  final String status;
  final List<IngredientGuide> warnings;
  final List<String> unmatchedIngredients;

  const IngredientGuideAssessment({
    this.status = 'UNAVAILABLE',
    this.warnings = const [],
    this.unmatchedIngredients = const [],
  });

  factory IngredientGuideAssessment.fromJson(Map<String, dynamic> json) =>
      IngredientGuideAssessment(
        status: json['status'] as String? ?? 'UNAVAILABLE',
        warnings: (json['warnings'] as List<dynamic>? ?? [])
            .map((e) => IngredientGuide.fromJson(e as Map<String, dynamic>))
            .toList(),
        unmatchedIngredients:
            (json['unmatchedIngredients'] as List<dynamic>? ?? [])
                .whereType<String>()
                .toList(),
      );

  String get statusLabel => switch (status) {
    'AVAILABLE' => '성분 주의 ${warnings.length}건',
    'PARTIAL' => '성분 주의 ${warnings.length}건 · 일부 가이드 없음',
    'NO_INGREDIENT_DATA' => '성분 정보 없음 · 가이드 확인 불가',
    'NO_REGISTERED_GUIDE' => '등록된 성분 가이드 없음',
    _ => '성분 가이드를 불러오지 못했습니다',
  };
}
