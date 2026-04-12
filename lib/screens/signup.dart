import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 1. 6가지 정보를 담을 빨대(Controller) 준비!
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  
  // 성별은 오타 방지를 위해 선택형(Dropdown) 변수로 관리합니다.
  String _selectedGender = 'MALE'; 

  // 2. 백엔드로 회원가입 정보를 쏘는 함수!
  Future<void> _signup() async {
    // 빈칸 검사
    if (_idController.text.isEmpty || _passwordController.text.isEmpty || 
        _nameController.text.isEmpty || _emailController.text.isEmpty || 
        _birthController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 정보를 입력해주세요!')),
      );
      return;
    }

    final url = Uri.parse('http://10.0.2.2:8080/api/users/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'loginId': _idController.text.trim(),
          'password': _passwordController.text.trim(),
          'username': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'gender': _selectedGender, // MALE 또는 FEMALE
          'birthDate': _birthController.text.trim(), // 예: 1990-01-01
        }),
      );

      if (response.statusCode == 200) {
        print("🎉 회원가입 성공!");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('회원가입 성공! 로그인해주세요.')),
          );
          // 3. 가입 성공 시, 이전 화면(로그인 화면)으로 부드럽게 돌아가기!
          Navigator.pop(context); 
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('가입 실패: ${response.body}')),
          );
        }
      }
    } catch (e) {
      print("🔥 에러 발생: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버와 연결할 수 없습니다.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _birthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Register', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              // 입력 폼들 배치
              _buildTextField('아이디 (loginId)', false, _idController),
              const SizedBox(height: 15),
              _buildTextField('비밀번호', true, _passwordController),
              const SizedBox(height: 15),
              _buildTextField('이름', false, _nameController),
              const SizedBox(height: 15),
              _buildTextField('이메일', false, _emailController),
              const SizedBox(height: 15),
              _buildTextField('생년월일 (YYYY-MM-DD)', false, _birthController),
              const SizedBox(height: 15),

              // 성별 선택 드롭다운
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'MALE', child: Text('남성')),
                      DropdownMenuItem(value: 'FEMALE', child: Text('여성')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        if (value != null) _selectedGender = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 가입하기 버튼
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A8DE5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text('Sign Up', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 텍스트 필드 생성 위젯
  Widget _buildTextField(String hint, bool isPassword, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}