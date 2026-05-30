import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/profile_api.dart';

class HealthInfoScreen extends StatefulWidget {
  const HealthInfoScreen({super.key});

  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen> {
  // 사용자가 선택한 질환들을 담을 리스트
  final List<String> _selectedDiseases = [];
  final ProfileApi _profileApi = ProfileApi();

  // 추천 질환 목록
  final List<String> _recommendedDiseases = [
    '고혈압',
    '당뇨병',
    '고지혈증',
    '신장 질환',
    '간 질환',
    '심장 질환',
  ];

  final List<String> _allergies = [];
  final TextEditingController _allergyController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadHealthProfile();
  }

  @override
  void dispose() {
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthProfile() async {
    try {
      final profile = await _profileApi.getHealthProfile();
      if (profile != null && mounted) {
        setState(() {
          _selectedDiseases
            ..clear()
            ..addAll(_splitValues(profile.disease));
          _allergies
            ..clear()
            ..addAll(_splitValues(profile.allergy));
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(duration: const Duration(seconds: 2), content: Text('건강 정보 조회 실패: ${e.message}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveHealthProfile() async {
    setState(() => _isSaving = true);
    try {
      await _profileApi.saveHealthProfile(
        disease: _selectedDiseases.isEmpty
            ? '없음'
            : _selectedDiseases.join(', '),
        allergy: _allergies.isEmpty ? '없음' : _allergies.join(', '),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(duration: Duration(seconds: 2), content: Text('건강 정보가 저장되었습니다.')));
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(duration: const Duration(seconds: 2), content: Text('저장 실패: ${e.message}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteHealthProfile() async {
    try {
      await _profileApi.deleteHealthProfile();
      if (mounted) {
        setState(() {
          _selectedDiseases.clear();
          _allergies.clear();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(duration: Duration(seconds: 2), content: Text('건강 정보가 삭제되었습니다.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(duration: const Duration(seconds: 2), content: Text('삭제 실패: ${e.message}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '건강 정보 관리',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 질환 정보 섹션
                  _buildTitle('보유 질환', '해당하는 질환을 선택해주세요.'),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _recommendedDiseases.map((disease) {
                      final isSelected = _selectedDiseases.contains(disease);
                      return FilterChip(
                        label: Text(disease),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDiseases.add(disease);
                            } else {
                              _selectedDiseases.remove(disease);
                            }
                          });
                        },
                        selectedColor: const Color(
                          0xFF2A8DE5,
                        ).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF2A8DE5),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF2A8DE5)
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF2A8DE5)
                                : Colors.transparent,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 40),

                  // 2. 알레르기 섹션
                  _buildTitle('알레르기 정보', '복용 시 부작용이 있는 성분을 입력하세요.'),
                  const SizedBox(height: 15),

                  // 알레르기 입력창
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _allergyController,
                          decoration: InputDecoration(
                            hintText: '예: 아스피린, 항생제 등',
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (_allergyController.text.isNotEmpty) {
                            setState(() {
                              _allergies.add(_allergyController.text);
                              _allergyController.clear();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A8DE5),
                          minimumSize: const Size(60, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '추가',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // 추가된 알레르기 리스트 (칩 형태)
                  Wrap(
                    spacing: 8,
                    children: _allergies.map((allergy) {
                      return Chip(
                        label: Text(allergy),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _allergies.remove(allergy);
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 60),

                  // 3. 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveHealthProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A8DE5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isSaving ? '저장 중...' : '건강 정보 저장하기',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _deleteHealthProfile,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('건강 정보 삭제'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<String> _splitValues(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '없음') {
      return [];
    }
    return trimmed
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Widget _buildTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
