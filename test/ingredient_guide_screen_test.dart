import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safepill_frontend/services/ingredient_guide_api.dart';
import 'package:safepill_frontend/screens/medication/ingredient_guide_screen.dart';

final entry = IngredientGuideEntry.fromJson({
  'guide': {
    'code': 'ACETAMINOPHEN',
    'ingredientName': '아세트아미노펜',
    'title': '중복복용 주의',
    'detail': '제품 설명서를 확인하세요.',
    'sourceName': '공식 출처',
    'sourceUrl': 'https://www.fda.gov/',
    'reviewedAt': '2026-10-20',
  },
  'aliases': ['APAP', 'Acetaminophen'],
});

class FakeGuideApi extends IngredientGuideApi {
  bool fail = false;
  @override
  Future<List<IngredientGuideEntry>> getGuides() async {
    if (fail) throw Exception('offline');
    return [entry];
  }
}

void main() {
  test('matches aliases case-insensitively and ignores whitespace', () {
    expect(entry.matches(' aPaP '), isTrue);
    expect(entry.matches('아세트 아미노펜'), isTrue);
    expect(entry.matches('칼슘'), isFalse);
  });

  testWidgets('search opens details and displays empty result honestly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: IngredientGuideScreen(api: FakeGuideApi())),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'apap');
    await tester.pumpAndSettle();
    await tester.tap(find.text('아세트아미노펜'));
    await tester.pumpAndSettle();
    expect(find.text('제품 설명서를 확인하세요.'), findsOneWidget);
    expect(find.textContaining('자료 확인일'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '일치하지않음');
    await tester.pumpAndSettle();
    expect(find.textContaining('일치하는 가이드가 없습니다'), findsOneWidget);
    expect(find.text('아세트아미노펜'), findsNothing);
  });

  testWidgets('failed request can be retried', (tester) async {
    final api = FakeGuideApi()..fail = true;
    await tester.pumpWidget(MaterialApp(home: IngredientGuideScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('성분 가이드를 불러오지 못했습니다.'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('아세트아미노펜'), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
  });
}
