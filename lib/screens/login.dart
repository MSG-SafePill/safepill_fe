import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart'; 
import 'signup.dart';

// 1. 화면의 상태를 변경할 수 있도록 StatefulWidget으로 변경!
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 2. 입력창에서 글자를 빼오기 위한 빨대(Controller) 2개 준비!
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 3. 백엔드와 통신하는 진짜 로그인 함수!
  Future<void> _login() async {
    final loginId = _idController.text.trim();
    final password = _passwordController.text.trim();

    if (loginId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    final url = Uri.parse('http://10.0.2.2:8080/api/users/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'loginId': loginId,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final token = response.body; // 백엔드가 준 JWT 토큰!
        print("🎉 로그인 성공! 획득한 토큰: $token");

        // 4. 로그인 성공하면 홈 화면으로 넘어가기!
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        // 비밀번호 틀림 등 에러 발생 시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('로그인 실패: ${response.body}')),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text('Welcome!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 50),

              // 5. 입력 폼에 아까 만든 빨대(Controller)를 꽂아줍니다!
              _buildTextField('Email Address (loginId)', false, _idController),
              const SizedBox(height: 15),
              _buildTextField('Password', true, _passwordController),
              const SizedBox(height: 15),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?', style: TextStyle(color: Color(0xFF2A8DE5), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  // 6. 버튼을 누르면 아까 만든 _login() 함수가 실행됩니다!
                  onPressed: _login, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A8DE5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text('Login', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not a member? ', style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () {
                      // 👇 회원가입 화면으로 이동하는 코드!
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignupScreen()),
                      );
                    },
                    child: const Text('Register now', style: TextStyle(color: Color(0xFF2A8DE5), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              const Text('Or continue with', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton('G', const Color(0xFFEA4335)),
                  const SizedBox(width: 20),
                  _buildSocialButton('', Colors.black),
                  const SizedBox(width: 20),
                  _buildSocialButton('f', const Color(0xFF1877F2)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- [UI 재사용 컴포넌트들] ---
  
  // 💡 빨대(controller)를 받을 수 있게 수정했습니다!
  Widget _buildTextField(String hint, bool isPassword, TextEditingController controller) {
    return TextField(
      controller: controller, // 👈 여기에 빨대를 꽂습니다!
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        suffixIcon: isPassword ? const Icon(Icons.visibility_off, color: Colors.grey) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSocialButton(String label, Color color) {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
      ),
    );
  }
}