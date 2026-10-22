class IngredientOverlap {
  final String ingredientName;
  final Map<int, String> relatedItems;

  const IngredientOverlap({
    required this.ingredientName,
    required this.relatedItems,
  });

  factory IngredientOverlap.fromJson(Map<String, dynamic> json) =>
      IngredientOverlap(
        ingredientName: json['ingredientName'] as String? ?? '성분명 없음',
        relatedItems: {
          for (final item in json['relatedItems'] as List<dynamic>? ?? [])
            (item['regId'] as num).toInt():
                item['itemName'] as String? ?? '이름 없음',
        },
      );
}
