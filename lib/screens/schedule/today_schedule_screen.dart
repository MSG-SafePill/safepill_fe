import 'package:flutter/material.dart';

import '../../services/schedule_api.dart';
import '../camera/scan_medication.dart';
import '../chat/ai_chat.dart';
import '../medication/my_medication.dart';
import '../profile/profile.dart';

enum ScheduleViewStatus { completed, pending, shifted }

class TodayScheduleItem {
  final int? scheduleId;
  final IntakeSchedule? source;
  final String time;
  final String period;
  final String medicineName;
  final String condition;
  final String tag;
  final ScheduleViewStatus status;
  final bool isAiShifted;

  const TodayScheduleItem({
    this.scheduleId,
    this.source,
    required this.time,
    required this.period,
    required this.medicineName,
    required this.condition,
    required this.tag,
    required this.status,
    this.isAiShifted = false,
  });

  factory TodayScheduleItem.fromSchedule({
    required IntakeSchedule schedule,
    required bool isTaken,
    required bool isAiShifted,
  }) {
    return TodayScheduleItem(
      scheduleId: schedule.scheduleId,
      source: schedule,
      time: _normalizeTime(schedule.takeTime),
      period: _periodLabel(schedule.takeTime),
      medicineName: schedule.itemName,
      condition: schedule.dosage.isEmpty ? '복용 정보 확인 필요' : schedule.dosage,
      tag: _extractTag(schedule.dosage),
      status: isTaken
          ? ScheduleViewStatus.completed
          : isAiShifted
          ? ScheduleViewStatus.shifted
          : ScheduleViewStatus.pending,
      isAiShifted: isAiShifted,
    );
  }
}

class TodayScheduleScreen extends StatefulWidget {
  final List<IntakeSchedule> schedules;
  final Map<int, IntakeLog> logsByScheduleId;
  final Future<bool> Function(IntakeSchedule schedule, bool isTaken)?
  onTakenChanged;

  const TodayScheduleScreen({
    super.key,
    this.schedules = const [],
    this.logsByScheduleId = const {},
    this.onTakenChanged,
  });

  @override
  State<TodayScheduleScreen> createState() => _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen> {
  late List<TodayScheduleItem> _items;
  final Set<int> _savingIds = {};

  @override
  void initState() {
    super.initState();
    _items = _buildItems();
  }

  @override
  void didUpdateWidget(covariant TodayScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schedules != widget.schedules ||
        oldWidget.logsByScheduleId != widget.logsByScheduleId) {
      _items = _buildItems();
    }
  }

  List<TodayScheduleItem> _buildItems() {
    if (widget.schedules.isEmpty) return [];

    return widget.schedules.map((schedule) {
      final log = widget.logsByScheduleId[schedule.scheduleId];
      return TodayScheduleItem.fromSchedule(
        schedule: schedule,
        isTaken: log?.status == IntakeStatus.taken,
        isAiShifted: false,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _items
        .where((item) => item.status == ScheduleViewStatus.completed)
        .length;
    final remainingCount = _items.length - completedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6FAFF),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFF23364A),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          '오늘의 복약 스케줄',
          style: TextStyle(
            color: Color(0xFF23364A),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            color: const Color(0xFF7C8EA5),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: _buildCameraFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(context),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 132),
          children: [
            _ScheduleSummaryCard(
              total: _items.length,
              completed: completedCount,
              remaining: remainingCount,
            ),
            const SizedBox(height: 14),
            if (_items.isEmpty)
              const _EmptyTodaySchedule()
            else ...[
              ..._items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _CompactScheduleCard(
                    item: item,
                    isSaving: _savingIds.contains(item.scheduleId),
                    onToggleCompleted: () => _toggleCompleted(item),
                    onShowAiReason: _showAiReason,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const _ScheduleGuideText(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCameraFab(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 28),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A8DE5).withValues(alpha: 0.28),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: FloatingActionButton(
            heroTag: 'todayScheduleCameraFab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanMedicationScreen()),
              );
            },
            backgroundColor: const Color(0xFF2A8DE5),
            elevation: 0,
            shape: const CircleBorder(),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.home,
            label: '홈',
            isActive: true,
            onTap: () => Navigator.maybePop(context),
          ),
          _BottomNavItem(
            icon: Icons.medication,
            label: '마이약장',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyMedicationScreen()),
              );
            },
          ),
          const SizedBox(width: 40),
          _BottomNavItem(
            icon: Icons.smart_toy,
            label: 'AI 상담',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiChatScreen()),
              );
            },
          ),
          _BottomNavItem(
            icon: Icons.person,
            label: '내정보',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCompleted(TodayScheduleItem item) async {
    final scheduleId = item.scheduleId;
    if (scheduleId == null || _savingIds.contains(scheduleId)) return;

    final nextStatus = item.status == ScheduleViewStatus.completed
        ? (item.isAiShifted
              ? ScheduleViewStatus.shifted
              : ScheduleViewStatus.pending)
        : ScheduleViewStatus.completed;

    final previousItems = List<TodayScheduleItem>.from(_items);
    setState(() {
      _savingIds.add(scheduleId);
      _items = _items
          .map(
            (current) => current.scheduleId == scheduleId
                ? TodayScheduleItem(
                    scheduleId: current.scheduleId,
                    source: current.source,
                    time: current.time,
                    period: current.period,
                    medicineName: current.medicineName,
                    condition: current.condition,
                    tag: current.tag,
                    status: nextStatus,
                    isAiShifted: current.isAiShifted,
                  )
                : current,
          )
          .toList();
    });

    var saved = true;
    if (item.source != null && widget.onTakenChanged != null) {
      saved = await widget.onTakenChanged!(
        item.source!,
        nextStatus == ScheduleViewStatus.completed,
      );
    }

    if (!mounted) return;
    setState(() {
      _savingIds.remove(scheduleId);
      if (!saved) {
        _items = previousItems;
      }
    });
  }

  void _showAiReason() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI 재배치 이유',
                style: TextStyle(
                  color: Color(0xFF23364A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'AI 재배치 사유는 추후 상호작용 분석 API에서 전달되는 근거 데이터를 연결해 표시할 예정입니다.',
                style: TextStyle(
                  color: Color(0xFF65758A),
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A8DE5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScheduleSummaryCard extends StatelessWidget {
  final int total;
  final int completed;
  final int remaining;

  const _ScheduleSummaryCard({
    required this.total,
    required this.completed,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9E8FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF315F97).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF2A8DE5),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _SummaryPill(
                  label: '오늘 총 $total회 복약',
                  color: const Color(0xFF23364A),
                  background: const Color(0xFFF3F7FC),
                ),
                _SummaryPill(
                  label: '완료 $completed회',
                  color: const Color(0xFF18B58F),
                  background: const Color(0xFFE3F8F2),
                ),
                _SummaryPill(
                  label: '남은 $remaining회',
                  color: const Color(0xFFF08A00),
                  background: const Color(0xFFFFF4DF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _SummaryPill({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompactScheduleCard extends StatelessWidget {
  final TodayScheduleItem item;
  final bool isSaving;
  final VoidCallback onToggleCompleted;
  final VoidCallback onShowAiReason;

  const _CompactScheduleCard({
    required this.item,
    required this.isSaving,
    required this.onToggleCompleted,
    required this.onShowAiReason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isAiShifted
              ? const Color(0xFFBBD9FF)
              : const Color(0xFFE5ECF5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF315F97).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFFEAF3FF),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.time,
                  style: const TextStyle(
                    color: Color(0xFF2A72EA),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.period,
                  style: const TextStyle(
                    color: Color(0xFF2A72EA),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.medicineName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF23364A),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.condition,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7D8899),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _InfoChip(label: item.tag),
                      if (item.isAiShifted)
                        _InfoChip(
                          label: 'AI 재배치 이유 보기',
                          icon: Icons.lightbulb_outline_rounded,
                          onTap: onShowAiReason,
                          color: const Color(0xFF2A8DE5),
                          background: const Color(0xFFEAF3FF),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _StatusButton(
              status: item.status,
              isSaving: isSaving,
              onTap: onToggleCompleted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final ScheduleViewStatus status;
  final bool isSaving;
  final VoidCallback onTap;

  const _StatusButton({
    required this.status,
    required this.isSaving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      ScheduleViewStatus.completed => (
        icon: Icons.check_circle_rounded,
        label: '완료',
        color: const Color(0xFF18B58F),
      ),
      ScheduleViewStatus.shifted => (
        icon: Icons.sync_rounded,
        label: '재배치',
        color: const Color(0xFF2A8DE5),
      ),
      ScheduleViewStatus.pending => (
        icon: Icons.radio_button_unchecked_rounded,
        label: '예정',
        color: const Color(0xFF9AA8B8),
      ),
    };

    return InkWell(
      onTap: isSaving ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isSaving
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: config.color,
                    ),
                  )
                : Icon(config.icon, color: config.color, size: 28),
            const SizedBox(height: 3),
            Text(
              config.label,
              maxLines: 1,
              style: TextStyle(
                color: config.color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;
  final Color background;

  const _InfoChip({
    required this.label,
    this.icon,
    this.onTap,
    this.color = const Color(0xFF2A8DE5),
    this.background = const Color(0xFFEAF3FF),
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: child,
    );
  }
}

class _ScheduleGuideText extends StatelessWidget {
  const _ScheduleGuideText();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFF7D8899), size: 18),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            '복용 시간은 ±10분 범위 내에서 복용하시는 것을 권장드려요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF65758A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyTodaySchedule extends StatelessWidget {
  const _EmptyTodaySchedule();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5ECF5)),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_note_rounded, color: Color(0xFF2A8DE5), size: 42),
          SizedBox(height: 14),
          Text(
            '오늘 등록된 복약 스케줄이 없습니다',
            style: TextStyle(
              color: Color(0xFF23364A),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '약을 등록하면 오늘의 복약 일정이 이곳에 표시됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF65758A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF2A8DE5) : const Color(0xFF9AA0A6);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _normalizeTime(String value) {
  final parts = value.split(':');
  if (parts.length >= 2) {
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
  return value.isEmpty ? '--:--' : value;
}

String _periodLabel(String time) {
  final hour = int.tryParse(time.split(':').first) ?? 0;
  return hour < 12 ? '오전' : '오후';
}

String _extractTag(String detail) {
  if (detail.contains('취침')) return '취침 전';
  if (detail.contains('식사 중')) return '식사 중';
  if (detail.contains('식전')) return '식전';
  if (detail.contains('식후')) return '식후';
  if (detail.contains('공복')) return '공복';
  return '복용';
}
