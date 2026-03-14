import 'package:flutter/material.dart';
import 'my_medication_screen.dart'; // 방금 만든 마이약장 화면

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 현재 선택된 탭 번호를 기억하는 변수 (0: 홈, 1: 마이약장 ...)
  int _currentIndex = 0;

  // 알맹이 화면들 리스트
  final List<Widget> _pages = [
    const HomeContent(),        // 0번: 홈 화면 내용
    const MyMedicationScreen(), // 1번: 마이약장 화면 내용
    const Center(child: Text('카메라 화면')), // 2번 (가운데 버튼용, 실제론 모달 띄울 예정)
    const Center(child: Text('AI 상담 준비중')), // 3번
    const Center(child: Text('내정보 준비중')),  // 4번
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      
      // 알맹이 화면 (현재 선택된 탭 번호에 따라 화면이 샥샥 바뀜!)
      body: _pages[_currentIndex],

      // 가운데 카메라 버튼 (항상 떠있음)
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 30),
        child: Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: const Color(0xFF4285F4).withOpacity(0.3), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFF4285F4),
              elevation: 0,
              shape: const CircleBorder(),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 하단 네비게이션 바
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home, '홈', 0),
            _buildBottomNavItem(Icons.medication, '마이약장', 1),
            const SizedBox(width: 40), // 가운데 카메라 공간
            _buildBottomNavItem(Icons.smart_toy, 'AI 상담', 3),
            _buildBottomNavItem(Icons.person, '내정보', 4),
          ],
        ),
      ),
    );
  }

  // 하단 탭 아이콘 부품
  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    // 현재 선택된 인덱스와 이 버튼의 인덱스가 같으면 활성화(파란색)!
    bool isActive = _currentIndex == index; 

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index; // 탭을 누르면 알맹이 화면 번호를 바꿈!
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? const Color(0xFF2A8DE5) : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? const Color(0xFF2A8DE5) : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ==== [홈 화면의 알맹이 내용 (원래 있던 코드)] ====
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 70, left: 20, right: 20, bottom: 30),
          decoration: const BoxDecoration(
            color: Color(0xFF2A8DE5),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('안녕하세요, 홍길동님!', style: TextStyle(color: Colors.white, fontSize: 16)),
              SizedBox(height: 10),
              Text('오늘은 3알의 약을\n더 드셔야 해요.', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text('오늘의 복약 스케줄', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            children: [
              _buildSimplePillCard('08:30', '아세트아미노펜 500mg', '식후 30분 | 1정', true, false),
              _buildSimplePillCard('13:00', '종합 비타민', '식사 중 | 2정', false, true),
              _buildSimplePillCard('22:00', '오메가3', '취침 전 | 1정', false, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimplePillCard(String time, String name, String desc, bool isTaken, bool isMissed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: isMissed ? const Border(left: BorderSide(color: Color(0xFFE53935), width: 5)) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Text(time, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isMissed ? const Color(0xFFE53935) : const Color(0xFF2A8DE5))),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: Icon(isTaken ? Icons.check_circle : Icons.circle_outlined, color: isTaken ? const Color(0xFF4CAF50) : Colors.grey[300], size: 32),
      ),
    );
  }
}