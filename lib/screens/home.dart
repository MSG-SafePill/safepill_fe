import 'package:flutter/material.dart';
import 'my_medication.dart';
import 'profile.dart';
import 'ai_chat.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // [상태 변수] 현재 선택된 탭 인덱스
  int _currentIndex = 0;

  // [화면 목록] 탭 번호에 매칭되는 위젯 리스트
  final List<Widget> _pages = [
    const HomeContent(),        // 0: 홈
    const MyMedicationScreen(), // 1: 마이약장
    const Center(child: Text('카메라 화면')), // 2: 카메라
    const AiChatScreen(),       // 3: AI 상담
    const ProfileScreen(),      // 4: 내정보 (여기가 싹 바뀌었습니다!)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      
      // [메인 화면] 현재 탭에 맞는 화면 출력
      body: _pages[_currentIndex],

      // [중앙 FAB] 카메라 버튼
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 30),
        child: Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4285F4).withOpacity(0.3), 
                blurRadius: 15, 
                spreadRadius: 2, 
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: FloatingActionButton(
              onPressed: () {
                // TODO: 카메라 모달 또는 화면 전환 로직
              },
              backgroundColor: const Color(0xFF4285F4),
              elevation: 0,
              shape: const CircleBorder(),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // [하단 네비게이션 바]
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home, '홈', 0),
            _buildBottomNavItem(Icons.medication, '마이약장', 1),
            const SizedBox(width: 40), // 중앙 카메라 버튼용 여백
            _buildBottomNavItem(Icons.smart_toy, 'AI 상담', 3),
            _buildBottomNavItem(Icons.person, '내정보', 4),
          ],
        ),
      ),
    );
  }

  // --- [UI 컴포넌트: 하단 네비게이션 아이템] ---
  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    bool isActive = _currentIndex == index; 

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
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

// ==========================================
// [0번 탭: 홈 화면 본문]
// ==========================================
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 상단 사용자 인사말 헤더
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
        
        // 2. 복약 스케줄 타이틀
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text('오늘의 복약 스케줄', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 15),
        
        // 3. 복약 스케줄 리스트
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

  // --- [UI 컴포넌트: 메인 홈 복약 카드] ---
  Widget _buildSimplePillCard(String time, String name, String desc, bool isTaken, bool isMissed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
        // 누락된 약일 경우 좌측 적색 테두리 표시
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