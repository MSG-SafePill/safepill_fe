import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safepill_frontend/screens/medication/add_medication.dart';
import 'package:safepill_frontend/services/medication_api.dart';
import 'package:safepill_frontend/services/medication_preview.dart';

class PreviewApi extends MedicationApi {
  bool fail = false;
  bool registered = false;
  int adds = 0;
  int previews = 0;
  Completer<MedicationPreview>? pending;
  final product = MedicationSearchItem(
    type: SearchItemType.medicine,
    id: 1,
    name: '테스트 제품',
  );

  MedicationPreview response() => MedicationPreview.fromJson({
    'itemName': product.name,
    'alreadyRegistered': registered,
    'ingredientGuide': {'status': 'NO_INGREDIENT_DATA', 'warnings': []},
    'ingredientOverlaps': [],
    'unverifiedCabinetItems': 1,
  });

  @override
  Future<MedicationSearchPage> searchPage(
    String keyword, {
    int page = 0,
    int size = 10,
    bool auth = false,
  }) async => MedicationSearchPage(
    items: [product],
    page: 0,
    size: 10,
    hasNext: false,
    totalElements: 1,
  );

  @override
  Future<MedicationPreview> previewMedication(MedicationSearchItem item) async {
    previews++;
    if (fail) throw Exception('offline');
    return pending == null ? response() : pending!.future;
  }

  @override
  Future<void> addToMyPills(
    MedicationSearchItem item, {
    int? supplyDays,
  }) async {
    adds++;
  }
}

void main() {
  Future<void> open(WidgetTester tester, PreviewApi api) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMedicationScreen(
                    initialKeyword: '테스트',
                    medicationApi: api,
                  ),
                ),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('테스트 제품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마이약장에 추가하기'));
  }

  testWidgets(
    'preview cancellation never saves and later confirmation saves once',
    (tester) async {
      final api = PreviewApi();
      await open(tester, api);
      await tester.pumpAndSettle();
      expect(find.text('등록 전 성분 확인'), findsOneWidget);
      expect(find.textContaining('기존 약장 1개'), findsOneWidget);
      expect(api.adds, 0);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(api.adds, 0);
      await tester.tap(find.text('마이약장에 추가하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인 후 등록'));
      await tester.pumpAndSettle();
      expect(api.adds, 1);
      expect(api.previews, 2);
    },
  );

  testWidgets('preview failure does not save and can be retried', (
    tester,
  ) async {
    final api = PreviewApi()..fail = true;
    await open(tester, api);
    await tester.pumpAndSettle();
    expect(api.adds, 0);
    expect(find.text('등록 전 성분 확인'), findsNothing);
    api.fail = false;
    await tester.tap(find.text('마이약장에 추가하기'));
    await tester.pumpAndSettle();
    expect(find.text('등록 전 성분 확인'), findsOneWidget);
  });

  testWidgets('already registered preview prevents duplicate save', (
    tester,
  ) async {
    final api = PreviewApi()..registered = true;
    await open(tester, api);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '확인 후 등록'))
          .onPressed,
      isNull,
    );
    expect(api.adds, 0);
  });

  testWidgets('leaving while preview loads does not show a stale dialog', (
    tester,
  ) async {
    final api = PreviewApi()..pending = Completer<MedicationPreview>();
    await open(tester, api);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    api.pending!.complete(api.response());
    await tester.pumpAndSettle();
    expect(find.text('등록 전 성분 확인'), findsNothing);
    expect(api.adds, 0);
    expect(tester.takeException(), isNull);
  });
}
