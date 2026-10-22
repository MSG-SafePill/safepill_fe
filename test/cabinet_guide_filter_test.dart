import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safepill_frontend/services/cabinet_guide_filter.dart';
import 'package:safepill_frontend/services/medication_api.dart';
import 'package:safepill_frontend/screens/medication/my_medication.dart';

CabinetItem item(
  int id,
  String status, {
  bool warning = false,
  bool overlap = false,
}) => CabinetItem.fromJson({
  'regId': id,
  'itemId': id,
  'type': 'MEDICINE',
  'itemName': '제품 $id',
  'ingredientGuide': {
    'status': status,
    'warnings': [
      if (warning) {'code': 'CALCIUM'},
    ],
  },
  'ingredientOverlaps': [
    if (overlap)
      {
        'ingredientName': '칼슘',
        'relatedItems': [
          {'regId': 2, 'itemName': '제품 2'},
        ],
      },
  ],
});

class FilterApi extends MedicationApi {
  @override
  Future<List<CabinetItem>> getMyPills() async => [
    item(1, 'AVAILABLE', warning: true),
    item(2, 'NO_INGREDIENT_DATA'),
  ];
}

void main() {
  test('partial guidance belongs to both warning and unverified filters', () {
    final partial = item(1, 'PARTIAL', warning: true);
    expect(CabinetGuideFilter.warnings.matches(partial, {1}), isTrue);
    expect(CabinetGuideFilter.unverified.matches(partial, {1}), isTrue);
    expect(
      CabinetGuideFilter.unverified.matches(
        item(1, 'AVAILABLE', warning: true),
        {1},
      ),
      isFalse,
    );
    for (final status in [
      'NO_INGREDIENT_DATA',
      'NO_REGISTERED_GUIDE',
      'UNAVAILABLE',
      'UNKNOWN',
    ]) {
      expect(
        CabinetGuideFilter.unverified.matches(item(1, status), {1}),
        isTrue,
      );
    }
  });

  test(
    'overlap filter uses all registered IDs and excludes deleted partners',
    () {
      final product = item(1, 'AVAILABLE', overlap: true);
      expect(CabinetGuideFilter.overlaps.matches(product, {1, 2}), isTrue);
      expect(CabinetGuideFilter.overlaps.matches(product, {1}), isFalse);
    },
  );

  testWidgets('filter combines with search and reset restores products', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MyMedicationScreen(medicationApi: FilterApi())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '주의 성분'));
    await tester.pumpAndSettle();
    expect(find.text('제품 1'), findsOneWidget);
    expect(find.text('제품 2'), findsNothing);
    await tester.enterText(find.byType(TextField), '없는제품');
    await tester.pumpAndSettle();
    expect(find.text('조건에 맞는 항목이 없습니다.'), findsOneWidget);
    expect(find.text('등록된 항목이 없습니다'), findsNothing);
    await tester.tap(find.text('검색·상태 필터 초기화'));
    await tester.pumpAndSettle();
    expect(find.text('제품 1'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, '정보 미확인'));
    await tester.pumpAndSettle();
    expect(find.text('제품 1'), findsNothing);
    expect(find.text('제품 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
