import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import '../../services/vision_api.dart';
import '../../theme/app_theme.dart';
import 'scan_mode.dart';
import 'scan_result.dart';

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
  Uint8List? _selectedImageBytes;

  Future<void> _pickImage(
    ImageSource source, {
    bool analyzeAfterPick = false,
  }) async {
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null) {
      return;
    }
    final imageBytes = await image.readAsBytes();

    setState(() {
      _selectedImage = image;
      _selectedImageBytes = imageBytes;
    });

    if (analyzeAfterPick) {
      await _analyzeImage(image, imageBytes);
    }
  }

  Future<void> _analyzeSelectedImage() async {
    final image = _selectedImage;
    final imageBytes = _selectedImageBytes;
    if (image == null || imageBytes == null) {
      await _pickImage(ImageSource.camera, analyzeAfterPick: true);
      return;
    }
    await _analyzeImage(image, imageBytes);
  }

  Future<void> _analyzeImage(XFile image, Uint8List imageBytes) async {
    setState(() => _isLoading = true);
    List<PillIdentifyCandidate> pillCandidates = [];
    List<PrescriptionOcrItem> prescriptionItems = [];
    String? errorMessage;

    try {
      if (_mode == ScanMode.pill) {
        pillCandidates = await _visionApi.identifyPill(image);
      } else {
        prescriptionItems = await _visionApi.scanPrescription(image);
      }
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = '이미지 분석 서버와 연결할 수 없습니다.';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    if (!mounted) {
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanResultScreen(
          mode: _mode,
          imageBytes: imageBytes,
          pillCandidates: pillCandidates,
          prescriptionItems: prescriptionItems,
          errorMessage: errorMessage,
        ),
      ),
    );
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
                            _selectedImage = null;
                            _selectedImageBytes = null;
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
                          : () => _pickImage(ImageSource.gallery),
                    ),
                    GestureDetector(
                      onTap: _isLoading ? null : _analyzeSelectedImage,
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
                          child: _isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
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
                  '사진을 선택한 뒤 촬영 버튼을 눌러 분석해주세요',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Text(
              _selectedImage == null
                  ? (_mode == ScanMode.pill
                        ? '낱알을 촬영하거나 갤러리에서 선택해주세요.'
                        : '처방전이나 약 봉투를 촬영하거나 선택해주세요.')
                  : '선택한 사진을 분석할 준비가 되었습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
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
