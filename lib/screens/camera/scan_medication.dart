import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
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

  ScanMode _mode = ScanMode.pill;
  bool _isLoading = false;
  XFile? _selectedImage;
  List<PillIdentifyCandidate> _pillCandidates = [];
  List<PrescriptionOcrItem> _prescriptionItems = [];

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
        ).showSnackBar(SnackBar(content: Text('분석 실패: ${e.message}')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지 분석 서버와 연결할 수 없습니다.')));
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
            leading: const Icon(Icons.medication, color: Color(0xFF2A8DE5)),
            title: Text(item.pillName),
            subtitle: Text(
              '신뢰도 ${(item.confidence * 100).toStringAsFixed(1)}%',
            ),
            trailing: const Icon(Icons.chevron_right),
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
          child: ListTile(
            leading: const Icon(Icons.receipt_long, color: Color(0xFF2A8DE5)),
            title: Text(item.medicineName),
            subtitle: Text(
              [
                item.dosage,
                item.frequency,
                item.mealTiming,
                item.days,
              ].whereType<String>().join(' | '),
            ),
          ),
        ),
      ),
    ];
  }
}
