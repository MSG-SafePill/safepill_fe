import 'ingredient_guide.dart';
import 'ingredient_overlap.dart';

class MedicationPreview {
  final String itemName;
  final bool alreadyRegistered;
  final IngredientGuideAssessment guide;
  final List<IngredientOverlap> overlaps;
  final int unverifiedCabinetItems;

  MedicationPreview.fromJson(Map<String, dynamic> json)
    : itemName = json['itemName'] as String? ?? '제품명 없음',
      alreadyRegistered = json['alreadyRegistered'] as bool? ?? false,
      guide = IngredientGuideAssessment.fromJson(
        json['ingredientGuide'] as Map<String, dynamic>,
      ),
      overlaps = (json['ingredientOverlaps'] as List<dynamic>? ?? [])
          .map(
            (item) => IngredientOverlap.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      unverifiedCabinetItems =
          (json['unverifiedCabinetItems'] as num?)?.toInt() ?? 0;
}
