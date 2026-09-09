import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/medicine_alternative_api.dart';
import '../../theme/app_theme.dart';

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
  List<MedicineAlternative> _alternatives = [];

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
        setState(() => _alternatives = result);
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
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Text(
                      '\'${widget.medicineName}\'와(과) 같은 성분을 가진 약이에요',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      _MessageCard(
                        icon: Icons.priority_high_rounded,
                        color: AppColors.danger,
                        text: _errorMessage!,
                      )
                    else if (_alternatives.isEmpty)
                      const _MessageCard(
                        icon: Icons.info_outline_rounded,
                        color: AppColors.muted,
                        text:
                            '현재 등록된 데이터 기준으로 같은 성분을 가진 다른 약을 찾지 못했습니다.\n'
                            '성분 정보가 없거나 유사 약품이 없는 경우일 수 있어요.',
                      )
                    else ...[
                      if (_alternatives.any((alt) => alt.isAiSuggested))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '💡 DB에 등록된 성분 정보가 부족해 AI가 대신 추천한 결과예요. '
                            '복용 전 반드시 약사·의사와 확인하세요.',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF7C5CFC),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ..._alternatives.map(_buildCard),
                    ],
                  ],
                ),
              ),
      ),
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
              if (alt.isAiSuggested)
                _Badge(
                  label: 'AI 추천',
                  color: const Color(0xFF7C5CFC),
                  background: const Color(0xFF7C5CFC).withValues(alpha: 0.10),
                ),
              const SizedBox(width: 6),
              if (alt.hasCabinetConflict)
                _Badge(
                  label: '병용주의',
                  color: AppColors.danger,
                  background: AppColors.danger.withValues(alpha: 0.10),
                )
              else
                _Badge(
                  label: '충돌 없음',
                  color: AppColors.accent,
                  background: AppColors.accent.withValues(alpha: 0.12),
                ),
            ],
          ),
          if (alt.manufacturer != null && alt.manufacturer!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(alt.manufacturer!, style: AppTextStyles.caption),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: alt.sharedIngredients
                .map(
                  (name) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (alt.isAiSuggested &&
              alt.aiReason != null &&
              alt.aiReason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              alt.aiReason!,
              style: AppTextStyles.caption.copyWith(height: 1.4),
            ),
          ],
          if (alt.hasCabinetConflict) ...[
            const SizedBox(height: 10),
            ...alt.conflictReasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '⚠️ $reason',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(radius: 18),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
