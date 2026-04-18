import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main/home.dart';
import 'landing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAutoLogin(); // 앱이 켜지자마자 바로 금고 확인 시작!
  }

  // 💡 몰래 금고를 확인하는 마법의 함수!
  Future<void> _checkAutoLogin() async {
    // 1. 금고 소환
    const storage = FlutterSecureStorage();

    // 2. 금고에서 'jwt_token'이라는 이름표가 붙은 출입증 꺼내보기
    String? token = await storage.read(key: 'jwt_token');

    // (선택 사항) 로고를 보여주기 위해 1.5초 정도 일부러 기다려줍니다.
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      if (token != null) {
        // 🎉 토큰 발견! 로그인 건너뛰고 바로 홈 화면으로 직행!
        print("🔓 금고에서 토큰 발견! 자동 로그인 성공!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // ❌ 토큰 없음! 처음 왔거나 로그아웃한 유저. 랜딩 화면으로!
        print("🔒 토큰 없음. 랜딩 화면으로 이동.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 랜딩 화면과 비슷한 예쁜 그라데이션 배경
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E88E5), Color(0xFF00BFA5)],
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고 아이콘
            Icon(Icons.medication, size: 100, color: Colors.white),
            SizedBox(height: 20),
            // 앱 이름
            Text(
              'SafePill',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}