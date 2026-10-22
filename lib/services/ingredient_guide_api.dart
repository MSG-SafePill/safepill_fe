import 'dart:convert';
import 'api_client.dart';
import 'ingredient_guide.dart';

class IngredientGuideEntry {
  final IngredientGuide guide;
  final List<String> aliases;

  const IngredientGuideEntry({required this.guide, this.aliases = const []});

  factory IngredientGuideEntry.fromJson(Map<String, dynamic> json) =>
      IngredientGuideEntry(
        guide: IngredientGuide.fromJson(json['guide'] as Map<String, dynamic>),
        aliases: (json['aliases'] as List<dynamic>? ?? []).cast<String>(),
      );

  bool matches(String query) {
    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final keyword = normalize(query);
    return [
      guide.ingredientName,
      ...aliases,
    ].any((name) => normalize(name).contains(keyword));
  }
}

class IngredientGuideApi {
  final ApiClient _client;
  IngredientGuideApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<IngredientGuideEntry>> getGuides() async {
    final response = await _client.get('/api/ingredient-guides');
    return (jsonDecode(response.body) as List<dynamic>)
        .map(
          (entry) =>
              IngredientGuideEntry.fromJson(entry as Map<String, dynamic>),
        )
        .toList();
  }
}
