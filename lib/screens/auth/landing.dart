import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login.dart';
import 'signup.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  static const double designWidth = 393;
  static const double designHeight = 852;
  static const double designRatio = designWidth / designHeight;

  @override
  void initState() {
    super.initState();

    // 이미지 안에 상태바가 포함되어 있으므로 실제 시스템 UI는 숨김
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // 다른 화면으로 이동할 때 시스템 UI 복구
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;

          double frameWidth = maxWidth;
          double frameHeight = frameWidth / designRatio;

          if (frameHeight > maxHeight) {
            frameHeight = maxHeight;
            frameWidth = frameHeight * designRatio;
          }

          // 웹에서 너무 커지지 않도록 모바일 화면 크기 제한
          final limitedWidth = math.min(frameWidth, 430.0);
          final limitedHeight = limitedWidth / designRatio;

          return Center(
            child: SizedBox(
              width: limitedWidth,
              height: limitedHeight,
              child: _LandingContent(
                onLogin: _goToLogin,
                onSignup: _goToSignup,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LandingContent extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignup;

  const _LandingContent({
    required this.onLogin,
    required this.onSignup,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/safepill_start.png',
            fit: BoxFit.cover,
          ),
        ),

        // 로그인 버튼 투명 클릭 영역
        Positioned(
          left: 32,
          right: 32,
          bottom: 136,
          height: 66,
          child: GestureDetector(
            onTap: onLogin,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),

        // 회원가입 버튼 투명 클릭 영역
        Positioned(
          left: 32,
          right: 32,
          bottom: 48,
          height: 66,
          child: GestureDetector(
            onTap: onSignup,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}