import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../medication/add_medication.dart';
import '../../services/api_client.dart';
import '../../services/medication_api.dart';
import '../../services/ocr_registration_api.dart';
import '../../services/vision_api.dart';
import '../../theme/app_theme.dart';

enum ScanMode { pill, prescription }

class ScanMedicationScreen extends StatefulWidget {
  const ScanMedicationScreen({super.key});

  @override
  State<ScanMedicationScreen> createState() => _ScanMedicationScreenState();
}

class _ScanMedicationScreenState extends State<ScanMedicationScreen> {
  final ImagePicker _picker = ImagePicker();
  final VisionApi _visionApi = VisionApi();
  final OcrRegistrationApi _ocrRegistrationApi = OcrRegistrationApi();

  ScanMode _mode = ScanMode.pill;
  bool _isLoading = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  List<PillIdentifyCandidate> _pillCandidates = [];
  List<PrescriptionOcrItem> _prescriptionItems = [];
  final Map<String, MedicationMatchCandidate> _selectedOcrCandidates = {};
  bool _isRegistering = false;

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null) {
      return;
    }
    final imageBytes = await image.readAsBytes();

    setState(() {
      _selectedImage = image;
      _selectedImageBytes = imageBytes;
      _isLoading = true;
      _pillCandidates = [];
      _prescriptionItems = [];
      _selectedOcrCandidates.clear();
    });

    try {
      if (_mode == ScanMode.pill) {
        final candidates = await _visionApi.identifyPill(image);
        if (mounted) {
          setState(() => _pillCandidates = candidates);
        }
      } else {
        final items = await _visionApi.scanPrescription(image);
        if (mounted) {
          setState(() => _prescriptionItems = items);
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(duration: const Duration(seconds: 2), content: Text('분석 실패: ${e.message}')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(duration: Duration(seconds: 2), content: Text('이미지 분석 서버와 연결할 수 없습니다.')));
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
      backgroundColor: const Color(0xFF101824),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: null,
                    icon: const Icon(Icons.flash_on_rounded),
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: MediaQuery.of(context).size.height * 0.48,
            margin: const EdgeInsets.symmetric(horizontal: 0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF414852), Color(0xFFB7B7B2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _selectedImageBytes == null
                      ? Center(
                          child: Icon(
                            _mode == ScanMode.pill
                                ? Icons.medication_liquid_rounded
                                : Icons.description_rounded,
                            color: Colors.white.withValues(alpha: 0.78),
                            size: 116,
                          ),
                        )
                      : Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                ),
                if (_selectedImageBytes != null)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.20),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.28),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                if (_selectedImage != null)
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 22,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedImage!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const _ScanCorner(top: 46, left: 38),
                const _ScanCorner(top: 46, right: 38, flipX: true),
                const _ScanCorner(bottom: 46, left: 38, flipY: true),
                const _ScanCorner(
                  bottom: 46,
                  right: 38,
                  flipX: true,
                  flipY: true,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
            child: Column(
              children: [
                SegmentedButton<ScanMode>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Colors.white.withValues(alpha: 0.08);
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary;
                      }
                      return Colors.white;
                    }),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ScanMode.pill,
                      icon: Icon(Icons.medication_rounded),
                      label: Text('낱알'),
                    ),
                    ButtonSegment(
                      value: ScanMode.prescription,
                      icon: Icon(Icons.receipt_long_rounded),
                      label: Text('처방전'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _mode = value.first;
                            _pillCandidates = [];
                            _prescriptionItems = [];
                            _selectedOcrCandidates.clear();
                          });
                        },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RoundActionButton(
                      icon: Icons.photo_library_rounded,
                      onTap: _isLoading
                          ? null
                          : () => _pickAndAnalyze(ImageSource.gallery),
                    ),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () => _pickAndAnalyze(ImageSource.camera),
                      child: Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    _RoundActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: null,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  '약이 화면에 잘 보이도록 배치해주세요',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_isLoading && _mode == ScanMode.pill) ..._buildPillResults(),
          if (!_isLoading && _mode == ScanMode.prescription)
            ..._buildPrescriptionResults(),
        ],
      ),
    );
  }

  List<Widget> _buildPillResults() {
    if (_selectedImage == null) {
      return [const _ScanEmptyText('낱알을 촬영하면 약 후보가 표시됩니다.')];
    }
    if (_pillCandidates.isEmpty) {
      return [const _ScanEmptyText('식별된 후보가 없습니다.')];
    }
    return [
      const _ResultTitle('식별 후보'),
      const SizedBox(height: 12),
      ..._pillCandidates.map(
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
    ];
  }

  List<Widget> _buildPrescriptionResults() {
    if (_selectedImage == null) {
      return [const _ScanEmptyText('처방전이나 약 봉투를 촬영하면 추출 결과가 표시됩니다.')];
    }
    if (_prescriptionItems.isEmpty) {
      return [const _ScanEmptyText('추출된 약 정보가 없습니다.')];
    }
    return [
      const _ResultTitle('OCR 추출 결과'),
      const SizedBox(height: 12),
      ..._prescriptionItems.map(
        (item) => Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          decoration: AppDecorations.card(radius: 18),
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
                      initialValue: _selectedOcrCandidates[item.medicineName]
                          ?.selectionKey,
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
        ),
      ),
      if (_prescriptionItems.any(
        (item) => item.matchCandidates.isNotEmpty,
      )) ...[
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isRegistering ? null : _registerSelectedOcrItems,
          icon: const Icon(Icons.playlist_add_check_rounded),
          label: Text(_isRegistering ? '등록 중...' : '선택한 OCR 결과 등록'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    ];
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
    for (final item in _prescriptionItems) {
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
      ).showSnackBar(const SnackBar(duration: Duration(seconds: 2), content: Text('등록할 후보를 선택해주세요.')));
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
          SnackBar(duration: const Duration(seconds: 2), content: Text('${results.length}개 항목이 등록되었습니다.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(duration: const Duration(seconds: 2), content: Text('등록 실패: ${e.message}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }
}

class _ScanCorner extends StatelessWidget {
  const _ScanCorner({
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.flipX = false,
    this.flipY = false,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final bool flipX;
  final bool flipY;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(flipX ? -1 : 1, flipY ? -1 : 1, 1),
        child: CustomPaint(size: const Size(58, 58), painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 14)
      ..quadraticBezierTo(0, 0, 14, 0)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _ResultTitle extends StatelessWidget {
  const _ResultTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Text(
        text,
        style: AppTextStyles.sectionTitle.copyWith(color: Colors.white),
      ),
    );
  }
}

class _ScanEmptyText extends StatelessWidget {
  const _ScanEmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: AppDecorations.card(radius: 18),
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
