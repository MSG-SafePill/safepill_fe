import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safepill_frontend/services/medication_api.dart';
import 'package:safepill_frontend/services/ingredient_guide.dart';
import 'package:safepill_frontend/screens/medication/ingredient_guide_panel.dart';

void main() {
  final guideJson = <String, dynamic>{
    'status': 'PARTIAL',
    'warnings': [
      {
        'code': 'MORPHINE',
        'ingredientName': '모르핀',
        'riskType': 'DEPENDENCE',
        'title': '의존·호흡억제 주의',
        'summary': '처방대로 사용하세요.',
        'detail': '임의로 증량하거나 갑자기 중단하지 마세요.',
        'sourceName': 'MedlinePlus · Morphine',
        'sourceUrl': 'https://medlineplus.gov/druginfo/meds/a682133.html',
        'reviewedAt': '2026-10-20',
      },
    ],
    'unmatchedIngredients': ['기타 성분'],
  };

  test(
    'cabinet parses nested guide response and preserves partial coverage',
    () {
      final item = CabinetItem.fromJson({
        'regId': 1,
        'itemId': 2,
        'type': 'MEDICINE',
        'ingredientGuide': guideJson,
      });
      expect(item.ingredientGuide.status, 'PARTIAL');
      expect(item.ingredientGuide.warnings.single.code, 'MORPHINE');
      expect(item.ingredientGuide.unmatchedIngredients, ['기타 성분']);
    },
  );

  test('older server response remains unavailable rather than safe', () {
    final item = CabinetItem.fromJson({'regId': 1, 'itemId': 2});
    expect(item.ingredientGuide.status, 'UNAVAILABLE');
    expect(item.ingredientGuide.statusLabel, contains('불러오지 못했습니다'));
  });

  testWidgets('expansion shows warning evidence and uncovered ingredients', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: IngredientGuidePanel(
              assessment: IngredientGuideAssessment.fromJson(guideJson),
            ),
          ),
        ),
      ),
    );
    expect(find.text('성분 주의 1건 · 일부 가이드 없음'), findsOneWidget);
    await tester.tap(find.text('성분 주의 1건 · 일부 가이드 없음'));
    await tester.pumpAndSettle();
    expect(find.text('모르핀 · 의존·호흡억제 주의'), findsOneWidget);
    expect(find.textContaining('MedlinePlus'), findsOneWidget);
    expect(find.textContaining('가이드 미확인 성분: 기타 성분'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing ingredient data has an explicit neutral status', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IngredientGuidePanel(
            assessment: IngredientGuideAssessment(status: 'NO_INGREDIENT_DATA'),
          ),
        ),
      ),
    );
    expect(find.text('성분 정보 없음 · 가이드 확인 불가'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });
}
