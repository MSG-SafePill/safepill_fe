import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safepill_frontend/services/medication_api.dart';
import 'package:safepill_frontend/services/ingredient_overlap.dart';
import 'package:safepill_frontend/screens/medication/ingredient_overlap_panel.dart';

void main() {
  test('parses overlap response and supports older servers', () {
    final item = CabinetItem.fromJson({
      'regId': 1,
      'itemId': 10,
      'ingredientOverlaps': [
        {
          'ingredientName': '칼슘',
          'relatedItems': [
            {'regId': 2, 'itemName': '칼슘 제품'},
          ],
        },
      ],
    });
    expect(item.ingredientOverlaps.single.relatedItems[2], '칼슘 제품');
    expect(
      CabinetItem.fromJson({'regId': 1, 'itemId': 10}).ingredientOverlaps,
      isEmpty,
    );
  });

  testWidgets(
    'shows related product and removes stale overlap after deletion',
    (tester) async {
      const overlaps = [
        IngredientOverlap(ingredientName: '칼슘', relatedItems: {2: '칼슘 제품'}),
      ];
      Future<void> render(Set<int> ids) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: IngredientOverlapPanel(
                overlaps: overlaps,
                registeredIds: ids,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await render({1, 2});
      await tester.tap(find.text('다른 제품과 성분 겹침 1건'));
      await tester.pumpAndSettle();
      expect(find.text('칼슘: 칼슘 제품'), findsOneWidget);
      expect(find.textContaining('실제 동시 복용'), findsOneWidget);
      await render({1});
      expect(find.text('다른 제품과 성분 겹침 1건'), findsNothing);
      expect(find.text('칼슘: 칼슘 제품'), findsNothing);
    },
  );
}
