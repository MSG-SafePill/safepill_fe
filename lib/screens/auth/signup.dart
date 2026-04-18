import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  
  String _selectedGender = 'MALE'; 
  
  // 💡 [핵심 변수] 아이디 중복 확인을 통과했는지 기억하는 변수!
  bool _isIdChecked = false; 

  @override
  void initState() {
    super.initState();
    // 유저가 중복 확인 후 아이디를 또 수정하면, 다시 중복 확인을 하도록 상태를 초기화합니다!
    _idController.addListener(() {
      if (_isIdChecked) {
        setState(() {
          _isIdChecked = false;
        });
      }
    });
  }

  // 👇 1. 백엔드에 아이디 중복을 물어보는 함수
  Future<void> _checkDuplicateId() async {
    final loginId = _idController.text.trim();
    if (loginId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('아이디를 먼저 입력해주세요.')));
      return;
    }

    final String baseUrl = kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
    final url = Uri.parse('$baseUrl/api/users/check-id?loginId=$loginId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() { _isIdChecked = true; }); // 통과!
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 사용 가능한 아이디입니다!'), backgroundColor: Colors.green),
        );
      } else {
        setState(() { _isIdChecked = false; }); // 빠꾸!
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('서버 통신 에러가 발생했습니다.')));
    }
  }

  // 👇 2. 진짜 회원가입 쏘는 함수
  Future<void> _signup() async {
    // [보안] 중복 확인 안 했으면 아예 서버로 안 보냄!
    if (!_isIdChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디 중복 확인을 진행해주세요!'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_idController.text.isEmpty || _passwordController.text.isEmpty || 
        _nameController.text.isEmpty || _emailController.text.isEmpty || 
        _birthController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('모든 정보를 입력해주세요!')));
      return;
    }

    final String baseUrl = kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
    final url = Uri.parse('$baseUrl/api/users/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'loginId': _idController.text.trim(),
          'password': _passwordController.text.trim(),
          'username': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'gender': _selectedGender,
          'birthDate': _birthController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원가입 성공! 로그인해주세요.')));
          Navigator.pop(context); 
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('가입 실패: ${response.body}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('서버와 연결할 수 없습니다.')));
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

              // 💡 아이디 입력창 + 중복확인 버튼 나란히 배치!
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('아이디 (loginId)', false, _idController),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _checkDuplicateId,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isIdChecked ? Colors.green : Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(
                      _isIdChecked ? '확인 완료' : '중복 확인',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              _buildTextField('비밀번호', true, _passwordController),
              const SizedBox(height: 15),
              _buildTextField('이름', false, _nameController),
              const SizedBox(height: 15),
              _buildTextField('이메일', false, _emailController),
              const SizedBox(height: 15),
              _buildTextField('생년월일 (YYYY-MM-DD)', false, _birthController),
              const SizedBox(height: 15),

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
                      setState(() { if (value != null) _selectedGender = value; });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _signup, // 중복 확인 안 했으면 여기서 튕겨냅니다!
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