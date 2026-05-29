class DemoState {
  static bool enabled = false;
  static bool medicationsRegistered = false;
  static bool analysisCompleted = false;
  static bool scheduleGenerated = false;

  static void reset() {
    medicationsRegistered = false;
    analysisCompleted = false;
    scheduleGenerated = false;
  }

  static void activate() {
    enabled = true;
    reset();
  }
}

class DemoMedication {
  final String name;
  final String ingredient;
  final String manufacturer;
  final String purpose;
  final String instruction;
  final String warning;
  final double confidence;
  final bool supplement;

  const DemoMedication({
    required this.name,
    required this.ingredient,
    required this.manufacturer,
    required this.purpose,
    required this.instruction,
    required this.warning,
    required this.confidence,
    this.supplement = false,
  });
}

const demoDetectedMedications = [
  DemoMedication(
    name: '메트포르민정 500mg',
    ingredient: '메트포르민염산염',
    manufacturer: '대웅제약',
    purpose: '제2형 당뇨병 혈당 조절',
    instruction: '아침 식후 1정 복용',
    warning: '신장 기능 저하 또는 조영제 검사 전후에는 전문가 상담이 필요합니다.',
    confidence: 0.96,
  ),
  DemoMedication(
    name: '암로디핀정 5mg',
    ingredient: '암로디핀베실산염',
    manufacturer: '한국화이자제약',
    purpose: '고혈압 및 협심증 관리',
    instruction: '저녁 식후 1정 복용',
    warning: '어지러움, 부종이 있으면 복용 시간을 조정하거나 전문가와 상담하세요.',
    confidence: 0.91,
  ),
];

const demoBaseSupplements = [
  DemoMedication(
    name: '홍삼 농축액',
    ingredient: '홍삼농축액',
    manufacturer: '정관장',
    purpose: '피로 개선 및 면역 보조',
    instruction: '점심 식후 1포',
    warning: '당뇨약 복용 중에는 혈당 변화를 확인해야 합니다.',
    confidence: 1.0,
    supplement: true,
  ),
];
