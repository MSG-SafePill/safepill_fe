import 'package:flutter/material.dart';
import 'profile_edit.dart';
import '../auth/landing.dart';
import 'health_info.dart';
import 'notification_settings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. 상단 파란색 헤더 영역 (홈 화면과 완벽 동일한 스타일 적용!)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 70, left: 20, right: 20, bottom: 30),
          decoration: const BoxDecoration(
            color: Color(0xFF2A8DE5),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25), 
              bottomRight: Radius.circular(25)
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('안녕하세요, 홍길동님!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('오늘도 건강한 하루 보내세요!', style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),

        // 2. 하단 리스트 영역
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // [내 정보] 섹션
              _buildSectionTitle('내 정보'),
              _buildMenuCard([
                _buildMenuItem(Icons.person, '프로필 관리', showDivider: true, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen()));
                }),
                _buildMenuItem(Icons.medical_information, '건강 정보 (기저질환/알레르기)', showDivider: false, onTap: () {
                  // ✨ 건강 정보 관리 화면으로 이동!
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const HealthInfoScreen())
                  );
                }),
              ]),
              const SizedBox(height: 30),

              // [앱 설정] 섹션
              _buildSectionTitle('앱 설정'),
              _buildMenuCard([
                _buildMenuItem(Icons.notifications_active, '복용 알림 설정', showDivider: false, onTap: () {
                  // ✨ 복용 알림 설정 화면으로 이동!
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
                }),
              ]),
              const SizedBox(height: 30),

              // [기타] 섹션
              _buildSectionTitle('기타'),
              _buildMenuCard([
                // 계정 관리는 삭제하고 바로 로그아웃만 배치!
                _buildMenuItem(Icons.logout, '로그아웃', showDivider: false, isDestructive: true, onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (context) => const LandingScreen()), 
                    (route) => false,
                  );
                }),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  // --- [UI 재사용 컴포넌트들] ---

  // 섹션 제목 (예: 내 정보, 앱 설정)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }

  // 하얀색 둥근 모서리 카드 (메뉴들을 감싸는 껍데기)
  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // 개별 메뉴 아이템 (아이콘 + 텍스트 + 화살표 + 클릭 액션)
  Widget _buildMenuItem(IconData icon, String title, {required bool showDivider, bool isDestructive = false, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFF0F7FF), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: isDestructive ? Colors.red : const Color(0xFF2A8DE5)),
          ),
          title: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDestructive ? Colors.red : Colors.black87),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          onTap: onTap, // 👈 밖에서 전달받은 클릭 액션을 실행합니다!
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0), indent: 20, endIndent: 20),
      ],
    );
  }
}