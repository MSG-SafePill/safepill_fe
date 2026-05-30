import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../medication/add_medication.dart';
import '../../services/api_client.dart';
import '../../services/medication_api.dart';
import '../../services/ocr_registration_api.dart';
import '../../services/vision_api.dart';

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
  List<PillIdentifyCandidate> _pillCandidates = [];
  List<PrescriptionOcrItem> _prescriptionItems = [];
  final Map<String, MedicationMatchCandidate> _selectedOcrCandidates = {};
  bool _isRegistering = false;

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null) {
      return;
    }

    setState(() {
      _selectedImage = image;
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          '약 촬영',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<ScanMode>(
            segments: const [
              ButtonSegment(
                value: ScanMode.pill,
                icon: Icon(Icons.medication),
                label: Text('낱알'),
              ),
              ButtonSegment(
                value: ScanMode.prescription,
                icon: Icon(Icons.receipt_long),
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
          const SizedBox(height: 20),
          Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _selectedImage == null
                ? Icon(
                    _mode == ScanMode.pill
                        ? Icons.medication_liquid
                        : Icons.description,
                    color: const Color(0xFF2A8DE5),
                    size: 56,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF2ECC71),
                        size: 42,
                      ),
                      const SizedBox(height: 10),
                      Text(_selectedImage!.name, textAlign: TextAlign.center),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _pickAndAnalyze(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('촬영'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A8DE5),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _pickAndAnalyze(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('앨범'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading && _mode == ScanMode.pill) ..._buildPillResults(),
          if (!_isLoading && _mode == ScanMode.prescription)
            ..._buildPrescriptionResults(),
        ],
      ),
    );
  }

  List<Widget> _buildPillResults() {
    if (_selectedImage == null) {
      return [const Text('낱알을 촬영하면 약 후보가 표시됩니다.')];
    }
    if (_pillCandidates.isEmpty) {
      return [const Text('식별된 후보가 없습니다.')];
    }
    return [
      const Text(
        '식별 후보',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      ..._pillCandidates.map(
        (item) => Card(
          child: ListTile(
            onTap: () {
              if (item.itemId != null && item.itemType != null) {
                _registerSingleCandidate(item);
              } else {
                _openAddMedication(item.pillName);
              }
            },
            leading: const Icon(Icons.medication, color: Color(0xFF2A8DE5)),
            title: Text(item.pillName),
            subtitle: Text(
              [
                '신뢰도 ${(item.confidence * 100).toStringAsFixed(1)}%',
                item.manufacturer,
              ].whereType<String>().join(' | '),
            ),
            trailing: Icon(
              item.itemId == null
                  ? Icons.chevron_right
                  : Icons.add_circle_outline,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildPrescriptionResults() {
    if (_selectedImage == null) {
      return [const Text('처방전이나 약 봉투를 촬영하면 추출 결과가 표시됩니다.')];
    }
    if (_prescriptionItems.isEmpty) {
      return [const Text('추출된 약 정보가 없습니다.')];
    }
    return [
      const Text(
        'OCR 추출 결과',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      ..._prescriptionItems.map(
        (item) => Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.receipt_long,
                    color: Color(0xFF2A8DE5),
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
                    icon: const Icon(Icons.search),
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
                        fillColor: const Color(0xFFF8F9FA),
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
          icon: const Icon(Icons.playlist_add_check),
          label: Text(_isRegistering ? '등록 중...' : '선택한 OCR 결과 등록'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A8DE5),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
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
