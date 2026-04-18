import 'package:flutter/material.dart';
import 'add_medication.dart';

class MyMedicationScreen extends StatelessWidget {
  const MyMedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // [탭 제어기: 전체, 처방약, 영양제 3개 탭 구성]
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // 본문 배경색 (연한 회색)
        
        // [상단 앱바 및 탭 메뉴] - 이미지 7 디자인 적용
        appBar: AppBar(
          backgroundColor: Colors.white, // 앱바 배경색 (흰색)
          elevation: 1, // 이미지 7처럼 약간의 그림자 추가
          
          automaticallyImplyLeading: false, // 👈 ✨ [핵심 수정] 뒤로가기 버튼을 강제로 제거합니다.

          title: const Text(
            '마이약장',
            style: TextStyle(
              color: Colors.black, // 타이틀 색상 (검정)
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          
          // 이미지 7처럼 하단 탭과 여백을 주고 싶다면, 여기에 padding을 주는 것보다
          // AppBar.bottom 보다는 body의 Column 상단에 배치하는 게 낫습니다.
          // 일단은 AppBar.bottom으로 구현하고, 여백을 조절하겠습니다.
          bottom: const TabBar(
            labelColor: Color(0xFF2A8DE5), // 선택된 탭 컬러
            unselectedLabelColor: Colors.grey, // 선택 안 된 탭 컬러
            indicatorColor: Color(0xFF2A8DE5), // 밑줄 컬러
            indicatorWeight: 3,
            labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            tabs: [
              Tab(text: '전체'),
              Tab(text: '처방약'),
              Tab(text: '영양제'),
            ],
          ),
        ),

        // [메인 본문 영역]
        body: Column(
          children: [
            // 이미지 7의 탭바 아래 하얀 여백 디테일을 살리기 위해 Container 추가
            Container(height: 10, color: Colors.white),

            // 1. 상단 검색창 (이미지 7 스타일)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '약품명 또는 성분명 검색',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // 2. 탭별 약품 리스트 화면 전환 영역
            Expanded(
              child: TabBarView(
                children: [
                  // [전체] 탭 리스트
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: const [
                      PillCard(icon: '💊', name: '메트포르민 500mg', days: '30일분', instruction: '아침 식후 1정', isWarning: false),
                      PillCard(icon: '💊', name: '암로디핀 5mg', days: '30일분', instruction: '아침 식후 1정', isWarning: false),
                      PillCard(icon: '👁️', name: '루테인 지아잔틴', days: '60일분', instruction: '점심 식사 중 1캡슐', isWarning: false),
                      PillCard(icon: '🌿', name: '홍삼 진액', days: '2일분', instruction: '저녁 식전 1포 (시간엄수)', isWarning: true),
                    ],
                  ),
                  // [처방약] 탭 리스트
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: const [
                      PillCard(icon: '💊', name: '메트포르민 500mg', days: '30일분', instruction: '아침 식후 1정', isWarning: false),
                      PillCard(icon: '💊', name: '암로디핀 5mg', days: '30일분', instruction: '아침 식후 1정', isWarning: false),
                    ],
                  ),
                  // [영양제] 탭 리스트
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: const [
                      PillCard(icon: '👁️', name: '루테인 지아잔틴', days: '60일분', instruction: '점심 식사 중 1캡슐', isWarning: false),
                      PillCard(icon: '🌿', name: '홍삼 진액', days: '2일분', instruction: '저녁 식전 1포 (시간엄수)', isWarning: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // [우측 하단 약 추가 플로팅 버튼] 유지
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
            );
          },
          backgroundColor: const Color(0xFF2A8DE5),
          shape: const CircleBorder(),
          elevation: 4, 
          child: const Icon(Icons.add, color: Colors.white, size: 35), 
        ),
      ),
    );
  }
}

// --- [개별 약품 카드 UI 컴포넌트] ---
class PillCard extends StatefulWidget {
  final String icon;
  final String name;
  final String days;
  final String instruction;
  final bool isWarning; // 소진 임박 등 경고 상태 체크

  const PillCard({super.key, required this.icon, required this.name, required this.days, required this.instruction, this.isWarning = false});

  @override
  State<PillCard> createState() => _PillCardState();
}

class _PillCardState extends State<PillCard> {
  // [상태 변수] 삭제 메뉴 활성화 여부
  bool _showDeleteMenu = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // 경고 상태일 경우 좌측 빨간색 테두리 적용
        border: widget.isWarning ? const Border(left: BorderSide(color: Color(0xFFFF5252), width: 5)) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // 1. 기본 약품 정보 표시 영역
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFF8E1),
              child: Text(widget.icon, style: const TextStyle(fontSize: 20)),
            ),
            title: Row(
              children: [
                Expanded(child: Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                if (widget.isWarning)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10)),
                    child: const Text('소진 임박', style: TextStyle(color: Color(0xFFFF5252), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                children: [
                  const TextSpan(text: '남은 약: '),
                  TextSpan(text: widget.days, style: TextStyle(color: widget.isWarning ? const Color(0xFFFF5252) : Colors.black, fontWeight: FontWeight.bold)),
                  TextSpan(text: '  •  ${widget.instruction}', style: const TextStyle(color: Color(0xFF2A8DE5), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // 우측 점 3개 버튼 (삭제 메뉴 토글)
            trailing: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _showDeleteMenu = !_showDeleteMenu;
                });
              },
            ),
          ),
          
          // 2. 삭제/취소 메뉴 (상태값에 따라 조건부 렌더링)
          if (_showDeleteMenu)
            Column(
              children: [
                const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          // TODO: 삭제 기능 로직 연결
                        },
                        child: const Text('삭제', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Container(width: 1, height: 20, color: const Color(0xFFEEEEEE)),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _showDeleteMenu = false; // 취소 누르면 메뉴 닫기
                          });
                        },
                        child: const Text('취소', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}