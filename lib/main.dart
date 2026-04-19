import 'package:flutter/material.dart';
import 'screens/auth/splash.dart'; // 👈 스플래시 화면 잘 불러왔습니다!

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafePill',
      debugShowCheckedModeBanner: false, // 👈 거슬리는 디버그 띠 완벽 제거!
      
      // 👇 여기가 HomeScreen이 아니라 SplashScreen이어야 합니다!
      home: const SplashScreen(), 
    );
  }
}