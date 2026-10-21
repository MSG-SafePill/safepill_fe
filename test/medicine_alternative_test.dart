import 'package:flutter_test/flutter_test.dart';
import 'package:safepill_frontend/services/medicine_alternative_api.dart';

void main() {
  test('parses target, grouped alternatives, dosage and conflict info', () {
    final result = AlternativeResult.fromJson({
      'target': {
        'id': 501,
        'medicineName': '써스펜데이정',
        'ingredients': ['아세트아미노펜 500mg'],
        'permitActive': false,
        'permitStatus': '취하',
        'cancelDate': '2023-12-07',
      },
      'alternatives': [
        {
          'id': 7,
          'medicineName': '카엘정',
          'matchType': 'PARTIAL_INGREDIENT',
          'sharedIngredients': ['아세트아미노펜'],
          'ingredientSummaries': ['아세트아미노펜 200mg', '카페인무수물 10mg'],
          'dosageDiffers': true,
          'hasCabinetConflict': true,
          'conflictReasons': ['아세트아미노펜 성분이 이미 복용 중인 약에도 들어 있어요.'],
        },
      ],
      'aiUnavailable': false,
    });

    expect(result.target.permitActive, isFalse);
    expect(result.target.cancelDate, '2023-12-07');
    final alt = result.alternatives.single;
    expect(alt.matchType, AlternativeMatchType.partialIngredient);
    expect(alt.dosageDiffers, isTrue);
    expect(alt.hasCabinetConflict, isTrue);
    expect(alt.ingredientSummaries, hasLength(2));
  });

  test('AI suggestion without matchType falls back to the AI group', () {
    final alt = MedicineAlternative.fromJson({
      'medicineName': '부스코판당의정',
      'aiSuggested': true,
      'verifiedInDb': false,
    });

    expect(alt.matchType, AlternativeMatchType.aiSuggested);
    expect(alt.id, isNull);
    expect(alt.isVerifiedInDb, isFalse);
  });

  test('missing fields do not crash and the target defaults to active', () {
    final result = AlternativeResult.fromJson({});

    expect(result.target.permitActive, isTrue);
    expect(result.alternatives, isEmpty);
    expect(result.aiUnavailable, isFalse);
  });
}
