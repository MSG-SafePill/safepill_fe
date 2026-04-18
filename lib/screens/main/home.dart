import 'package:flutter/material.dart';
import '../medication/my_medication.dart';
import '../profile/profile.dart';
import '../chat/ai_chat.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // [상태 변수] 현재 선택된 탭 인덱스
  int _currentIndex = 0;

  // [화면 목록]
  final List<Widget> _pages = [
    const HomeContent(),        // 0: 홈 (👇 아래에서 새롭게 디자인된 본문)
    const MyMedicationScreen(), // 1: 마이약장
    const Center(child: Text('카메라 화면')), // 2: 카메라
    const AiChatScreen(),       // 3: AI 상담
    const ProfileScreen(),      // 4: 내정보
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      
      // [메인 화면]
      body: _pages[_currentIndex],

      // [중앙 FAB] 카메라 버튼 (기존 유지)
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
                color: const Color(0xFF2A8DE5).withOpacity(0.3), 
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
                // TODO: 카메라 추가 화면으로 이동
              },
              backgroundColor: const Color(0xFF2A8DE5), // 기존 테마 컬러 유지
              elevation: 0,
              shape: const CircleBorder(),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // [하단 네비게이션 바] (기존 유지)
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home, '홈', 0),
            _buildBottomNavItem(Icons.medication, '마이약장', 1),
            const SizedBox(width: 40), 
            _buildBottomNavItem(Icons.smart_toy, 'AI 상담', 3),
            _buildBottomNavItem(Icons.person, '내정보', 4),
          ],
        ),
      ),
    );
  }

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
// [0번 탭: 새롭게 디자인된 홈 화면 본문]
// ==========================================
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 상단 사용자 인사말 헤더 (디자인 변경!)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 70, left: 24, right: 24, bottom: 40),
          decoration: const BoxDecoration(
            color: Color(0xFF2A8DE5),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('안녕하세요, 홍길동님!', style: TextStyle(fontSize: 16, color: Colors.white70)),
              SizedBox(height: 8),
              Text(
                '오늘의 안전 복약 스케줄이\n생성되었습니다.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
              ),
            ],
          ),
        ),
        
        // 2. 새로운 약품 리스트 영역
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: const [
              Text('오늘의 복약 스케줄', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              SizedBox(height: 16),

              // 💡 새로운 약품 데이터 적용!
              HomeMedicationCard(time: '08:30', name: '메트포르민 500mg', detail: '식후 30분 | 1정 (당뇨약)', isInitiallyTaken: true),
              SizedBox(height: 12),
              HomeMedicationCard(time: '08:30', name: '암로디핀 5mg', detail: '식후 30분 | 1정 (혈압약)', isInitiallyTaken: true),
              SizedBox(height: 12),
              HomeMedicationCard(time: '13:00', name: '루테인 지아잔틴', detail: '식사 중 | 1캡슐 (눈 영양제)'),
              SizedBox(height: 12),
              
              // 🚀 홍삼 진액에만 AI 분석 버튼 활성화!
              HomeMedicationCard(time: '18:00', name: '홍삼 진액', detail: '식전 | 1포 (면역 영양제)', showAiButton: true),
              SizedBox(height: 80), // 하단 여백
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// [개별 약품 카드 (체크박스를 위해 StatefulWidget으로 변경!)]
// ==========================================
class HomeMedicationCard extends StatefulWidget {
  final String time;
  final String name;
  final String detail;
  final bool showAiButton;
  final bool isInitiallyTaken;

  const HomeMedicationCard({
    super.key,
    required this.time,
    required this.name,
    required this.detail,
    this.showAiButton = false,
    this.isInitiallyTaken = false,
  });

  @override
  State<HomeMedicationCard> createState() => _HomeMedicationCardState();
}

class _HomeMedicationCardState extends State<HomeMedicationCard> {
  late bool isTaken;

  @override
  void initState() {
    super.initState();
    isTaken = widget.isInitiallyTaken;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(widget.time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2A8DE5))),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                const SizedBox(height: 4),
                Text(widget.detail, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                
                // 💡 AI 버튼이 true일 때만 보여주기
                if (widget.showAiButton) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showAiDialog(context), // 팝업 띄우기!
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF5FB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD6EAF8)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('💡 ', style: TextStyle(fontSize: 12)),
                          Text('AI 재배치 이유 보기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2A8DE5))),
                        ],
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
          
          // 체크박스 동작 부분
          GestureDetector(
            onTap: () {
              setState(() {
                isTaken = !isTaken; // 클릭할 때마다 상태 토글
              });
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTaken ? const Color(0xFF2ECC71) : Colors.transparent,
                border: Border.all(color: isTaken ? const Color(0xFF2ECC71) : Colors.grey.shade300, width: 2),
              ),
              child: isTaken ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
            ),
          ),
        ],
      ),
    );
  }

  // --- 중앙 팝업 (Dialog) 띄우는 함수 ---
  void _showAiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🤖', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text('AI 상호작용 분석 리포트', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '홍길동님의 기저질환(당뇨)과 등록된 약물 간의 상호작용 분석 결과입니다.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D), height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDEDEC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFADBD8)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⚠️ 위험도 높음 (저혈당 쇼크)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE74C3C))),
                      SizedBox(height: 8),
                      Text('홍삼이 인슐린 분비를 촉진하여 메트포르민과 병용 시 심각한 저혈당 위험이 발생할 수 있습니다.', style: TextStyle(fontSize: 13, color: Color(0xFFC0392B), height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAFAF1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD5F5E3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✅ 스케줄 안전 재배치 완료', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF27AE60))),
                      SizedBox(height: 8),
                      Text('안전한 체내 흡수를 위해 두 약물의 복용 시간을 최소 4시간 이상 분리하여 스케줄을 재배치했습니다.', style: TextStyle(fontSize: 13, color: Color(0xFF1E8449), height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A8DE5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}