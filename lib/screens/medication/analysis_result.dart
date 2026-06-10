import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/interaction_api.dart';
import '../../theme/app_theme.dart';

class AnalysisResult extends StatefulWidget {
  const AnalysisResult({super.key});

  @override
  State<AnalysisResult> createState() => _AnalysisResultState();
}

class _AnalysisResultState extends State<AnalysisResult> {
  final InteractionApi _interactionApi = InteractionApi();
  bool _isLoading = true;
  AiInteractionAnalysis? _analysis;
  String? _errorMessage;

  bool get isDanger {
    final risk = _analysis?.riskLevel;
    return risk == 'DANGER' || risk == 'WARNING' || risk == 'CAUTION';
  }

  Color get _statusColor {
    final risk = _analysis?.riskLevel;
    if (risk == 'DANGER') return AppColors.danger;
    if (risk == 'WARNING' || risk == 'CAUTION') return AppColors.warning;
    return AppColors.accent;
  }

  String get _statusTitle {
    final risk = _analysis?.riskLevel;
    if (risk == 'DANGER') return '위험해요';
    if (risk == 'WARNING' || risk == 'CAUTION') return '주의가 필요해요';
    return '안전해요';
  }

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final analysis = await _interactionApi.analyzeMyCabinetWithAi();
      if (mounted) {
        setState(() => _analysis = analysis);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('분석 결과', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: AppDecorations.card(),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            isDanger
                                ? Icons.warning_amber_rounded
                                : Icons.health_and_safety_rounded,
                            color: _statusColor,
                            size: 42,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _statusTitle,
                                style: AppTextStyles.screenTitle.copyWith(
                                  color: _statusColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _errorMessage ??
                                    analysis?.summary ??
                                    (isDanger
                                        ? '함께 복용 시 주의가 필요한 조합이 있습니다.'
                                        : '현재 복용 중인 약은 상호작용 위험이 없습니다.'),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.navy,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('분석 요약', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 12),
                  Container(
                    decoration: AppDecorations.card(radius: 16),
                    child: Column(
                      children: [
                        _SummaryRow(
                          icon: Icons.medication_rounded,
                          label: '총 약품 수',
                          value: '${analysis?.evidence.length ?? 0}개',
                        ),
                        const Divider(height: 1, color: AppColors.line),
                        _SummaryRow(
                          icon: Icons.sync_problem_rounded,
                          label: '상호작용 확인',
                          value: '${analysis?.warnings.length ?? 0}건',
                        ),
                        const Divider(height: 1, color: AppColors.line),
                        _SummaryRow(
                          icon: Icons.local_hospital_outlined,
                          label: '주의 필요 항목',
                          value: isDanger
                              ? '${analysis?.warnings.length ?? 1}개'
                              : '0개',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (analysis?.warnings.isNotEmpty == true) ...[
                    const Text('상호작용 경고', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    ...analysis!.warnings.map(
                      (warning) =>
                          _WarningCard(warning: warning, color: _statusColor),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (analysis?.evidence.isNotEmpty == true) ...[
                    const Text('복용 약품', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    Container(
                      decoration: AppDecorations.card(radius: 16),
                      child: Column(
                        children: analysis!.evidence
                            .map((item) => _EvidenceRow(evidence: item))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (analysis != null) ...[
                    _InfoSection(
                      title: '복약 관리 방법',
                      icon: Icons.checklist_rounded,
                      items: analysis.recommendations,
                    ),
                    _InfoSection(
                      title: '복용 시간 안내',
                      icon: Icons.schedule_rounded,
                      items: analysis.scheduleRecommendations,
                    ),
                    _InfoSection(
                      title: '음식/영양제 주의',
                      icon: Icons.restaurant_rounded,
                      items: analysis.foodWarnings,
                    ),
                    _InfoSection(
                      title: '상담이 필요한 경우',
                      icon: Icons.local_hospital_rounded,
                      items: analysis.consultationGuidance,
                    ),
                  ],

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      analysis?.disclaimer.isNotEmpty == true
                          ? analysis!.disclaimer
                          : '최종 판단은 반드시 의사 또는 약사와 상담하십시오.',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.warning, required this.color});

  final AiInteractionWarning warning;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(radius: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warning.title ?? '주의 항목',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (warning.items.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    warning.items.join(' · '),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  warning.reason ?? '복용 전 전문가 상담이 필요합니다.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.navy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.evidence});

  final AiInteractionEvidence evidence;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: AppColors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidence.source ?? '등록 약품',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (evidence.text?.isNotEmpty == true)
                  Text(
                    evidence.text!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
          Text(
            '안전',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card(radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.sectionTitle),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: AppTextStyles.body),
                    Expanded(child: Text(item, style: AppTextStyles.body)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
