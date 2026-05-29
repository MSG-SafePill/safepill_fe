import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/medication_api.dart';
import 'add_medication.dart';
import 'analysis_result.dart';

class MyMedicationScreen extends StatefulWidget {
  const MyMedicationScreen({super.key});

  @override
  State<MyMedicationScreen> createState() => _MyMedicationScreenState();
}

class _MyMedicationScreenState extends State<MyMedicationScreen> {
  final MedicationApi _medicationApi = MedicationApi();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<CabinetItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadMyPills();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMyPills() async {
    setState(() => _isLoading = true);
    try {
      final items = await _medicationApi.getMyPills();
      if (mounted) {
        setState(() => _items = items);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('약장 조회 실패: ${e.message}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteMyPill(int regId) async {
    try {
      await _medicationApi.deleteMyPill(regId);
      if (mounted) {
        setState(() => _items.removeWhere((item) => item.regId == regId));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('내 약장에서 삭제되었습니다.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('삭제 실패: ${e.message}')));
      }
    }
  }

  List<CabinetItem> _filteredItems(SearchItemType? type) {
    final keyword = _searchController.text.trim();
    return _items.where((item) {
      final typeMatched = type == null || item.type == type;
      final keywordMatched = keyword.isEmpty || item.itemName.contains(keyword);
      return typeMatched && keywordMatched;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // [탭 제어기: 전체, 처방약, 영양제 3개 탭 구성]
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAFF),
        body: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: _buildSearchField(),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildPillList(_filteredItems(null)),
                        _buildPillList(_filteredItems(SearchItemType.medicine)),
                        _buildPillList(
                          _filteredItems(SearchItemType.supplement),
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
              MaterialPageRoute(
                builder: (context) => const AddMedicationScreen(),
              ),
            ).then((_) => _loadMyPills());
          },
          backgroundColor: const Color(0xFF2A8DE5),
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 35),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final total = _items.length;
    final medicines = _items
        .where((item) => item.type == SearchItemType.medicine)
        .length;
    final supplements = _items
        .where((item) => item.type == SearchItemType.supplement)
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 66, 28, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF43A3FF), Color(0xFF1F6FEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '마이약장',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  total == 0
                      ? '복용 중인 약을 등록해보세요'
                      : '전체 $total개 · 처방약 $medicines개 · 영양제 $supplements개',
                  style: const TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '상호작용 분석',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalysisResult()),
              );
            },
            icon: const Icon(Icons.health_and_safety_rounded),
            color: Colors.white,
            iconSize: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: const TabBar(
        labelColor: Color(0xFF2A8DE5),
        unselectedLabelColor: Color(0xFF9AA3AE),
        indicatorColor: Color(0xFF2A8DE5),
        indicatorWeight: 3,
        labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(text: '전체'),
          Tab(text: '처방약'),
          Tab(text: '영양제'),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '약품명 또는 성분명 검색',
        hintStyle: const TextStyle(color: Color(0xFF9AA3AE)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9AA3AE)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5ECF5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF2A8DE5)),
        ),
      ),
    );
  }

  Widget _buildPillList(List<CabinetItem> items) {
    if (items.isEmpty) {
      return const _EmptyMedicationList();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: items
          .map(
            (item) => PillCard(
              icon: item.type == SearchItemType.medicine ? '💊' : '🌿',
              name: item.itemName,
              days: item.supplyDays == null ? '미설정' : '${item.supplyDays}일',
              instruction: item.efficacy?.isNotEmpty == true
                  ? item.efficacy!
                  : item.manufacturer ?? '',
              isWarning: false,
              onDelete: () => _deleteMyPill(item.regId),
            ),
          )
          .toList(),
    );
  }
}

class _EmptyMedicationList extends StatelessWidget {
  const _EmptyMedicationList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF3FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_liquid_rounded,
                color: Color(0xFF2A8DE5),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '등록된 항목이 없습니다',
              style: TextStyle(
                color: Color(0xFF23364A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '오른쪽 아래 + 버튼으로 복용 중인 약이나 영양제를 등록하세요.',
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

// --- [개별 약품 카드 UI 컴포넌트] ---
class PillCard extends StatefulWidget {
  final String icon;
  final String name;
  final String days;
  final String instruction;
  final bool isWarning; // 소진 임박 등 경고 상태 체크
  final VoidCallback? onDelete;

  const PillCard({
    super.key,
    required this.icon,
    required this.name,
    required this.days,
    required this.instruction,
    this.isWarning = false,
    this.onDelete,
  });

  @override
  State<PillCard> createState() => _PillCardState();
}

class _PillCardState extends State<PillCard> {
  // [상태 변수] 삭제 메뉴 활성화 여부
  bool _showDeleteMenu = false;

  void _showInstructionDetail() {
    setState(() => _showDeleteMenu = false);

    final detail = widget.instruction.trim();
    if (detail.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '효능 및 정보',
                  style: TextStyle(
                    color: Color(0xFF2A8DE5),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // 경고 상태일 경우 좌측 빨간색 테두리 적용
        border: widget.isWarning
            ? const Border(left: BorderSide(color: Color(0xFFFF5252), width: 5))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. 기본 약품 정보 표시 영역
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 5,
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFF8E1),
              child: Text(widget.icon, style: const TextStyle(fontSize: 20)),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (widget.isWarning)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '소진 임박',
                      style: TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text.rich(
              TextSpan(
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                children: [
                  const TextSpan(text: '남은 약: '),
                  TextSpan(
                    text: widget.days,
                    style: TextStyle(
                      color: widget.isWarning
                          ? const Color(0xFFFF5252)
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.instruction.trim().isNotEmpty)
                    TextSpan(
                      text: '  •  ${widget.instruction.trim()}',
                      style: const TextStyle(
                        color: Color(0xFF2A8DE5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: widget.instruction.trim().isEmpty
                            ? null
                            : _showInstructionDetail,
                        child: const Text(
                          '자세히 보기',
                          style: TextStyle(
                            color: Color(0xFF2A8DE5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: const Color(0xFFEEEEEE),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          widget.onDelete?.call();
                          setState(() {
                            _showDeleteMenu = false;
                          });
                        },
                        child: const Text(
                          '삭제',
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: const Color(0xFFEEEEEE),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _showDeleteMenu = false; // 취소 누르면 메뉴 닫기
                          });
                        },
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
