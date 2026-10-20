import 'package:flutter/material.dart';
import '../../services/ingredient_guide.dart';

class IngredientGuidePanel extends StatelessWidget {
  final IngredientGuideAssessment assessment;

  const IngredientGuidePanel({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    final hasWarnings = assessment.warnings.isNotEmpty;
    final color = hasWarnings
        ? const Color(0xFF9A4C00)
        : const Color(0xFF65758A);
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      leading: Icon(
        hasWarnings ? Icons.warning_amber_rounded : Icons.info_outline,
        color: color,
      ),
      title: Text(
        assessment.statusLabel,
        style: TextStyle(color: color, fontSize: 13),
      ),
      children: [
        const Text(
          '선정된 5개 성분에 대한 일반 안내입니다. 실제 과다복용이나 의존 여부를 판정하지 않습니다. '
          '처방·제품 설명서를 따르고 복용 변경은 의사·약사와 상의하세요.',
          style: TextStyle(fontSize: 12, color: Color(0xFF65758A)),
        ),
        for (final warning in assessment.warnings)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${warning.ingredientName} · ${warning.title}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 6),
                Text(warning.summary),
                const SizedBox(height: 6),
                Text(warning.detail, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 8),
                SelectableText(
                  '출처: ${warning.sourceName}\n${warning.sourceUrl}\n'
                  '자료 확인일: ${warning.reviewedAt}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF65758A),
                  ),
                ),
              ],
            ),
          ),
        if (assessment.unmatchedIngredients.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '가이드 미확인 성분: ${assessment.unmatchedIngredients.join(', ')}',
            ),
          ),
        if (assessment.status != 'AVAILABLE')
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('가이드가 없거나 정보가 부족하다고 안전함을 의미하지는 않습니다.'),
          ),
      ],
    );
  }
}
