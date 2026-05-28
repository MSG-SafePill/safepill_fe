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
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/safepill_start.png',
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                left: width * 0.085,
                right: width * 0.085,
                top: height * 0.78,
                height: height * 0.07,
                child: GestureDetector(
                  onTap: _goToLogin,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                left: width * 0.085,
                right: width * 0.085,
                top: height * 0.875,
                height: height * 0.07,
                child: GestureDetector(
                  onTap: _goToSignup,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
