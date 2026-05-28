import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/medication_api.dart';
import '../../services/schedule_api.dart';

class AddMedicationScreen extends StatefulWidget {
  final String? initialKeyword;

  const AddMedicationScreen({super.key, this.initialKeyword});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  // [상태 변수]
  final TextEditingController _searchController = TextEditingController();
  final MedicationApi _medicationApi = MedicationApi();
  final ScheduleApi _scheduleApi = ScheduleApi();
  bool isPrescription = true;
  Set<String> selectedTimes = {};
  int days = 30;
  bool _isSearching = false;
  bool _isSaving = false;
  List<MedicationSearchItem> _searchResults = [];
  MedicationSearchItem? _selectedItem;

  SearchItemType get _selectedType =>
      isPrescription ? SearchItemType.medicine : SearchItemType.supplement;

  List<MedicationSearchItem> get _visibleSearchResults => _searchResults
      .where((item) => item.type == _selectedType)
      .toList();

  @override
  void initState() {
    super.initState();
    final keyword = widget.initialKeyword?.trim();
    if (keyword != null && keyword.isNotEmpty) {
      _searchController.text = keyword;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchMedications();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchMedications() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('검색어를 입력해주세요.')));
      return;
    }

    setState(() {
      _isSearching = true;
      _selectedItem = null;
    });

    try {
      final results = await _medicationApi.searchPage(keyword, auth: true);
      if (mounted) {
        setState(() {
          _searchResults = results.items;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('검색 실패: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('서버와 연결할 수 없습니다.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _addMedication() async {
    final selectedItem = _selectedItem;
    if (selectedItem == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내 약장에 추가할 약품을 선택해주세요.')));
      return;
    }
    if (selectedItem.type != _selectedType) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선택한 분류에 맞는 검색 결과를 다시 선택해주세요.')));
      return;
    }
    if (selectedItem.registered) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 내 약장에 등록된 항목입니다.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _medicationApi.addToMyPills(selectedItem, supplyDays: days);
      await _createSchedulesIfSelected(selectedItem);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('내 약장에 추가되었습니다.')));
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('추가 실패: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('서버와 연결할 수 없습니다.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _createSchedulesIfSelected(MedicationSearchItem item) async {
    if (selectedTimes.isEmpty) {
      return;
    }

    final myPills = await _medicationApi.getMyPills();
    CabinetItem? registered;
    for (final pill in myPills) {
      if (pill.type == item.type && pill.itemId == item.id) {
        registered = pill;
      }
    }
    if (registered == null) {
      return;
    }

    final createdTimes = <String>{};
    for (final label in selectedTimes) {
      final takeTime = _timeLabelToTakeTime(label);
      if (takeTime == null || !createdTimes.add(takeTime)) {
        continue;
      }
      try {
        await _scheduleApi.createSchedule(
          regId: registered.regId,
          takeTime: takeTime,
          daysOfWeek: const ['EVERYDAY'],
          dosage: item.type == SearchItemType.medicine ? '1정' : '1회분',
        );
      } on ApiException {
        // 약장 등록은 성공했으므로 스케줄 중복 등은 화면 흐름을 막지 않습니다.
      }
    }
  }

  String? _timeLabelToTakeTime(String label) {
    if (label.contains('아침')) {
      return '08:00';
    }
    if (label.contains('점심')) {
      return '13:00';
    }
    if (label.contains('저녁')) {
      return '19:00';
    }
    if (label.contains('취침')) {
      return '22:00';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // [상단 앱바]
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '약품 직접 추가',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      // [메인 입력 폼 영역]
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 약품명 검색 입력창
            _buildSectionTitle('약품명 또는 성분명', isRequired: true),
            TextField(
              controller: _searchController,
              onSubmitted: (_) => _searchMedications(),
              decoration: InputDecoration(
                hintText: '예: 타이레놀, 오메가3',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF2A8DE5),
                        ),
                  onPressed: _isSearching ? null : _searchMedications,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.info, color: Color(0xFF2A8DE5), size: 14),
                SizedBox(width: 4),
                Text(
                  '정확한 상극 분석(DUR)을 위해 제품명을 검색해 주세요.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              if (_visibleSearchResults.isEmpty)
                Text(
                  isPrescription
                      ? '검색된 의약품이 없습니다. 영양제 결과를 보려면 분류를 변경하세요.'
                      : '검색된 영양제가 없습니다. 의약품 결과를 보려면 분류를 변경하세요.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 312),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: _visibleSearchResults.length > 4
                        ? const AlwaysScrollableScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    itemCount: _visibleSearchResults.length,
                    itemBuilder: (context, index) =>
                        _buildSearchResultTile(_visibleSearchResults[index]),
                  ),
                ),
            ],
            const SizedBox(height: 30),

            // 2. 약품 분류 선택 (처방약/일반약 vs 영양제)
            _buildSectionTitle('분류'),
            Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    '처방약 / 일반약',
                    isPrescription,
                    () => _selectCategory(SearchItemType.medicine),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildToggleButton(
                    '영양제',
                    !isPrescription,
                    () => _selectCategory(SearchItemType.supplement),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 3. 복용 시간 선택 (그리드 형태 다중 선택)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('복용 시간', isRequired: true),
                const Text(
                  '다중 선택 가능',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  [
                        _buildTimeButton('☀️ 아침 식전'),
                        _buildTimeButton('☀️ 아침 식후'),
                        _buildTimeButton('⛅ 점심 식전'),
                        _buildTimeButton('⛅ 점심 식후'),
                        _buildTimeButton('🌙 저녁 식전'),
                        _buildTimeButton('🌙 저녁 식후'),
                        _buildTimeButton('🛌 취침 전'),
                      ]
                      .map(
                        (widget) => FractionallySizedBox(
                          widthFactor: 0.48,
                          child: widget,
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 10),
            _buildTimeButton('시간 상관없이 필요 시 복용', isFullWidth: true),
            const SizedBox(height: 30),

            // 4. 복용 일수 카운터
            _buildSectionTitle('처방/구매 일수'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('총 며칠 분량인가요?', style: TextStyle(fontSize: 14)),
                  Row(
                    children: [
                      _buildRoundButton(
                        Icons.remove,
                        () => setState(() => days > 1 ? days-- : null),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$days',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A8DE5),
                          ),
                        ),
                      ),
                      _buildRoundButton(
                        Icons.add,
                        () => setState(() => days++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),

      // [하단 고정 버튼 영역]
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _addMedication,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A8DE5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: Text(
                _isSaving ? '추가 중...' : '마이약장에 추가하기',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- [UI 재사용 컴포넌트들] ---

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: RichText(
        text: TextSpan(
          text: title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          children: isRequired
              ? [
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Color(0xFF2A8DE5)),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF2A8DE5) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF2A8DE5) : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _selectCategory(SearchItemType type) {
    setState(() {
      isPrescription = type == SearchItemType.medicine;
      if (_selectedItem?.type != type) {
        _selectedItem = null;
      }
    });
  }

  Widget _buildTimeButton(String label, {bool isFullWidth = false}) {
    bool isSelected = selectedTimes.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedTimes.remove(label);
          } else {
            selectedTimes.add(label);
          }
        });
      },
      child: Container(
        height: 50,
        width: isFullWidth ? double.infinity : null,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF2A8DE5) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF2A8DE5) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRoundButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFFE3F2FD),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF2A8DE5)),
      ),
    );
  }

  Widget _buildSearchResultTile(MedicationSearchItem item) {
    final isSelected =
        _selectedItem?.type == item.type && _selectedItem?.id == item.id;
    final typeLabel = item.type == SearchItemType.medicine ? '의약품' : '영양제';

    return GestureDetector(
      onTap: () {
        if (item.registered) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('이미 등록된 항목입니다.')));
          return;
        }
        setState(() {
          _selectedItem = item;
          isPrescription = item.type == SearchItemType.medicine;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.registered
              ? Colors.grey.shade100
              : isSelected
              ? const Color(0xFFE3F2FD)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2A8DE5) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.type == SearchItemType.medicine
                  ? Icons.medication
                  : Icons.spa,
              color: isSelected ? const Color(0xFF2A8DE5) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$typeLabel${item.manufacturer == null ? '' : ' | ${item.manufacturer}'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF2A8DE5))
            else if (item.registered)
              const Text(
                '등록됨',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
