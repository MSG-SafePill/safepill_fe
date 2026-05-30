import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/local_profile_api.dart';
import '../../services/schedule_api.dart';
import '../../services/user_profile_api.dart';
import '../camera/scan_medication.dart';
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
  int _homeReloadKey = 0;

  // [화면 목록]
  List<Widget> get _pages => [
    HomeContent(
      key: ValueKey(_homeReloadKey),
      onScan: () {
        setState(() => _currentIndex = 2);
      },
    ), // 0: 홈
    const MyMedicationScreen(), // 1: 마이약장
    const ScanMedicationScreen(), // 2: 카메라
    const AiChatScreen(), // 3: AI 상담
    const ProfileScreen(), // 4: 내정보
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
                color: const Color(0xFF2A8DE5).withValues(alpha: 0.3),
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
                setState(() {
                  _currentIndex = 2;
                });
              },
              backgroundColor: const Color(0xFF2A8DE5), // 기존 테마 컬러 유지
              elevation: 0,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 30,
              ),
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
          if (index == 0) {
            _homeReloadKey++;
          }
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
class HomeContent extends StatefulWidget {
  final VoidCallback onScan;

  const HomeContent({super.key, required this.onScan});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ScheduleApi _scheduleApi = ScheduleApi();
  final UserProfileApi _userProfileApi = UserProfileApi();
  final LocalProfileApi _localProfileApi = LocalProfileApi();
  bool _isLoading = true;
  String _username = '사용자';
  List<IntakeSchedule> _schedules = [];
  Map<int, IntakeLog> _logsByScheduleId = {};

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadTodaySchedules();
  }

  Future<void> _loadUsername() async {
    try {
      final profile = await _userProfileApi.getProfile();
      if (mounted) {
        setState(() => _username = profile.username);
      }
    } catch (_) {
      final profile = await _localProfileApi.getProfile();
      if (mounted) {
        setState(() => _username = profile.nickname);
      }
    }
  }

  Future<void> _loadTodaySchedules() async {
    setState(() => _isLoading = true);
    try {
      final schedules = await _scheduleApi.getTodaySchedules();
      final logs = await _scheduleApi.getLogsByDate(DateTime.now());
      schedules.sort(_compareSchedules);
      if (mounted) {
        setState(() {
          _schedules = schedules;
          _logsByScheduleId = {for (final log in logs) log.scheduleId: log};
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(duration: const Duration(seconds: 2), content: Text('오늘의 스케줄 조회 실패: ${e.message}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _setTaken(IntakeSchedule schedule, bool isTaken) async {
    try {
      final existingLog = _logsByScheduleId[schedule.scheduleId];
      if (!isTaken && existingLog != null) {
        await _scheduleApi.deleteLog(existingLog.logId);
        if (mounted) {
          setState(() => _logsByScheduleId.remove(schedule.scheduleId));
        }
        return true;
      }
      final status = isTaken ? IntakeStatus.taken : IntakeStatus.skipped;
      final log = existingLog == null
          ? await _scheduleApi.createLog(
              scheduleId: schedule.scheduleId,
              status: status,
            )
          : await _scheduleApi.updateLog(
              logId: existingLog.logId,
              status: status,
              actualTime: DateTime.now(),
            );
      if (mounted) {
        setState(() => _logsByScheduleId[schedule.scheduleId] = log);
      }
      return true;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(duration: const Duration(seconds: 2), content: Text('복약 기록 저장 실패: ${e.message}')));
      }
      return false;
    }
  }

  Future<void> _deleteSchedule(IntakeSchedule schedule) async {
    try {
      await _scheduleApi.deleteSchedule(schedule.scheduleId);
      if (mounted) {
        setState(() {
          _schedules.removeWhere(
            (item) => item.scheduleId == schedule.scheduleId,
          );
          _logsByScheduleId.remove(schedule.scheduleId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(duration: Duration(seconds: 2), content: Text('스케줄이 삭제되었습니다.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(duration: const Duration(seconds: 2), content: Text('스케줄 삭제 실패: ${e.message}')));
      }
    }
  }

  Future<void> _editScheduleTime(IntakeSchedule schedule) async {
    final current = _parseTimeOfDay(schedule.takeTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? TimeOfDay.now(),
    );
    if (picked == null) {
      return;
    }
    final takeTime =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    try {
      final updated = await _scheduleApi.updateSchedule(
        scheduleId: schedule.scheduleId,
        takeTime: takeTime,
      );
      if (mounted) {
        setState(() {
          final index = _schedules.indexWhere(
            (item) => item.scheduleId == updated.scheduleId,
          );
          if (index >= 0) {
            _schedules[index] = updated;
            _schedules.sort(_compareSchedules);
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(duration: const Duration(seconds: 2), content: Text('스케줄 수정 실패: ${e.message}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadTodaySchedules,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 102),
          children: [
            _buildTopBar(),
            const SizedBox(height: 10),
            _buildHeroCard(),
            const SizedBox(height: 12),
            _buildScheduleSection(),
            const SizedBox(height: 12),
            _buildScanActionCard(),
            const SizedBox(height: 12),
            _buildAnalysisSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu_rounded),
          color: const Color(0xFF8793A3),
          iconSize: 30,
          tooltip: '메뉴',
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
              color: const Color(0xFF8793A3),
              iconSize: 30,
              tooltip: '알림',
            ),
            Positioned(
              right: 11,
              top: 10,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF2A8DE5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return SizedBox(
      height: 178,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF43A3FF), Color(0xFF0A58E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1975F6).withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: 22,
              child: Opacity(opacity: 0.92, child: _heroIllustration()),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요, $_username님!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '오늘의 안전 복약\n스케줄이 생성되었습니다.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.28,
                  ),
                ),
                const Spacer(),
                const Text(
                  '규칙적인 복용으로 건강을 지켜보세요!',
                  style: TextStyle(
                    color: Color(0xDFFFFFFF),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroIllustration() {
    return SizedBox(
      width: 124,
      height: 116,
      child: Stack(
        children: [
          Positioned(
            top: 2,
            right: 14,
            child: Container(
              width: 68,
              height: 78,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF88F0F5), Color(0xFF45B9EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 10,
            child: Transform.rotate(
              angle: -0.65,
              child: Container(
                width: 62,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF93DAFF),
                      Color(0xFF93DAFF),
                      Colors.white,
                      Colors.white,
                    ],
                    stops: [0, 0.5, 0.5, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 18,
            child: Transform.rotate(
              angle: 0.25,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.horizontal_rule,
                  color: Color(0xFFCFD7E3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    final nextSchedule = _nextSchedule();
    final nextLog = nextSchedule == null
        ? null
        : _logsByScheduleId[nextSchedule.scheduleId];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF2A8DE5),
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  '오늘의 복약 스케줄',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF23364A),
                  ),
                ),
              ),
              TextButton(
                onPressed: _openScheduleOverview,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEAF3FF),
                  foregroundColor: const Color(0xFF2A8DE5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '전체 보기',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 34),
              child: CircularProgressIndicator(),
            )
          else if (_schedules.isEmpty)
            _buildEmptyScheduleCard()
          else ...[
            HomeMedicationCard(
              key: ValueKey(nextSchedule!.scheduleId),
              time: nextSchedule.takeTime,
              name: _shortMedicationName(nextSchedule.itemName),
              detail: nextSchedule.dosage,
              username: _username,
              isInitiallyTaken: nextLog?.status == IntakeStatus.taken,
              onTakenChanged: (isTaken) => _setTaken(nextSchedule, isTaken),
              onEditSchedule: () => _editScheduleTime(nextSchedule),
              onDeleteSchedule: () => _deleteSchedule(nextSchedule),
            ),
            const SizedBox(height: 10),
            _buildScheduleSummaryRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleSummaryRow() {
    final total = _schedules.length;
    final remaining = _remainingCount();
    final completed = total - remaining;

    return Row(
      children: [
        _SummaryChip(
          icon: Icons.event_available_rounded,
          label: '오늘 $total회',
          color: const Color(0xFF2A8DE5),
        ),
        const SizedBox(width: 8),
        _SummaryChip(
          icon: Icons.check_circle_outline_rounded,
          label: '완료 $completed회',
          color: const Color(0xFF18B58F),
        ),
        const SizedBox(width: 8),
        _SummaryChip(
          icon: Icons.access_time_rounded,
          label: '남은 $remaining회',
          color: const Color(0xFFE8A13F),
        ),
      ],
    );
  }

  IntakeSchedule? _nextSchedule() {
    if (_schedules.isEmpty) return null;

    for (final schedule in _schedules) {
      final log = _logsByScheduleId[schedule.scheduleId];
      if (log?.status != IntakeStatus.taken) {
        return schedule;
      }
    }
    return _schedules.first;
  }

  String _shortMedicationName(String name) {
    var result = name.trim();
    result = result.replaceAll(RegExp(r'\(.+?\)'), '');
    result = result.replaceAll('밀리그램', 'mg');
    result = result.replaceAll('마이크로그램', 'mcg');
    result = result.replaceAll('캡슐제', '캡슐');
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    return result;
  }

  Widget _buildEmptyScheduleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0EAF6)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF3FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medication_liquid_rounded,
              color: Color(0xFF2A8DE5),
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '등록된 복약 스케줄이 없습니다',
            style: TextStyle(
              color: Color(0xFF23364A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '약을 등록하면 맞춤형 복약 스케줄이 표시됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF65758A), fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: widget.onScan,
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('약 등록하러 가기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A8DE5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _remainingCount() {
    if (_schedules.isEmpty) return 0;
    return _schedules.where((schedule) {
      final log = _logsByScheduleId[schedule.scheduleId];
      return log?.status != IntakeStatus.taken;
    }).length;
  }

  Widget _buildScanActionCard() {
    return InkWell(
      onTap: widget.onScan,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD4E7FF)),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43A3FF), Color(0xFF0A58E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 31,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '약 촬영하기',
                    style: TextStyle(
                      color: Color(0xFF23364A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '약 정보를 인식하고 복용 관리를 도와드려요.',
                    style: TextStyle(color: Color(0xFF65758A), fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF2A8DE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2FAF3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF23C7B5),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '상호작용 분석 요약',
                      style: TextStyle(
                        color: Color(0xFF23364A),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 7),
                    Row(
                      children: [
                        _SafeBadge(),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '현재 복용 중인 약 조합은 안전합니다.',
                            style: TextStyle(
                              color: Color(0xFF23364A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 7),
                    Text(
                      '마지막 분석: 오늘 07:30',
                      style: TextStyle(color: Color(0xFF8793A3), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF2A8DE5)),
                SizedBox(width: 8),
                Text(
                  '건강 팁',
                  style: TextStyle(
                    color: Color(0xFF2A8DE5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Spacer(),
                Flexible(
                  flex: 4,
                  child: Text(
                    '규칙적인 복용이 건강의 시작입니다!',
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF65758A)),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Color(0xFF2A8DE5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE7EEF7)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF315F97).withValues(alpha: 0.08),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  void _openScheduleOverview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ScheduleOverviewScreen(
          username: _username,
          schedules: _schedules,
          logsByScheduleId: _logsByScheduleId,
          onTakenChanged: _setTaken,
          onEditSchedule: _editScheduleTime,
          onDeleteSchedule: _deleteSchedule,
        ),
      ),
    );
  }
}

class _SafeBadge extends StatelessWidget {
  const _SafeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF8EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '안전',
        style: TextStyle(color: Color(0xFF12A87E), fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleOverviewScreen extends StatelessWidget {
  final String username;
  final List<IntakeSchedule> schedules;
  final Map<int, IntakeLog> logsByScheduleId;
  final Future<bool> Function(IntakeSchedule schedule, bool isTaken)
  onTakenChanged;
  final Future<void> Function(IntakeSchedule schedule) onEditSchedule;
  final Future<void> Function(IntakeSchedule schedule) onDeleteSchedule;

  const _ScheduleOverviewScreen({
    required this.username,
    required this.schedules,
    required this.logsByScheduleId,
    required this.onTakenChanged,
    required this.onEditSchedule,
    required this.onDeleteSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final items = schedules.map((schedule) {
      final log = logsByScheduleId[schedule.scheduleId];
      return HomeMedicationCard(
        key: ValueKey(schedule.scheduleId),
        time: schedule.takeTime,
        name: schedule.itemName,
        detail: schedule.dosage,
        username: username,
        isInitiallyTaken: log?.status == IntakeStatus.taken,
        onTakenChanged: (isTaken) => onTakenChanged(schedule, isTaken),
        onEditSchedule: () => onEditSchedule(schedule),
        onDeleteSchedule: () => onDeleteSchedule(schedule),
      );
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        title: const Text('전체 복약 스케줄'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF23364A),
        elevation: 0,
      ),
      body: schedules.isEmpty
          ? const _EmptyScheduleOverview()
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemBuilder: (context, index) => items[index],
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemCount: items.length,
            ),
    );
  }
}

class _EmptyScheduleOverview extends StatelessWidget {
  const _EmptyScheduleOverview();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF3FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_rounded,
                color: Color(0xFF2A8DE5),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 생성된 스케줄이 없습니다',
              style: TextStyle(
                color: Color(0xFF23364A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '약을 등록하면 사용자의 복약 정보에 맞춰 오늘의 스케줄이 표시됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF65758A),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
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
  final String username;
  final bool showAiButton;
  final bool isInitiallyTaken;
  final Future<bool> Function(bool isTaken)? onTakenChanged;
  final VoidCallback? onEditSchedule;
  final VoidCallback? onDeleteSchedule;
  final Color iconColor;

  const HomeMedicationCard({
    super.key,
    required this.time,
    required this.name,
    required this.detail,
    required this.username,
    this.showAiButton = false,
    this.isInitiallyTaken = false,
    this.onTakenChanged,
    this.onEditSchedule,
    this.onDeleteSchedule,
    this.iconColor = const Color(0xFF2A8DE5),
  });

  @override
  State<HomeMedicationCard> createState() => _HomeMedicationCardState();
}

class _HomeMedicationCardState extends State<HomeMedicationCard> {
  late bool isTaken;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    isTaken = widget.isInitiallyTaken;
  }

  @override
  void didUpdateWidget(covariant HomeMedicationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isInitiallyTaken != widget.isInitiallyTaken) {
      isTaken = widget.isInitiallyTaken;
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = _periodLabel(widget.time);
    final displayTime = _displayTime(widget.time);
    final isAnytime = _isAnytimeSlot(widget.time);
    final canEdit =
        widget.onEditSchedule != null || widget.onDeleteSchedule != null;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5ECF5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(color: Color(0xFFEAF3FF)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayTime,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isAnytime ? 13 : 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2A72EA),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    period,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2A72EA),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: widget.iconColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            Icons.medical_services_rounded,
                            color: widget.iconColor,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF23364A),
                            ),
                          ),
                        ),
                        if (canEdit)
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: Color(0xFF9AA8B8),
                              ),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  widget.onEditSchedule?.call();
                                }
                                if (value == 'delete') {
                                  widget.onDeleteSchedule?.call();
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('시간 수정'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('스케줄 삭제'),
                                ),
                              ],
                            ),
                          )
                        else
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFC0CAD7),
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF65758A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isSaving
                              ? null
                              : () async {
                                  final next = !isTaken;
                                  setState(() {
                                    isTaken = next;
                                    _isSaving = true;
                                  });
                                  final saved =
                                      await widget.onTakenChanged?.call(next) ??
                                      true;
                                  if (mounted) {
                                    setState(() {
                                      if (!saved) {
                                        isTaken = !next;
                                      }
                                      _isSaving = false;
                                    });
                                  }
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isTaken
                                  ? const Color(0xFFE3F8F2)
                                  : const Color(0xFFF1F5FA),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isTaken
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: isTaken
                                      ? const Color(0xFF18B58F)
                                      : const Color(0xFF9AA8B8),
                                  size: 17,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isTaken ? '완료' : '전',
                                  style: TextStyle(
                                    color: isTaken
                                        ? const Color(0xFF18B58F)
                                        : const Color(0xFF7D8899),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.showAiButton) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () => _showAiDialog(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF5FB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFD6EAF8),
                              ),
                            ),
                            child: const Text(
                              'AI 재배치 이유 보기',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2A8DE5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel(String value) {
    if (_isAnytimeSlot(value)) return '수시';
    final hour = int.tryParse(value.split(':').first);
    if (hour == null) return '';
    return hour < 12 ? '오전' : '오후';
  }

  String _displayTime(String value) {
    return _isAnytimeSlot(value) ? '상관없음' : value;
  }

  // --- 중앙 팝업 (Dialog) 띄우는 함수 ---
  void _showAiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                    Text(
                      'AI 상호작용 분석 리포트',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${widget.username}님의 기저질환(당뇨)과 등록된 약물 간의 상호작용 분석 결과입니다.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                    height: 1.5,
                  ),
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
                      Text(
                        '⚠️ 위험도 높음 (저혈당 쇼크)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE74C3C),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '홍삼이 인슐린 분비를 촉진하여 메트포르민과 병용 시 심각한 저혈당 위험이 발생할 수 있습니다.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFC0392B),
                          height: 1.4,
                        ),
                      ),
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
                      Text(
                        '✅ 스케줄 안전 재배치 완료',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '안전한 체내 흡수를 위해 두 약물의 복용 시간을 최소 4시간 이상 분리하여 스케줄을 재배치했습니다.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E8449),
                          height: 1.4,
                        ),
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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

TimeOfDay? _parseTimeOfDay(String value) {
  if (_isAnytimeSlot(value)) {
    return null;
  }
  final parts = value.split(':');
  if (parts.length < 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }
  return TimeOfDay(hour: hour, minute: minute);
}

int _compareSchedules(IntakeSchedule a, IntakeSchedule b) {
  final aKey = _scheduleSortKey(a.takeTime);
  final bKey = _scheduleSortKey(b.takeTime);
  if (aKey != bKey) {
    return aKey.compareTo(bKey);
  }
  return a.itemName.compareTo(b.itemName);
}

int _scheduleSortKey(String value) {
  if (_isAnytimeSlot(value)) {
    return -1;
  }
  final parts = value.split(':');
  if (parts.length < 2) {
    return 24 * 60;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return 24 * 60;
  }
  return hour * 60 + minute;
}

bool _isAnytimeSlot(String value) {
  final normalized = value.trim().toUpperCase();
  return normalized == 'ANYTIME' || normalized == '상관없음';
}
