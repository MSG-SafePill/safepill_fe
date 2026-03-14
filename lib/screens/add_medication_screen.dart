import 'package:flutter/material.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  // 사용자가 선택하는 데이터를 저장할 변수들
  bool isPrescription = true; // 처방약인지 영양제인지
  Set<String> selectedTimes = {}; // 선택된 복용 시간들 (다중 선택)
  int days = 30; // 처방/구매 일수

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      
      // 상단 뒤로가기 바
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context), // 닫고 돌아가기
        ),
        title: const Text('약품 직접 추가', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),

      // 메인 스크롤 화면
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 약품명 입력 섹션
            _buildSectionTitle('약품명 또는 성분명', isRequired: true),
            TextField(
              decoration: InputDecoration(
                hintText: '예: 타이레놀, 오메가3',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[300]!)),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.info, color: Color(0xFF2A8DE5), size: 14),
                SizedBox(width: 4),
                Text('정확한 상극 분석(DUR)을 위해 제품명을 검색해 주세요.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 30),

            // 2. 분류 섹션 (처방약 vs 영양제)
            _buildSectionTitle('분류'),
            Row(
              children: [
                Expanded(child: _buildToggleButton('처방약 / 일반약', isPrescription, () => setState(() => isPrescription = true))),
                const SizedBox(width: 10),
                Expanded(child: _buildToggleButton('영양제', !isPrescription, () => setState(() => isPrescription = false))),
              ],
            ),
            const SizedBox(height: 30),

            // 3. 복용 시간 섹션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('복용 시간', isRequired: true),
                const Text('다중 선택 가능', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildTimeButton('☀️ 아침 식전'), _buildTimeButton('☀️ 아침 식후'),
                _buildTimeButton('⛅ 점심 식전'), _buildTimeButton('⛅ 점심 식후'),
                _buildTimeButton('🌙 저녁 식전'), _buildTimeButton('🌙 저녁 식후'),
                _buildTimeButton('🛌 취침 전'),
              ].map((widget) => FractionallySizedBox(
                widthFactor: 0.48, // 2열로 예쁘게 배치하기 위해 48%씩 차지
                child: widget,
              )).toList(),
            ),
            const SizedBox(height: 10),
            _buildTimeButton('시간 상관없이 필요 시 복용', isFullWidth: true),
            const SizedBox(height: 30),

            // 4. 처방/구매 일수 조절 섹션
            _buildSectionTitle('처방/구매 일수'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('총 며칠 분량인가요?', style: TextStyle(fontSize: 14)),
                  Row(
                    children: [
                      _buildRoundButton(Icons.remove, () => setState(() => days > 1 ? days-- : null)),
                      SizedBox(width: 40, child: Text('$days', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2A8DE5)))),
                      _buildRoundButton(Icons.add, () => setState(() => days++)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),

      // 5. 하단 고정 저장 버튼
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                // 추가 완료 후 창 닫기
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A8DE5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text('마이약장에 추가하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI 부품(Widget) 함수들 ---

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: RichText(
        text: TextSpan(
          text: title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          children: isRequired ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFF2A8DE5)))] : [],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? const Color(0xFF2A8DE5) : Colors.grey[300]!, width: 1.5),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF2A8DE5) : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildTimeButton(String label, {bool isFullWidth = false}) {
    bool isSelected = selectedTimes.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) selectedTimes.remove(label);
          else selectedTimes.add(label);
        });
      },
      child: Container(
        height: 50,
        width: isFullWidth ? double.infinity : null,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? const Color(0xFF2A8DE5) : Colors.grey[300]!, width: 1.5),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF2A8DE5) : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildRoundButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32, height: 32,
        decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: const Color(0xFF2A8DE5)),
      ),
    );
  }
}