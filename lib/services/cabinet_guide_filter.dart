import 'medication_api.dart';

enum CabinetGuideFilter {
  all('모든 상태'),
  warnings('주의 성분'),
  overlaps('성분 겹침'),
  unverified('정보 미확인');

  const CabinetGuideFilter(this.label);
  final String label;

  bool matches(CabinetItem item, Set<int> registeredIds) => switch (this) {
    all => true,
    warnings => item.ingredientGuide.warnings.isNotEmpty,
    overlaps => item.ingredientOverlaps.any(
      (overlap) => overlap.relatedItems.keys.any(registeredIds.contains),
    ),
    unverified => item.ingredientGuide.status != 'AVAILABLE',
  };
}
