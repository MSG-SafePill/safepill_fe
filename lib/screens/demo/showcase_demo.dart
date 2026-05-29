import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../demo/demo_state.dart';

enum DemoScanMode { prescription, pill }

class ShowcaseDemoScreen extends StatefulWidget {
  const ShowcaseDemoScreen({super.key});

  @override
  State<ShowcaseDemoScreen> createState() => _ShowcaseDemoScreenState();
}

class DemoModeSelector extends StatelessWidget {
  final DemoScanMode selected;
  final ValueChanged<DemoScanMode>? onChanged;

  const DemoModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF2)),
      ),
      child: Row(
        children: [
          _DemoModeOption(
            label: '처방전 OCR',
            icon: Icons.receipt_long,
            selected: selected == DemoScanMode.prescription,
            onTap: onChanged == null
                ? null
                : () => onChanged!(DemoScanMode.prescription),
          ),
          _DemoModeOption(
            label: '낱알 식별',
            icon: Icons.center_focus_strong,
            selected: selected == DemoScanMode.pill,
            onTap: onChanged == null
                ? null
                : () => onChanged!(DemoScanMode.pill),
          ),
        ],
      ),
    );
  }
}

class _DemoModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _DemoModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1D6FEA) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : const Color(0xFF65758A),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF65758A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShowcaseDemoScreenState extends State<ShowcaseDemoScreen> {
  int _index = 0;

  void _moveTo(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DemoHomePage(onScan: () => _moveTo(1)),
      DemoCameraPage(onComplete: () => _moveTo(2)),
      DemoCabinetPage(onAnalyze: () => _moveTo(3)),
      DemoAnalysisPage(onSchedule: () => setState(() {})),
      const DemoPillBotPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _moveTo,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1D6FEA),
        unselectedItemColor: const Color(0xFF9AA8B8),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: '촬영'),
          BottomNavigationBarItem(icon: Icon(Icons.medication), label: '약장'),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: '분석'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: '필봇'),
        ],
      ),
    );
  }
}

class DemoHomePage extends StatelessWidget {
  final VoidCallback onScan;

  const DemoHomePage({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return DemoPageShell(
      title: '김민준님, 오늘의 복약 상태',
      subtitle: '당뇨 · 고혈압 · 페니실린 알레르기',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          const DemoInfoBanner(
            icon: Icons.verified_user,
            title: 'SafePill Demo Mode',
            body: '카메라 촬영부터 약품 식별, 상극 분석, 스케줄, PillBot 상담까지 안정적으로 시연합니다.',
          ),
          const SizedBox(height: 16),
          DemoPrimaryButton(
            icon: Icons.camera_alt,
            label: '약 사진 촬영하기',
            onPressed: onScan,
          ),
          const SizedBox(height: 22),
          const DemoSectionTitle('현재 등록된 건강 정보'),
          const DemoProfileCard(),
          const SizedBox(height: 22),
          const DemoSectionTitle('오늘의 복약 스케줄'),
          const DemoScheduleCard(
            time: '12:30',
            title: '홍삼 농축액',
            subtitle: '점심 식후 1포 · 혈당 변화 관찰',
            badge: '등록됨',
          ),
          const DemoScheduleCard(
            time: '촬영 후',
            title: '처방약 자동 등록 대기',
            subtitle: '카메라로 약을 찍으면 복용 시간이 자동 배치됩니다.',
            badge: 'AI 분석',
          ),
        ],
      ),
    );
  }
}

class DemoCameraPage extends StatefulWidget {
  final VoidCallback onComplete;

  const DemoCameraPage({super.key, required this.onComplete});

  @override
  State<DemoCameraPage> createState() => _DemoCameraPageState();
}

class _DemoCameraPageState extends State<DemoCameraPage> {
  bool _loading = false;
  int _step = 0;
  DemoScanMode _mode = DemoScanMode.prescription;
  Timer? _timer;

  static const _prescriptionSteps = [
    '처방전 이미지를 전처리하고 있습니다',
    'OCR로 약품명과 복용 정보를 추출하고 있습니다',
    '불필요한 병원명과 금액 텍스트를 제거하고 있습니다',
    '백엔드 약품 DB와 성분 정보를 매칭하고 있습니다',
  ];

  static const _pillSteps = [
    'YOLOv8로 낱알 영역을 탐지하고 있습니다',
    '색상, 모양, 각인 후보를 추출하고 있습니다',
    '낱알식별 DB와 itemSeq를 매칭하고 있습니다',
    '성분과 주의사항을 불러오고 있습니다',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<String> get _steps =>
      _mode == DemoScanMode.prescription ? _prescriptionSteps : _pillSteps;

  Future<void> _pick(ImageSource source) async {
    try {
      await ImagePicker().pickImage(source: source, imageQuality: 75);
    } catch (_) {
      // 웹/데스크톱 권한 문제 시에도 발표 흐름은 계속 진행합니다.
    }
    if (!mounted) return;
    setState(() {
      _loading = true;
      _step = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (!mounted) return;
      if (_step >= _steps.length - 1) {
        timer.cancel();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DemoIdentifyResultPage(
              mode: _mode,
              onRegister: () {
                DemoState.medicationsRegistered = true;
                widget.onComplete();
                Navigator.pop(context);
              },
            ),
          ),
        );
        setState(() => _loading = false);
        return;
      }
      setState(() => _step += 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoPageShell(
      title: '이미지 기반 약 등록',
      subtitle: '처방전 OCR과 낱알 식별 중 하나를 선택합니다',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DemoModeSelector(
              selected: _mode,
              onChanged: _loading
                  ? null
                  : (mode) {
                      setState(() => _mode = mode);
                    },
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F3FF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD3E7FF)),
                ),
                child: _loading
                    ? DemoLoadingPanel(step: _steps[_step], stepIndex: _step)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _mode == DemoScanMode.prescription
                                ? Icons.receipt_long
                                : Icons.medication,
                            size: 72,
                            color: const Color(0xFF1D6FEA),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _mode == DemoScanMode.prescription
                                ? '처방전 또는 약봉투 이미지를 업로드하세요'
                                : '낱알을 화면 중앙에 맞춰 촬영하세요',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF23364A),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _mode == DemoScanMode.prescription
                                ? 'OCR 후보를 사용자가 확인한 뒤 약장에 등록합니다.'
                                : 'YOLOv8 탐지 결과를 약품 DB와 매칭합니다.',
                            style: const TextStyle(color: Color(0xFF6B7C8F)),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: DemoSecondaryButton(
                    icon: Icons.photo_library,
                    label: '앨범 선택',
                    onPressed: _loading
                        ? null
                        : () => _pick(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DemoPrimaryButton(
                    icon: Icons.camera_alt,
                    label: _loading ? '분석 중' : '촬영하기',
                    onPressed: _loading
                        ? null
                        : () => _pick(ImageSource.camera),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DemoIdentifyResultPage extends StatelessWidget {
  final DemoScanMode mode;
  final VoidCallback onRegister;

  const DemoIdentifyResultPage({
    super.key,
    required this.mode,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final isPrescription = mode == DemoScanMode.prescription;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(isPrescription ? '처방전 OCR 결과' : '낱알 식별 결과'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF23364A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DemoInfoBanner(
            icon: isPrescription
                ? Icons.document_scanner
                : Icons.center_focus_strong,
            title: isPrescription ? 'OCR 후보 2건을 추출했습니다' : '낱알 후보 2건을 식별했습니다',
            body: isPrescription
                ? '처방전 이미지에서 약품명과 복용 정보를 추출하고 medicine_master와 매칭했습니다.'
                : 'YOLOv8이 낱알 영역을 탐지하고 itemSeq 기준으로 백엔드 약품 DB와 매칭했습니다.',
          ),
          const SizedBox(height: 16),
          if (isPrescription) const DemoOcrTraceCard(),
          if (!isPrescription) const DemoPillTraceCard(),
          const SizedBox(height: 6),
          ...demoDetectedMedications.map(
            (medication) => DemoMedicationResultCard(
              medication,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DemoMedicationDetailPage(
                      medication: medication,
                      source: isPrescription ? '처방전 OCR' : 'YOLOv8 낱알 식별',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          DemoPrimaryButton(
            icon: Icons.add_circle,
            label: '선택한 약 등록하기',
            onPressed: onRegister,
          ),
        ],
      ),
    );
  }
}

class DemoMedicationDetailPage extends StatelessWidget {
  final DemoMedication medication;
  final String source;

  const DemoMedicationDetailPage({
    super.key,
    required this.medication,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('약 상세 정보'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF23364A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DemoInfoBanner(
            icon: Icons.verified,
            title: medication.name,
            body: '$source 결과를 백엔드 DB와 매칭해 성분, 효능, 복용법, 주의사항을 표시합니다.',
          ),
          const SizedBox(height: 16),
          DemoCard(
            child: Column(
              children: [
                DemoKeyValue(label: '약품명', value: medication.name),
                DemoKeyValue(label: '제조사', value: medication.manufacturer),
                DemoKeyValue(label: '성분', value: medication.ingredient),
                DemoKeyValue(label: '효능', value: medication.purpose),
                DemoKeyValue(label: '복용법', value: medication.instruction),
                DemoKeyValue(
                  label: '신뢰도',
                  value: '${(medication.confidence * 100).round()}%',
                ),
              ],
            ),
          ),
          DemoInteractionCard(
            severity: '주의사항',
            color: const Color(0xFFE8A13F),
            title: '복용 전 확인',
            body: medication.warning,
            icon: Icons.info,
          ),
        ],
      ),
    );
  }
}

class DemoCabinetPage extends StatelessWidget {
  final VoidCallback onAnalyze;

  const DemoCabinetPage({super.key, required this.onAnalyze});

  @override
  Widget build(BuildContext context) {
    final items = [
      ...demoBaseSupplements,
      if (DemoState.medicationsRegistered) ...demoDetectedMedications,
    ];
    return DemoPageShell(
      title: '마이약장',
      subtitle: DemoState.medicationsRegistered
          ? '촬영한 처방약이 등록되었습니다'
          : '현재 등록된 약과 영양제',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          if (!DemoState.medicationsRegistered)
            const DemoInfoBanner(
              icon: Icons.info,
              title: '처방약 등록 전',
              body: '촬영 탭에서 약 사진을 찍으면 메트포르민과 암로디핀이 자동 등록됩니다.',
            ),
          if (!DemoState.medicationsRegistered) const SizedBox(height: 16),
          ...items.map(DemoCabinetCard.new),
          const SizedBox(height: 18),
          DemoPrimaryButton(
            icon: Icons.health_and_safety,
            label: '상호작용 분석하기',
            onPressed: DemoState.medicationsRegistered
                ? () {
                    DemoState.analysisCompleted = true;
                    onAnalyze();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class DemoAnalysisPage extends StatelessWidget {
  final VoidCallback onSchedule;

  const DemoAnalysisPage({super.key, required this.onSchedule});

  @override
  Widget build(BuildContext context) {
    return DemoPageShell(
      title: '맞춤형 상극 분석',
      subtitle: '기저질환 · 등록약 · 영양제를 함께 확인했습니다',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          const DemoRiskSummaryCard(),
          const SizedBox(height: 16),
          const DemoInteractionCard(
            severity: '주의 필요',
            color: Color(0xFFE85D3F),
            title: '메트포르민 + 홍삼 농축액',
            body:
                '홍삼은 혈당에 영향을 줄 수 있어 당뇨약 복용자에게 저혈당 위험 확인이 필요합니다. 같은 시간 복용을 피하도록 스케줄을 분리합니다.',
            icon: Icons.warning_amber,
          ),
          const DemoInteractionCard(
            severity: '복용 주의',
            color: Color(0xFFE8A13F),
            title: '암로디핀 + 자몽 섭취',
            body: '일부 혈압약은 자몽과 함께 섭취할 때 혈중 농도 변화가 생길 수 있어 식이 안내가 필요합니다.',
            icon: Icons.restaurant,
          ),
          const DemoInteractionCard(
            severity: '확인됨',
            color: Color(0xFF2CA66F),
            title: '메트포르민 + 암로디핀',
            body: '현재 등록된 정보 기준으로 직접적인 병용금기 조합은 확인되지 않았습니다.',
            icon: Icons.check_circle,
          ),
          const SizedBox(height: 14),
          DemoPrimaryButton(
            icon: Icons.schedule,
            label: '안전 복약 스케줄 생성',
            onPressed: () {
              DemoState.scheduleGenerated = true;
              onSchedule();
            },
          ),
          const SizedBox(height: 16),
          if (DemoState.scheduleGenerated) const DemoGeneratedSchedule(),
        ],
      ),
    );
  }
}

class DemoPillBotPage extends StatefulWidget {
  const DemoPillBotPage({super.key});

  @override
  State<DemoPillBotPage> createState() => _DemoPillBotPageState();
}

class _DemoPillBotPageState extends State<DemoPillBotPage> {
  final List<_DemoMessage> _messages = [
    const _DemoMessage(
      text: '김민준님, 등록된 기저질환과 복용 약을 기준으로 상담할 준비가 되었습니다.',
      user: false,
    ),
  ];

  void _ask(String question, String answer) {
    setState(() {
      _messages.add(_DemoMessage(text: question, user: true));
      _messages.add(_DemoMessage(text: answer, user: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoPageShell(
      title: 'PillBot 맞춤 상담',
      subtitle: '등록된 약장과 분석 결과를 알고 답변합니다',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final message in _messages)
                  _DemoChatBubble(message: message),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            color: Colors.white,
            child: Column(
              children: [
                DemoQuestionButton(
                  text: '홍삼이랑 당뇨약 같이 먹어도 돼?',
                  onTap: () => _ask(
                    '홍삼이랑 당뇨약 같이 먹어도 돼?',
                    '메트포르민을 복용 중이고 기저질환이 당뇨로 등록되어 있어 홍삼과 같은 시간 복용은 피하는 것이 좋습니다. 오늘 스케줄은 메트포르민 08:00, 홍삼 12:30으로 분리했습니다.',
                  ),
                ),
                DemoQuestionButton(
                  text: '오늘 약은 언제 먹으면 돼?',
                  onTap: () => _ask(
                    '오늘 약은 언제 먹으면 돼?',
                    '오늘은 08:00 메트포르민, 12:30 홍삼 농축액, 20:00 암로디핀 순서로 복용하세요. 혈당 저하 증상이 있으면 홍삼 복용을 중단하고 전문가와 상담하세요.',
                  ),
                ),
                DemoQuestionButton(
                  text: '암로디핀 먹을 때 조심할 음식은?',
                  onTap: () => _ask(
                    '암로디핀 먹을 때 조심할 음식은?',
                    '자몽은 일부 혈압약의 혈중 농도에 영향을 줄 수 있어 주의가 필요합니다. 복용 중 어지러움이나 부종이 있으면 의료진에게 알려주세요.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DemoPageShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const DemoPageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 58, 20, 26),
          decoration: const BoxDecoration(
            color: Color(0xFF1D6FEA),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: '데모 종료',
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'DEMO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class DemoLoadingPanel extends StatelessWidget {
  final String step;
  final int stepIndex;

  const DemoLoadingPanel({
    super.key,
    required this.step,
    required this.stepIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 54,
            height: 54,
            child: CircularProgressIndicator(strokeWidth: 5),
          ),
          const SizedBox(height: 28),
          Text(
            step,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF23364A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: (stepIndex + 1) / 4,
            borderRadius: BorderRadius.circular(999),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}

class DemoMedicationResultCard extends StatelessWidget {
  final DemoMedication medication;
  final VoidCallback? onTap;

  const DemoMedicationResultCard(this.medication, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: DemoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFEAF3FF),
                  child: Icon(Icons.medication, color: Color(0xFF1D6FEA)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    medication.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${(medication.confidence * 100).round()}%',
                  style: const TextStyle(
                    color: Color(0xFF1D6FEA),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DemoKeyValue(label: '성분', value: medication.ingredient),
            DemoKeyValue(label: '제조사', value: medication.manufacturer),
            DemoKeyValue(label: '효능', value: medication.purpose),
            DemoKeyValue(label: '복용법', value: medication.instruction),
            const SizedBox(height: 8),
            Text(
              medication.warning,
              style: const TextStyle(color: Color(0xFFE85D3F), height: 1.35),
            ),
            const SizedBox(height: 8),
            const Text(
              '카드를 눌러 상세 정보 보기',
              style: TextStyle(
                color: Color(0xFF1D6FEA),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DemoOcrTraceCard extends StatelessWidget {
  const DemoOcrTraceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OCR 추출 로그',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          DemoKeyValue(label: '원문 후보', value: '메트포르민정 500mg / 암로디핀정 5mg'),
          DemoKeyValue(label: '노이즈 제거', value: '병원명, 금액, 전화번호, 안내 문구 제외'),
          DemoKeyValue(
            label: 'DB 매칭',
            value: 'medicine_master + ingredient_master',
          ),
        ],
      ),
    );
  }
}

class DemoPillTraceCard extends StatelessWidget {
  const DemoPillTraceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOLOv8 식별 로그',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          DemoKeyValue(label: '탐지 객체', value: '2개 낱알 bounding box'),
          DemoKeyValue(label: '예측 클래스', value: 'metformin_500, amlodipine_5'),
          DemoKeyValue(label: '후처리', value: 'itemSeq 기준 약품 DB 매칭'),
        ],
      ),
    );
  }
}

class DemoCabinetCard extends StatelessWidget {
  final DemoMedication medication;

  const DemoCabinetCard(this.medication, {super.key});

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: medication.supplement
                ? const Color(0xFFEAF8EE)
                : const Color(0xFFEAF3FF),
            child: Icon(
              medication.supplement ? Icons.eco : Icons.medication,
              color: medication.supplement
                  ? const Color(0xFF2CA66F)
                  : const Color(0xFF1D6FEA),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${medication.ingredient} · ${medication.instruction}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF65758A),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DemoRiskSummaryCard extends StatelessWidget {
  const DemoRiskSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD3C7)),
      ),
      child: const Row(
        children: [
          Icon(Icons.report, color: Color(0xFFE85D3F), size: 34),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '주의 필요 2건 확인',
                  style: TextStyle(
                    color: Color(0xFFE85D3F),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '당뇨와 고혈압 프로필을 기준으로 복용 시간을 조정합니다.',
                  style: TextStyle(color: Color(0xFF784438), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DemoInteractionCard extends StatelessWidget {
  final String severity;
  final Color color;
  final String title;
  final String body;
  final IconData icon;

  const DemoInteractionCard({
    super.key,
    required this.severity,
    required this.color,
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      borderColor: color.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                severity,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(height: 1.4, color: Color(0xFF526173)),
          ),
        ],
      ),
    );
  }
}

class DemoGeneratedSchedule extends StatelessWidget {
  const DemoGeneratedSchedule({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DemoSectionTitle('자동 생성 스케줄'),
        DemoScheduleCard(
          time: '08:00',
          title: '메트포르민정 500mg',
          subtitle: '아침 식후 · 혈당 관리',
          badge: '당뇨',
        ),
        DemoScheduleCard(
          time: '12:30',
          title: '홍삼 농축액',
          subtitle: '메트포르민과 4시간 이상 분리',
          badge: '분리',
        ),
        DemoScheduleCard(
          time: '20:00',
          title: '암로디핀정 5mg',
          subtitle: '저녁 식후 · 어지러움 주의',
          badge: '혈압',
        ),
      ],
    );
  }
}

class DemoProfileCard extends StatelessWidget {
  const DemoProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoCard(
      child: Column(
        children: [
          DemoKeyValue(label: '기저질환', value: '당뇨, 고혈압'),
          DemoKeyValue(label: '알레르기', value: '페니실린'),
          DemoKeyValue(label: '등록 영양제', value: '홍삼 농축액'),
        ],
      ),
    );
  }
}

class DemoScheduleCard extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final String badge;

  const DemoScheduleCard({
    super.key,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Text(
              time,
              style: const TextStyle(
                color: Color(0xFF1D6FEA),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF65758A)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Color(0xFF1D6FEA),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DemoCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const DemoCard({super.key, required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? const Color(0xFFE3EAF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DemoInfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const DemoInfoBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD3E7FF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1D6FEA), size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF23364A),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF526173),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DemoPrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const DemoPrimaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF073D9A),
          disabledBackgroundColor: const Color(0xFFB8C6D9),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class DemoSecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const DemoSecondaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1D6FEA),
          side: const BorderSide(color: Color(0xFFD3E7FF), width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

class DemoSectionTitle extends StatelessWidget {
  final String text;

  const DemoSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF23364A),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class DemoKeyValue extends StatelessWidget {
  final String label;
  final String value;

  const DemoKeyValue({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8390A2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF23364A), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class DemoQuestionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const DemoQuestionButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: const Color(0xFF1D6FEA),
          side: const BorderSide(color: Color(0xFFD3E7FF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}

class _DemoChatBubble extends StatelessWidget {
  final _DemoMessage message;

  const _DemoChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: message.user ? const Color(0xFF1D6FEA) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.user ? 18 : 4),
            bottomRight: Radius.circular(message.user ? 4 : 18),
          ),
          border: message.user
              ? null
              : Border.all(color: const Color(0xFFE3EAF2)),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.user ? Colors.white : const Color(0xFF23364A),
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _DemoMessage {
  final String text;
  final bool user;

  const _DemoMessage({required this.text, required this.user});
}
