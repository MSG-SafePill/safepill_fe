import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/local_profile_api.dart';
import '../main/home.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  final LocalProfileApi _localProfileApi = LocalProfileApi();

  bool _obscurePassword = true;
  bool _saveId = true;
  bool _isLoading = false;

  static const Color primaryBlue = Color(0xFF1F6FEA);
  static const Color deepBlue = Color(0xFF0030C8);
  static const Color navyText = Color(0xFF0B1F4D);
  static const Color grayText = Color(0xFF7D8899);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color fieldBorder = Color(0xFFDDE6F2);

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final loginId = _loginIdController.text.trim();
    final password = _passwordController.text.trim();

    if (loginId.isEmpty || password.isEmpty) {
      _showMessage('아이디와 비밀번호를 입력해주세요.');
      return;
    }

    try {
      setState(() => _isLoading = true);

      final response = await _apiClient.post(
        '/api/users/login',
        body: {'loginId': loginId, 'password': password},
      );

      final token = response.body;
      await _apiClient.saveToken(token);
      if (_saveId) {
        await _localProfileApi.saveLoginId(loginId);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on ApiException catch (e) {
      if (mounted) {
        _showMessage('로그인 실패: ${e.message}');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('서버와 연결할 수 없습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(flex: 30, child: _buildTopVisual()),
                  const SizedBox(height: 8),
                  _buildLoginCard(),
                  const SizedBox(height: 12),
                  _buildSocialLogin(),
                  const SizedBox(height: 10),
                  _buildSecurityText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopVisual() {
    return SizedBox(
      height: 238,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.62, -0.2),
                  radius: 0.95,
                  colors: [
                    const Color(0xFFEAF6FF),
                    const Color(0xFFF6FAFF).withValues(alpha: 0.96),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: -12,
            child: Opacity(
              opacity: 0.95,
              child: SizedBox(
                width: 220,
                height: 166,
                child: Stack(
                  children: [
                    Positioned(
                      top: 72,
                      left: 34,
                      child: _capsule(
                        width: 100,
                        height: 40,
                        angle: -0.55,
                        leftColor: primaryBlue,
                        rightColor: Colors.white,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 54,
                      child: _tablet(
                        text: '',
                        color1: Colors.white,
                        color2: const Color(0xFFE7EEF8),
                        width: 62,
                        height: 42,
                        angle: 0.35,
                      ),
                    ),
                    Positioned(
                      top: 46,
                      right: 0,
                      child: _tablet(
                        text: 'IM-6',
                        color1: const Color(0xFFBEE2FF),
                        color2: const Color(0xFF6EAFF5),
                        width: 68,
                        height: 34,
                        angle: -0.28,
                        fontSize: 12,
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 42,
                      child: _tablet(
                        text: 'X',
                        color1: const Color(0xFFDFF3DC),
                        color2: const Color(0xFF9FD6A2),
                        width: 58,
                        height: 38,
                        angle: -0.2,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 12,
                      child: _tablet(
                        text: '5',
                        color1: const Color(0xFFFFE5D9),
                        color2: const Color(0xFFF1A587),
                        width: 58,
                        height: 36,
                        angle: 0.28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 28,
            right: 0,
            child: Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 230,
                height: 124,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: const Color(0xFFBDEFFF).withValues(alpha: 0.62),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shieldIcon(),
                const SizedBox(height: 14),
                const Text(
                  'SafePill',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '안전한 복용을 위한 로그인',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6E7A8D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E6FD8).withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _inputField(
            controller: _loginIdController,
            hintText: '아이디 또는 이메일',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 10),
          _inputField(
            controller: _passwordController,
            hintText: '비밀번호',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffix: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF9AA7B8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _saveId = !_saveId),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _saveId ? primaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _saveId ? primaryBlue : const Color(0xFFD8E0EA),
                    ),
                  ),
                  child: _saveId
                      ? const Icon(Icons.check, size: 17, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '아이디 저장',
                style: TextStyle(
                  fontSize: 15,
                  color: grayText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _showMessage('비밀번호 찾기 기능은 준비 중입니다.');
                },
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '비밀번호 찾기',
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: deepBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _goToSignup,
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: primaryBlue, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '회원가입',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _textLink('아이디 찾기'),
              const SizedBox(width: 18),
              const Text('|', style: TextStyle(color: Color(0xFFD5DCE7))),
              const SizedBox(width: 18),
              _textLink('고객센터'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _line()),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '간편 로그인',
                style: TextStyle(
                  color: grayText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: _line()),
          ],
        ),
        const SizedBox(height: 10),
        _socialButton(
          label: '카카오로 로그인',
          icon: _kakaoMark(),
          backgroundColor: Colors.white,
          onTap: () {
            _showMessage('카카오 로그인은 준비 중입니다.');
          },
        ),
        const SizedBox(height: 8),
        _socialButton(
          label: 'Google로 로그인',
          icon: _googleMark(),
          backgroundColor: Colors.white,
          onTap: () {
            _showMessage('Google 로그인은 준비 중입니다.');
          },
        ),
      ],
    );
  }

  Widget _buildSecurityText() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user_rounded, color: Color(0xFF76B8FF), size: 22),
        SizedBox(width: 8),
        Text(
          'SafePill은 사용자의 소중한 정보를\n안전하게 보호합니다.',
          textAlign: TextAlign.center,
          style: TextStyle(color: grayText, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: fieldBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 16,
          color: navyText,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF98A4B5),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F6FC),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: grayText, size: 24),
          ),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String label,
    required Widget icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: const BorderSide(color: Color(0xFFE0E7F1), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: icon,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1E2430),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shieldIcon() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5CE1E6), primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
    );
  }

  Widget _line() {
    return Container(height: 1, color: fieldBorder);
  }

  Widget _textLink(String label) {
    return GestureDetector(
      onTap: () => _showMessage('$label 기능은 준비 중입니다.'),
      child: Text(
        label,
        style: const TextStyle(
          color: grayText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _capsule({
    required double width,
    required double height,
    required double angle,
    required Color leftColor,
    required Color rightColor,
  }) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height),
          gradient: LinearGradient(
            colors: [leftColor, leftColor, rightColor, rightColor],
            stops: const [0.0, 0.5, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tablet({
    required String text,
    required Color color1,
    required Color color2,
    required double width,
    required double height,
    required double angle,
    double fontSize = 20,
  }) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.blueGrey.withValues(alpha: 0.75),
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _kakaoMark() {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFEE500),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.chat_bubble, color: Color(0xFF3A1D1D), size: 17),
    );
  }

  Widget _googleMark() {
    return const SizedBox(
      width: 26,
      height: 26,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
