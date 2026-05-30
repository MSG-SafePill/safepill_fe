import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/medication_api.dart';
import '../../services/ocr_registration_api.dart';
import '../../services/vision_api.dart';
import '../../theme/app_theme.dart';
import '../medication/add_medication.dart';
import 'scan_mode.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({
    super.key,
    required this.mode,
    required this.imageBytes,
    required this.pillCandidates,
    required this.prescriptionItems,
    this.errorMessage,
  });

  final ScanMode mode;
  final Uint8List imageBytes;
  final List<PillIdentifyCandidate> pillCandidates;
  final List<PrescriptionOcrItem> prescriptionItems;
  final String? errorMessage;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final OcrRegistrationApi _ocrRegistrationApi = OcrRegistrationApi();
  final Map<String, MedicationMatchCandidate> _selectedOcrCandidates = {};
  bool _isRegistering = false;

  bool get _hasResults {
    if (widget.errorMessage != null) {
      return false;
    }
    return widget.mode == ScanMode.pill
        ? widget.pillCandidates.isNotEmpty
        : widget.prescriptionItems.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('인식 결과'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: (_hasResults ? AppColors.primary : Colors.redAccent)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _hasResults ? Icons.check_rounded : Icons.priority_high_rounded,
                color: _hasResults ? AppColors.primary : Colors.redAccent,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.memory(widget.imageBytes, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 26),
          if (widget.mode == ScanMode.pill) ..._buildPillResults(),
          if (widget.mode == ScanMode.prescription)
            ..._buildPrescriptionResults(),
        ],
      ),
    );
  }

  String get _title {
    if (_hasResults) {
      return '분석이 완료되었습니다';
    }
    return widget.errorMessage == null ? '식별된 결과가 없습니다' : '분석에 실패했습니다';
  }

  String get _subtitle {
    if (widget.errorMessage != null) {
      return widget.errorMessage!;
    }
    if (widget.mode == ScanMode.pill) {
      return _hasResults ? '사진 속 약 후보를 찾았습니다.' : '현재는 등록된 샘플 약만 식별할 수 있습니다.';
    }
    return _hasResults ? '사진에서 약 정보를 추출했습니다.' : '사진이 선명한지 확인해주세요.';
  }

  List<Widget> _buildPillResults() {
    if (!_hasResults) {
      return [const _EmptyResult('다시 촬영하거나 다른 이미지를 선택해주세요.')];
    }
    return [
      const _ResultTitle('식별된 약 후보'),
      const SizedBox(height: 12),
      ...widget.pillCandidates.map(
        (item) => _ResultCard(
          icon: Icons.medication_rounded,
          title: item.pillName,
          subtitle: [
            '신뢰도 ${(item.confidence * 100).toStringAsFixed(1)}%',
            item.manufacturer,
          ].whereType<String>().join(' | '),
          trailing: item.itemId == null
              ? Icons.chevron_right_rounded
              : Icons.add_circle_outline_rounded,
          onTap: () {
            if (item.itemId != null && item.itemType != null) {
              _registerSingleCandidate(item);
            } else {
              _openAddMedication(item.pillName);
            }
          },
        ),
      ),
      const SizedBox(height: 8),
      _PrimaryActionButton(
        label: '나의 약장에 추가',
        icon: Icons.add_rounded,
        onPressed: widget.pillCandidates.isEmpty
            ? null
            : () => _openAddMedication(widget.pillCandidates.first.pillName),
      ),
    ];
  }

  List<Widget> _buildPrescriptionResults() {
    if (!_hasResults) {
      return [const _EmptyResult('다시 촬영하거나 다른 이미지를 선택해주세요.')];
    }
    return [
      const _ResultTitle('OCR 추출 결과'),
      const SizedBox(height: 12),
      ...widget.prescriptionItems.map(_buildPrescriptionItem),
      if (widget.prescriptionItems.any(
        (item) => item.matchCandidates.isNotEmpty,
      )) ...[
        const SizedBox(height: 10),
        _PrimaryActionButton(
          label: _isRegistering ? '등록 중...' : '선택한 OCR 결과 등록',
          icon: Icons.playlist_add_check_rounded,
          onPressed: _isRegistering ? null : _registerSelectedOcrItems,
        ),
      ],
    ];
  }

  Widget _buildPrescriptionItem(PrescriptionOcrItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card(radius: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
              ),
              title: Text(item.medicineName),
              subtitle: Text(
                [
                  item.dosage,
                  item.frequency,
                  item.mealTiming,
                  item.days,
                ].whereType<String>().join(' | '),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => _openAddMedication(item.medicineName),
              ),
            ),
            if (item.matchCandidates.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: DropdownButtonFormField<String>(
                  initialValue:
                      _selectedOcrCandidates[item.medicineName]?.selectionKey,
                  decoration: InputDecoration(
                    labelText: '등록 후보 선택',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: item.matchCandidates
                      .map(
                        (candidate) => DropdownMenuItem(
                          value: candidate.selectionKey,
                          child: Text(candidate.itemName),
                        ),
                      )
                      .toList(),
                  onChanged: (selectionKey) {
                    setState(() {
                      OcrMatchCandidate? candidate;
                      for (final matchCandidate in item.matchCandidates) {
                        if (matchCandidate.selectionKey == selectionKey) {
                          candidate = matchCandidate;
                          break;
                        }
                      }
                      if (candidate != null) {
                        _selectedOcrCandidates[item.medicineName] =
                            MedicationMatchCandidate(
                              itemType: candidate.itemType == 'SUPPLEMENT'
                                  ? SearchItemType.supplement
                                  : SearchItemType.medicine,
                              itemId: candidate.itemId,
                              itemName: candidate.itemName,
                              manufacturer: candidate.manufacturer,
                              score: candidate.score,
                            );
                      }
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openAddMedication(String keyword) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(initialKeyword: keyword),
      ),
    );
  }

  Future<void> _registerSingleCandidate(PillIdentifyCandidate item) async {
    final candidate = MedicationMatchCandidate(
      itemType: item.itemType == 'SUPPLEMENT'
          ? SearchItemType.supplement
          : SearchItemType.medicine,
      itemId: item.itemId!,
      itemName: item.pillName,
      manufacturer: item.manufacturer,
      score: item.confidence,
    );
    await _registerSelections([
      OcrRegistrationSelection(candidate: candidate, schedules: const []),
    ]);
  }

  Future<void> _registerSelectedOcrItems() async {
    final selections = <OcrRegistrationSelection>[];
    for (final item in widget.prescriptionItems) {
      final candidate = _selectedOcrCandidates[item.medicineName];
      if (candidate != null) {
        selections.add(
          OcrRegistrationSelection(
            candidate: candidate,
            schedules: item.scheduleSuggestions,
          ),
        );
      }
    }
    if (selections.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('등록할 후보를 선택해주세요.')));
      return;
    }
    await _registerSelections(selections);
  }

  Future<void> _registerSelections(
    List<OcrRegistrationSelection> selections,
  ) async {
    setState(() => _isRegistering = true);
    try {
      final results = await _ocrRegistrationApi.registerSelections(selections);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${results.length}개 항목이 등록되었습니다.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('등록 실패: ${e.message}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }
}

class _ResultTitle extends StatelessWidget {
  const _ResultTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.sectionTitle.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(radius: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(color: AppColors.muted),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IconData trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card(radius: 16),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        trailing: Icon(trailing, color: AppColors.primary),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
