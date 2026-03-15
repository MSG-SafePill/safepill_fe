import 'package:flutter/material.dart';

class HealthInfoScreen extends StatefulWidget {
  const HealthInfoScreen({super.key});

  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen> {
  // 사용자가 선택한 질환들을 담을 리스트
  final List<String> _selectedDiseases = [];
  
  // 추천 질환 목록
  final List<String> _recommendedDiseases = ['고혈압', '당뇨병', '고지혈증', '신장 질환', '간 질환', '심장 질환'];

  // 알레르기 목록 (임시 데이터)
  final List<String> _allergies = ['페니실린', '아스피린'];
  final TextEditingController _allergyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('건강 정보 관리', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 질환 정보 섹션
            _buildTitle('보유 질환', '해당하는 질환을 선택해주세요.'),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _recommendedDiseases.map((disease) {
                final isSelected = _selectedDiseases.contains(disease);
                return FilterChip(
                  label: Text(disease),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDiseases.add(disease);
                      } else {
                        _selectedDiseases.remove(disease);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF2A8DE5).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF2A8DE5),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF2A8DE5) : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? const Color(0xFF2A8DE5) : Colors.transparent),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 40),

            // 2. 알레르기 섹션
            _buildTitle('알레르기 정보', '복용 시 부작용이 있는 성분을 입력하세요.'),
            const SizedBox(height: 15),
            
            // 알레르기 입력창
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _allergyController,
                    decoration: InputDecoration(
                      hintText: '예: 아스피린, 항생제 등',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_allergyController.text.isNotEmpty) {
                      setState(() {
                        _allergies.add(_allergyController.text);
                        _allergyController.clear();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A8DE5),
                    minimumSize: const Size(60, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // 추가된 알레르기 리스트 (칩 형태)
            Wrap(
              spacing: 8,
              children: _allergies.map((allergy) {
                return Chip(
                  label: Text(allergy),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _allergies.remove(allergy);
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 60),

            // 3. 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 서버 저장 로직
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A8DE5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('건강 정보 저장하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}