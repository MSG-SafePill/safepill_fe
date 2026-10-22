import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/medicine_alternative_api.dart';
import '../../theme/app_theme.dart';

const _aiColor = Color(0xFF7C5CFC);
const _efficacyColor = Color(0xFF5B7BD5);

class MedicineAlternativesScreen extends StatefulWidget {
  const MedicineAlternativesScreen({
    super.key,
    required this.medicineId,
    required this.medicineName,
  });

  final int medicineId;
  final String medicineName;

  @override
  State<MedicineAlternativesScreen> createState() =>
      _MedicineAlternativesScreenState();
}

class _MedicineAlternativesScreenState
    extends State<MedicineAlternativesScreen> {
  final MedicineAlternativeApi _api = MedicineAlternativeApi();
  bool _isLoading = true;
  String? _errorMessage;
  AlternativeResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _api.getAlternatives(widget.medicineId);
      if (mounted) {
        setState(() => _result = result);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = '서버와 연결할 수 없습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('대체 가능한 약', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),
      body: SafeArea(
        child: _isLoading
            ? const _LoadingView()
            : _errorMessage != null
            ? _ErrorView(message: _errorMessage!, onRetry: _load)
            : RefreshIndicator(onRefresh: _load, child: _buildContent()),
      ),
    );
  }

  Widget _buildContent() {
    final result = _result!;
    final sections = <_SectionSpec>[
      _SectionSpec(
        type: AlternativeMatchType.sameIngredient,
        title: '같은 성분의 약',
        subtitle: '성분이 모두 같아서 가장 가까운 대체 후보예요.',
        color: AppColors.accent,
        icon: Icons.verified_rounded,
      ),
      _SectionSpec(
        type: AlternativeMatchType.partialIngredient,
        title: '주성분이 일부 같은 약',
        subtitle: '같은 성분이 들어 있지만 다른 성분도 함께 들어 있어요.',
        color: AppColors.primary,
        icon: Icons.join_inner_rounded,
      ),
      _SectionSpec(
        type: AlternativeMatchType.sameEfficacyGroup,
        title: '비슷한 효능의 약',
        subtitle: '성분은 달라도 같은 약효군(ATC)으로 분류돼요.',
        color: _efficacyColor,
        icon: Icons.category_rounded,
      ),
      _SectionSpec(
        type: AlternativeMatchType.aiSuggested,
        title: 'AI 추천 (참고용)',
        subtitle: 'DB에서 후보를 찾지 못해 AI가 대신 추천했어요.',
        color: _aiColor,
        icon: Icons.auto_awesome_rounded,
      ),
    ];

    final children = <Widget>[
      _TargetCard(target: result.target),
      const SizedBox(height: 18),
    ];

    if (result.alternatives.isEmpty) {
      children.add(_EmptyCard(aiUnavailable: result.aiUnavailable));
    } else {
      for (final section in sections) {
        final items = result.alternatives
            .where((alt) => alt.matchType == section.type)
            .toList();
        if (items.isEmpty) continue;
        children.add(_SectionHeader(spec: section, count: items.length));
        children.addAll(items.map(_buildCard));
        children.add(const SizedBox(height: 6));
      }
    }
    children.add(const _Disclaimer());

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: children,
    );
  }

  Widget _buildCard(MedicineAlternative alt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card(radius: 18),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  alt.medicineName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (alt.hasCabinetConflict)
                _Badge(
                  label: '병용주의',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                )
              else
                const _Badge(
                  label: '규칙상 문제 없음',
                  icon: Icons.check_circle_rounded,
                  color: Color(0xFF1FB5A5),
                ),
            ],
          ),
          if (alt.manufacturer != null && alt.manufacturer!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(alt.manufacturer!, style: AppTextStyles.caption),
          ],
          if (alt.isAiSuggested) ...[
            const SizedBox(height: 8),
            _AiVerification(alt: alt),
          ],
          if (alt.ingredientSummaries.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: alt.ingredientSummaries
                  .map(
                    (summary) => _IngredientChip(
                      label: summary,
                      highlighted: alt.sharedIngredients.any(
                        (name) => summary.startsWith(name),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (alt.dosageDiffers) ...[
            const SizedBox(height: 10),
            const _Notice(
              icon: Icons.scale_rounded,
              color: AppColors.warning,
              text: '같은 성분이지만 함량이 달라요. 용량은 약사에게 꼭 확인하세요.',
            ),
          ],
          if (alt.isAiSuggested &&
              alt.aiReason != null &&
              alt.aiReason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(alt.aiReason!, style: AppTextStyles.caption),
          ],
          if (alt.hasCabinetConflict) ...[
            const SizedBox(height: 10),
            ...alt.conflictReasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _Notice(
                  icon: Icons.error_outline_rounded,
                  color: AppColors.danger,
                  text: reason,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionSpec {
  const _SectionSpec({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String type;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('대체약을 찾는 중이에요', style: AppTextStyles.body),
          SizedBox(height: 4),
          Text('DB에 후보가 없으면 AI 추천을 위해 몇 초 걸릴 수 있어요', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: AppColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.target});

  final AlternativeTarget target;

  @override
  Widget build(BuildContext context) {
    final cancelled = !target.permitActive;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.blueGradient(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기준 약',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            target.medicineName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          if (target.manufacturer != null && target.manufacturer!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                target.manufacturer!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (target.ingredients.isEmpty)
            Text(
              '등록된 성분 정보가 없어요',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: target.ingredients
                  .map(
                    (ingredient) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        ingredient,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          if (cancelled) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.report_gmailerrorred_rounded,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '이 약은 허가가 ${target.permitStatus ?? '종료'}'
                      '${target.cancelDate != null ? ' (${target.cancelDate})' : ''}'
                      '된 제품이에요. 아래 대체 후보를 약사와 상담해보세요.',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.spec, required this.count});

  final _SectionSpec spec;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: spec.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(spec.icon, size: 17, color: spec.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${spec.title} · $count',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 1),
                Text(spec.subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({required this.label, required this.highlighted});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primaryLight : const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? AppColors.primary : AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _AiVerification extends StatelessWidget {
  const _AiVerification({required this.alt});

  final MedicineAlternative alt;

  @override
  Widget build(BuildContext context) {
    final verified = alt.isVerifiedInDb;
    return Row(
      children: [
        _Badge(label: 'AI 추천', icon: Icons.auto_awesome_rounded, color: _aiColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            verified
                ? '국내 의약품 DB에서 등록을 확인했어요'
                : '우리 DB에 없는 이름이에요 — 약사·의사에게 꼭 확인하세요',
            style: AppTextStyles.caption.copyWith(
              color: verified ? const Color(0xFF1FB5A5) : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.aiUnavailable});

  final bool aiUnavailable;

  @override
  Widget build(BuildContext context) {
    final message = aiUnavailable
        ? '등록된 데이터에서 대체 후보를 찾지 못했고,\nAI 추천 서비스도 지금은 연결되지 않아요.\n약사에게 같은 성분의 다른 제품을 문의해보세요.'
        : '등록된 데이터에서 대체할 수 있는 약을 찾지 못했어요.\n약사에게 같은 성분의 다른 제품을 문의해보세요.';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppDecorations.card(radius: 18),
      child: Column(
        children: [
          Icon(
            aiUnavailable
                ? Icons.cloud_off_rounded
                : Icons.search_off_rounded,
            color: AppColors.muted,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        '※ 대체약 정보는 참고용이에요. "규칙상 문제 없음"은 등록된 병용·중복 규칙에 걸리지 않았다는 뜻이며 '
        '안전을 보증하지 않아요. 성분·함량이 같아도 사람에 따라 맞지 않을 수 있으니 '
        '복용 전 반드시 의사·약사와 상담하세요.',
        style: AppTextStyles.caption.copyWith(height: 1.5),
      ),
    );
  }
}
