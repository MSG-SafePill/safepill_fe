import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/user_profile_api.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final UserProfileApi _userProfileApi = UserProfileApi();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(
    text: '********',
  );
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _userProfileApi.getProfile();
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = profile;
        _nicknameController.text = profile.username;
        _emailController.text = profile.email.isEmpty
            ? profile.loginId
            : profile.email;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(duration: const Duration(seconds: 2), content: Text('프로필 조회 실패: ${e.message}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(duration: Duration(seconds: 2), content: Text('닉네임을 입력해주세요.')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final profile = await _userProfileApi.updateProfile(username: nickname);
      if (!mounted) {
        return;
      }
      setState(() => _profile = profile);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(duration: Duration(seconds: 2), content: Text('프로필이 저장되었습니다.')));
      Navigator.pop(context);
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

  Future<void> _showPasswordChangeDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final rootContext = context;
    bool isChanging = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final currentPassword = currentController.text.trim();
              final newPassword = newController.text.trim();
              final confirmPassword = confirmController.text.trim();
              if (currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(duration: Duration(seconds: 2), content: Text('비밀번호를 모두 입력해주세요.')),
                );
                return;
              }
              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(duration: Duration(seconds: 2), content: Text('새 비밀번호가 일치하지 않습니다.')),
                );
                return;
              }
              setDialogState(() => isChanging = true);
              try {
                await _userProfileApi.changePassword(
                  currentPassword: currentPassword,
                  newPassword: newPassword,
                );
                if (!rootContext.mounted) {
                  return;
                }
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(
                  rootContext,
                ).showSnackBar(const SnackBar(duration: Duration(seconds: 2), content: Text('비밀번호가 변경되었습니다.')));
              } on ApiException catch (e) {
                if (rootContext.mounted) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(duration: const Duration(seconds: 2), content: Text('비밀번호 변경 실패: ${e.message}')),
                  );
                }
              } finally {
                if (rootContext.mounted) {
                  setDialogState(() => isChanging = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('비밀번호 변경'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '현재 비밀번호'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '새 비밀번호'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '새 비밀번호 확인'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isChanging ? null : () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: isChanging ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A8DE5),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isChanging ? '변경 중...' : '변경'),
                ),
              ],
            );
          },
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
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
          onPressed: () => Navigator.pop(context), // 뒤로 가기
        ),
        title: const Text(
          '프로필 관리',
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
                  const SizedBox(height: 20),

                  // 1. 프로필 사진 & 변경 버튼 영역
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            // 동그란 프사 배경
                            Container(
                              width: 100,
                              height: 100,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE3F2FD), // 연한 파란색 배경
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: Color(0xFF2A8DE5),
                              ),
                            ),
                            // 우측 하단 작은 카메라 아이콘 (뱃지)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '사진 변경',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 2. 닉네임 입력란
                  _buildLabel('닉네임'),
                  TextField(
                    controller: _nicknameController,
                    decoration: _inputDecoration(),
                  ),
                  const SizedBox(height: 25),

                  // 3. 이메일 계정 (수정 불가)
                  _buildLabel('이메일 계정'),
                  TextField(
                    controller: _emailController,
                    readOnly: true, // 읽기 전용으로 설정
                    style: const TextStyle(
                      color: Colors.black54,
                    ), // 수정 불가 느낌을 위해 색상 살짝 연하게
                    decoration: _inputDecoration(),
                  ),
                  const SizedBox(height: 8),
                  // 이메일 안내 문구
                  const Row(
                    children: [
                      Icon(Icons.info, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '이메일은 변경할 수 없습니다.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  if (_profile?.loginId.isNotEmpty == true) ...[
                    _buildLabel('아이디'),
                    TextFormField(
                      initialValue: _profile!.loginId,
                      readOnly: true,
                      style: const TextStyle(color: Colors.black54),
                      decoration: _inputDecoration(),
                    ),
                    const SizedBox(height: 25),
                  ],

                  // 4. 비밀번호 영역 (우측에 '변경' 버튼)
                  _buildLabel('비밀번호'),
                  TextField(
                    controller: _passwordController,
                    readOnly: true,
                    obscureText: true,
                    decoration: _inputDecoration().copyWith(
                      suffixIcon: TextButton(
                        onPressed: _showPasswordChangeDialog,
                        child: const Text(
                          '변경',
                          style: TextStyle(
                            color: Color(0xFF2A8DE5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // 5. 하단 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A8DE5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isSaving ? '저장 중...' : '변경사항 저장하기',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // --- UI 재사용 헬퍼 함수들 ---

  // 라벨 (닉네임, 이메일 계정 등) 텍스트 위젯
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // 텍스트 필드 공통 디자인 (회색 테두리 둥근 박스)
  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A8DE5), width: 1.5),
      ),
    );
  }
}
