import 'package:flutter/material.dart';
import 'screens/auth/splash.dart'; // 👈 스플래시 화면을 꼭 불러와 주세요!

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafePill',
      theme: ThemeData(primarySwatch: Colors.blue),
      
      // 👇 앱이 켜지면 제일 처음으로 보여줄 화면을 스플래시로 고정!!
      home: const SplashScreen(), 
    );
  }
}