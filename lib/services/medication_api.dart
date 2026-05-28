import 'dart:convert';

import 'api_client.dart';

enum SearchItemType { medicine, supplement }

class MedicationSearchItem {
  final SearchItemType type;
  final int id;
  final String name;
  final String? manufacturer;
  final String? imageUrl;
  final bool registered;

  MedicationSearchItem({
    required this.type,
    required this.id,
    required this.name,
    this.manufacturer,
    this.imageUrl,
    this.registered = false,
  });

  String get requestType =>
      type == SearchItemType.medicine ? 'MEDICINE' : 'SUPPLEMENT';
}

class MedicationSearchPage {
  final List<MedicationSearchItem> items;
  final int page;
  final int size;
  final bool hasNext;
  final int totalElements;

  MedicationSearchPage({
    required this.items,
    required this.page,
    required this.size,
    required this.hasNext,
    required this.totalElements,
  });
}

class CabinetIngredient {
  final int ingredientId;
  final String ingredientName;
  final num? dosage;
  final String? unit;

  CabinetIngredient({
    required this.ingredientId,
    required this.ingredientName,
    this.dosage,
    this.unit,
  });

  factory CabinetIngredient.fromJson(Map<String, dynamic> json) {
    return CabinetIngredient(
      ingredientId: (json['ingredientId'] as num).toInt(),
      ingredientName: json['ingredientName'] as String? ?? '성분명 없음',
      dosage: json['dosage'] as num?,
      unit: json['unit'] as String?,
    );
  }
}

class CabinetItem {
  final int regId;
  final SearchItemType type;
  final int itemId;
  final int? supplyDays;
  final String itemName;
  final String? manufacturer;
  final String? imageUrl;
  final String? efficacy;
  final String? precautions;
  final List<CabinetIngredient> ingredients;

  CabinetItem({
    required this.regId,
    required this.type,
    required this.itemId,
    this.supplyDays,
    required this.itemName,
    this.manufacturer,
    this.imageUrl,
    this.efficacy,
    this.precautions,
    this.ingredients = const [],
  });

  factory CabinetItem.fromJson(Map<String, dynamic> json) {
    return CabinetItem(
      regId: (json['regId'] as num).toInt(),
      type: _parseItemType(json['type'] as String?),
      itemId: (json['itemId'] as num).toInt(),
      supplyDays: (json['supplyDays'] as num?)?.toInt(),
      itemName: json['itemName'] as String? ?? '이름 없음',
      manufacturer: json['manufacturer'] as String?,
      imageUrl: json['imageUrl'] as String?,
      efficacy: json['efficacy'] as String?,
      precautions: json['precautions'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map(
            (item) => CabinetIngredient.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class MedicationApi {
  MedicationApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<MedicationSearchItem>> search(String keyword) async {
    return (await searchPage(keyword)).items;
  }

  Future<MedicationSearchPage> searchPage(
    String keyword, {
    int page = 0,
    int size = 10,
    bool auth = false,
  }) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return MedicationSearchPage(
        items: [],
        page: page,
        size: size,
        hasNext: false,
        totalElements: 0,
      );
    }

    final response = await _apiClient.get(
      '/api/search',
      auth: auth,
      query: {'keyword': trimmed, 'page': '$page', 'size': '$size'},
    );
    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    final medicines = (data['medicines'] as List<dynamic>? ?? []).map((item) {
      final map = item as Map<String, dynamic>;
      return MedicationSearchItem(
        type: SearchItemType.medicine,
        id: (map['id'] as num).toInt(),
        name: map['medicineName'] as String? ?? '이름 없음',
        manufacturer: map['manufacturer'] as String?,
        imageUrl: map['imageUrl'] as String?,
        registered: map['registered'] as bool? ?? false,
      );
    });
    final supplements = (data['supplements'] as List<dynamic>? ?? []).map((
      item,
    ) {
      final map = item as Map<String, dynamic>;
      return MedicationSearchItem(
        type: SearchItemType.supplement,
        id: (map['id'] as num).toInt(),
        name: map['supplementName'] as String? ?? '이름 없음',
        manufacturer: map['manufacturer'] as String?,
        registered: map['registered'] as bool? ?? false,
      );
    });
    return MedicationSearchPage(
      items: [...medicines, ...supplements],
      page: (data['page'] as num?)?.toInt() ?? page,
      size: (data['size'] as num?)?.toInt() ?? size,
      hasNext: data['hasNext'] as bool? ?? false,
      totalElements: (data['totalElements'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> addToMyPills(
    MedicationSearchItem item, {
    int? supplyDays,
  }) async {
    await _apiClient.post(
      '/api/mypills',
      auth: true,
      body: {
        'type': item.requestType,
        'itemId': item.id,
        ...supplyDays == null ? const {} : {'supplyDays': supplyDays},
      },
    );
  }

  Future<List<CabinetItem>> getMyPills() async {
    final response = await _apiClient.get('/api/mypills', auth: true);
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => CabinetItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteMyPill(int regId) async {
    await _apiClient.delete('/api/mypills/$regId', auth: true);
  }
}

SearchItemType _parseItemType(String? value) {
  return value == 'SUPPLEMENT'
      ? SearchItemType.supplement
      : SearchItemType.medicine;
}
