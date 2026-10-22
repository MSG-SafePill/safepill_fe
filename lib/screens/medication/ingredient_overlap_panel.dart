import 'package:flutter/material.dart';
import '../../services/ingredient_overlap.dart';

class IngredientOverlapPanel extends StatelessWidget {
  final List<IngredientOverlap> overlaps;
  final Set<int> registeredIds;

  const IngredientOverlapPanel({
    super.key,
    required this.overlaps,
    required this.registeredIds,
  });

  @override
  Widget build(BuildContext context) {
    final visible = overlaps
        .map(
          (overlap) => IngredientOverlap(
            ingredientName: overlap.ingredientName,
            relatedItems: Map.fromEntries(
              overlap.relatedItems.entries.where(
                (e) => registeredIds.contains(e.key),
              ),
            ),
          ),
        )
        .where((overlap) => overlap.relatedItems.isNotEmpty)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      leading: const Icon(Icons.layers_outlined, color: Color(0xFF9A4C00)),
      title: Text(
        '다른 제품과 성분 겹침 ${visible.length}건',
        style: const TextStyle(fontSize: 13),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        const Text(
          '약장 전체에서 선정된 5개 성분을 비교한 결과입니다. 실제 동시 복용이나 과다복용 여부를 뜻하지 않습니다.',
        ),
        for (final overlap in visible)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${overlap.ingredientName}: ${overlap.relatedItems.values.join(', ')}',
              ),
            ),
          ),
      ],
    );
  }
}
