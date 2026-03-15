import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // --- 상태 변수 (토글 스위치 및 시간) ---
  bool _isAllAlarmOn = true;
  bool _isSoundVibrateOn = false;
  bool _isRefillAlarmOn = true;

  // 초기 시간 설정값 (TimeOfDay 객체 사용)
  TimeOfDay _morningTime = const TimeOfDay(hour: 8, minute: 30);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _nightTime = const TimeOfDay(hour: 23, minute: 30);

  // 시간을 '오전 08:30' 형태로 예쁘게 바꿔주는 함수
  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final isAm = dt.hour < 12;
    int hour = dt.hour % 12;
    if (hour == 0) hour = 12;
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return '${isAm ? '오전' : '오후'} $hour:$minuteStr';
  }

  // 시간 선택 팝업 띄우기
  Future<void> _selectTime(BuildContext context, TimeOfDay initialTime, Function(TimeOfDay) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        // 시간 선택기 테마 설정 (파란색 포인트)
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2A8DE5)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != initialTime) {
      onTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 살짝 회색 배경
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('복용 알림 설정', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 전체 알림 켜기 카드
            _buildMainToggleCard(),
            const SizedBox(height: 30),

            // 2. 기본 알림 시간대 섹션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('기본 알림 시간대', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {},
                  child: const Text('패턴 맞춤형', style: TextStyle(color: Color(0xFF2A8DE5), fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            _buildWhiteCard([
              _buildTimeSettingRow('☀️ 아침 식후', _morningTime, (t) => setState(() => _morningTime = t)),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              _buildTimeSettingRow('⛅ 점심 식후', _lunchTime, (t) => setState(() => _lunchTime = t)),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              _buildTimeSettingRow('🌙 저녁 식후', _dinnerTime, (t) => setState(() => _dinnerTime = t)),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              _buildTimeSettingRow('🛌 취침 전', _nightTime, (t) => setState(() => _nightTime = t)),
            ]),
            const SizedBox(height: 30),

            // 3. 상세 설정 섹션
            const Padding(
              padding: EdgeInsets.only(bottom: 10, left: 5),
              child: Text('상세 설정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            _buildWhiteCard([
              _buildSettingMenu('스누즈 (미루기) 간격', '10분 후', onTap: () {
                // TODO: 스누즈 시간 설정 바텀시트
              }),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              _buildToggleRow('소리 및 진동 알림', '매너모드에서도 소리를 울립니다.', _isSoundVibrateOn, (val) => setState(() => _isSoundVibrateOn = val)),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              _buildToggleRow('약 소진 임박 알림', '약이 3일 치 이하로 남으면 알려줍니다.', _isRefillAlarmOn, (val) => setState(() => _isRefillAlarmOn = val)),
            ]),
            const SizedBox(height: 40),

            // 4. 저장 버튼 (사진 오른쪽에 있는 파란 버튼)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 설정 저장 로직
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A8DE5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('설정 저장하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI 재사용 컴포넌트 ---

  // 맨 위 메인 토글 카드
  Widget _buildMainToggleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFF0F7FF), shape: BoxShape.circle),
            child: const Icon(Icons.notifications, color: Color(0xFF2A8DE5)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('전체 알림 켜기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('앱의 모든 푸시 알림을 받습니다.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(
            value: _isAllAlarmOn,
            onChanged: (val) => setState(() => _isAllAlarmOn = val),
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF2A8DE5),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  // 하얀색 둥근 배경 카드 (공통)
  Widget _buildWhiteCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: children),
    );
  }

  // 시간 설정 행 (아침 식후 등)
  Widget _buildTimeSettingRow(String label, TimeOfDay time, Function(TimeOfDay) onTimeChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: GestureDetector(
        onTap: () => _selectTime(context, time, onTimeChanged),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: Text(_formatTime(time), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
      ),
    );
  }

  // 스누즈 간격 등 화살표 메뉴 행
  Widget _buildSettingMenu(String title, String value, {required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Color(0xFF2A8DE5), fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  // 토글 스위치가 있는 상세 설정 행
  Widget _buildToggleRow(String title, String subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF2A8DE5),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey[300],
      ),
    );
  }
}