import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../demo/demo_state.dart';
import '../demo/showcase_demo.dart';
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
  int _showcaseTapCount = 0;

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

  void _openShowcaseDemo() {
    _showcaseTapCount += 1;
    if (_showcaseTapCount < 5) {
      return;
    }
    _showcaseTapCount = 0;
    DemoState.activate();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShowcaseDemoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF),
      body: ClipRect(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: designWidth,
              height: designHeight,
              child: _LandingContent(
                onLogin: _goToLogin,
                onSignup: _goToSignup,
                onShowcaseDemo: _openShowcaseDemo,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LandingContent extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  final VoidCallback onShowcaseDemo;

  const _LandingContent({
    required this.onLogin,
    required this.onSignup,
    required this.onShowcaseDemo,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/safepill_start.png', fit: BoxFit.cover),
        ),

        Positioned(
          left: 20,
          top: 16,
          width: 116,
          height: 70,
          child: GestureDetector(
            onTap: onShowcaseDemo,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),

        // 로그인 버튼 투명 클릭 영역
        Positioned(
          left: 30,
          right: 30,
          bottom: 114,
          height: 62,
          child: GestureDetector(
            onTap: onLogin,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),

        // 회원가입 버튼 투명 클릭 영역
        Positioned(
          left: 30,
          right: 30,
          bottom: 45,
          height: 62,
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
