import 'dart:convert';

import 'api_client.dart';

enum SearchItemType {
  medicine,
  supplement,
}

class MedicationSearchItem {
  final SearchItemType type;
  final int id;
  final String name;
  final String? manufacturer;
  final String? imageUrl;

  MedicationSearchItem({
    required this.type,
    required this.id,
    required this.name,
    this.manufacturer,
    this.imageUrl,
  });

  String get requestType => type == SearchItemType.medicine ? 'MEDICINE' : 'SUPPLEMENT';
}

class MedicationApi {
  MedicationApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<MedicationSearchItem>> search(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return [];
    }

    final response = await _apiClient.get(
      '/api/search',
      query: {
        'keyword': trimmed,
        'page': '0',
        'size': '10',
      },
    );
    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    final medicines = (data['medicines'] as List<dynamic>? ?? []).map((item) {
      final map = item as Map<String, dynamic>;
      return MedicationSearchItem(
        type: SearchItemType.medicine,
        id: map['id'] as int,
        name: map['medicineName'] as String? ?? '이름 없음',
        manufacturer: map['manufacturer'] as String?,
        imageUrl: map['imageUrl'] as String?,
      );
    });
    final supplements = (data['supplements'] as List<dynamic>? ?? []).map((item) {
      final map = item as Map<String, dynamic>;
      return MedicationSearchItem(
        type: SearchItemType.supplement,
        id: map['id'] as int,
        name: map['supplementName'] as String? ?? '이름 없음',
        manufacturer: map['manufacturer'] as String?,
      );
    });
    return [...medicines, ...supplements];
  }

  Future<void> addToMyPills(MedicationSearchItem item) async {
    await _apiClient.post(
      '/api/mypills',
      auth: true,
      body: {
        'type': item.requestType,
        'itemId': item.id,
      },
    );
  }
}

