import 'package:flutter/material.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // 텍스트를 제어할 컨트롤러들 (미리 임시 데이터를 넣어둡니다)
  final TextEditingController _nicknameController = TextEditingController(text: '강민준');
  final TextEditingController _emailController = TextEditingController(text: 'coja0727@naver.com');
  final TextEditingController _passwordController = TextEditingController(text: '********');

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
        title: const Text('프로필 관리', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
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
                        width: 100, height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE3F2FD), // 연한 파란색 배경
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, size: 60, color: Color(0xFF2A8DE5)),
                      ),
                      // 우측 하단 작은 카메라 아이콘 (뱃지)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('사진 변경', style: TextStyle(color: Colors.black54, fontSize: 14)),
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
              style: const TextStyle(color: Colors.black54), // 수정 불가 느낌을 위해 색상 살짝 연하게
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 8),
            // 이메일 안내 문구
            const Row(
              children: [
                Icon(Icons.info, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text('이메일은 변경할 수 없습니다.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 25),

            // 4. 비밀번호 영역 (우측에 '변경' 버튼)
            _buildLabel('비밀번호'),
            TextField(
              controller: _passwordController,
              readOnly: true,
              obscureText: true,
              decoration: _inputDecoration().copyWith(
                suffixIcon: TextButton(
                  onPressed: () {
                    // TODO: 비밀번호 변경 팝업 또는 화면 이동
                  },
                  child: const Text('변경', style: TextStyle(color: Color(0xFF2A8DE5), fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 50),

            // 5. 하단 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 변경된 닉네임 서버에 저장
                  Navigator.pop(context); // 저장 후 이전 화면으로 돌아가기
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A8DE5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('변경사항 저장하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  // 텍스트 필드 공통 디자인 (회색 테두리 둥근 박스)
  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A8DE5), width: 1.5)),
    );
  }
}