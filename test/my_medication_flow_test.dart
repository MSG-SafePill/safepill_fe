import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safepill_frontend/screens/medication/my_medication.dart';
import 'package:safepill_frontend/services/api_client.dart';
import 'package:safepill_frontend/services/medication_api.dart';

class FakeMedicationApi extends MedicationApi {
  Object? loadError;
  Object? deleteError;
  List<CabinetItem> items = [
    CabinetItem(
      regId: 1,
      type: SearchItemType.supplement,
      itemId: 10,
      itemName: '테스트 영양제',
      ingredients: [
        CabinetIngredient(ingredientId: 1, ingredientName: '비타민 C'),
      ],
    ),
  ];
  final deleted = <int>[];

  @override
  Future<List<CabinetItem>> getMyPills() async {
    if (loadError != null) throw loadError!;
    return List.of(items);
  }

  @override
  Future<void> deleteMyPill(int regId) async {
    if (deleteError != null) throw deleteError!;
    deleted.add(regId);
    items.removeWhere((item) => item.regId == regId);
  }
}

void main() {
  Future<void> open(WidgetTester tester, FakeMedicationApi api) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MyMedicationScreen(medicationApi: api)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('API failure is not an empty cabinet and retry restores cards', (
    tester,
  ) async {
    final api = FakeMedicationApi()..loadError = ApiException(503, '서버 점검');
    await open(tester, api);
    expect(find.text('약장 조회 실패: 서버 점검'), findsOneWidget);
    expect(find.text('등록된 항목이 없습니다'), findsNothing);
    api.loadError = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('테스트 영양제'), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
  });

  testWidgets('network errors show retry instead of escaping the screen', (
    tester,
  ) async {
    await open(tester, FakeMedicationApi()..loadError = Exception('offline'));
    expect(find.text('다시 시도'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ingredient search ignores spaces and case', (tester) async {
    await open(tester, FakeMedicationApi());
    await tester.enterText(find.byType(TextField), '비타민C');
    await tester.pumpAndSettle();
    expect(find.text('테스트 영양제'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '해당없는성분');
    await tester.pumpAndSettle();
    expect(find.text('테스트 영양제'), findsNothing);
  });

  testWidgets('delete removes the card only after API success', (tester) async {
    final api = FakeMedicationApi();
    await open(tester, api);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(api.deleted, [1]);
    expect(find.text('테스트 영양제'), findsNothing);
    expect(find.text('등록된 항목이 없습니다'), findsOneWidget);
  });

  testWidgets('failed deletion keeps the card and shows feedback', (
    tester,
  ) async {
    final api = FakeMedicationApi()..deleteError = Exception('offline');
    await open(tester, api);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('테스트 영양제'), findsOneWidget);
    expect(api.deleted, isEmpty);
    expect(find.textContaining('삭제하지 못했습니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
