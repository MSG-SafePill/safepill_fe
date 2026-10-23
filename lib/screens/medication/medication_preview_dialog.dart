import 'package:flutter/material.dart';
import '../../services/medication_preview.dart';
import 'ingredient_guide_panel.dart';

Future<bool> showMedicationPreview(
  BuildContext context,
  List<MedicationPreview> previews,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('등록 전 성분 확인'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '선정된 5개 성분을 기존 약장과 비교한 안내입니다. 실제 동시 복용이나 과다복용을 판정하지 않습니다.',
                  ),
                  if (previews.length > 1)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '이번에 선택한 제품끼리의 성분 겹침은 등록 후 마이약장에서 확인할 수 있습니다.',
                      ),
                    ),
                  for (final preview in previews) ...[
                    const Divider(height: 24),
                    Text(
                      preview.itemName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (preview.alreadyRegistered)
                      const Text('이미 약장에 등록된 제품입니다.'),
                    for (final guide in preview.guide.warnings)
                      Text('${guide.ingredientName} · ${guide.title}'),
                    IngredientGuidePanel(assessment: preview.guide),
                    if (preview.overlaps.isEmpty)
                      const Text('확인된 성분 겹침 없음 · 안전 판정이 아닙니다.'),
                    for (final overlap in preview.overlaps)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${overlap.ingredientName} 겹침: ${overlap.relatedItems.values.join(', ')}',
                        ),
                      ),
                    if (preview.unverifiedCabinetItems > 0)
                      Text(
                        '기존 약장 ${preview.unverifiedCabinetItems}개 제품은 성분 가이드가 일부 또는 전부 미확인 상태입니다.',
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed:
                  previews.isEmpty || previews.every((p) => p.alreadyRegistered)
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('확인 후 등록'),
            ),
          ],
        ),
      ) ??
      false;
}
