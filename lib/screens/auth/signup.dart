import 'package:flutter/material.dart';

import '../../services/api_client.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isIdChecked = false;
  String _gender = 'MALE';

  static const Color primaryBlue = Color(0xFF1F6FEA);
  static const Color deepBlue = Color(0xFF0030C8);
  static const Color navyText = Color(0xFF0B1F4D);
  static const Color grayText = Color(0xFF7D8899);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color borderColor = Color(0xFFDDE6F2);

  @override
  void initState() {
    super.initState();
    _loginIdController.addListener(() {
      if (_isIdChecked) {
        setState(() => _isIdChecked = false);
      }
    });
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _checkDuplicateId() async {
    final loginId = _loginIdController.text.trim();

    if (loginId.isEmpty) {
      _showMessage('아이디를 입력해주세요.');
      return;
    }

    try {
      await _apiClient.get('/api/users/check-id', query: {'loginId': loginId});
      if (!mounted) return;
      setState(() => _isIdChecked = true);
      _showMessage('사용 가능한 아이디입니다.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isIdChecked = false);
      _showMessage(e.message);
    } catch (_) {
      if (mounted) {
        _showMessage('서버 통신 에러가 발생했습니다.');
      }
    }
  }

  Future<void> _handleSignup() async {
    final loginId = _loginIdController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final birthDate = _birthDateController.text.trim();

    if (loginId.isEmpty ||
        password.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        birthDate.isEmpty) {
      _showMessage('모든 정보를 입력해주세요.');
      return;
    }

    if (!_isIdChecked) {
      _showMessage('아이디 중복확인을 해주세요.');
      return;
    }

    if (!_isValidBirthDate(birthDate)) {
      _showMessage('생년월일은 YYYY-MM-DD 형식으로 입력해주세요.');
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _apiClient.post(
        '/api/users/signup',
        body: {
          'loginId': loginId,
          'password': password,
          'username': username,
          'email': email,
          'gender': _gender,
          'birthDate': birthDate,
        },
      );

      if (!mounted) return;
      _showMessage('회원가입이 완료되었습니다. 로그인해주세요.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        _showMessage('가입 실패: ${e.message}');
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

  bool _isValidBirthDate(String value) {
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(value)) return false;

    try {
      DateTime.parse(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _goToLogin() {
    Navigator.pop(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(duration: const Duration(seconds: 2), content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBackButton(),
                  const SizedBox(height: 10),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSignupCard(),
                  const SizedBox(height: 16),
                  _buildSignupButton(),
                  const SizedBox(height: 16),
                  _buildLoginGuide(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: _goToLogin,
      child: const SizedBox(
        width: 44,
        height: 38,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 24,
            color: navyText,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 238,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            right: -12,
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
          Positioned(
            top: 22,
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
            bottom: 0,
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
                const SizedBox(height: 2),
                const Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: navyText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '새로운 계정으로 안전한 복용 관리를 시작하세요.',
                  style: TextStyle(
                    fontSize: 15,
                    color: grayText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupCard() {
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
            controller: _usernameController,
            hintText: '이름',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 10),
          _inputField(
            controller: _loginIdController,
            hintText: '아이디',
            icon: Icons.person_outline_rounded,
            suffix: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _checkDuplicateId,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _isIdChecked ? '확인 완료' : '중복 확인',
                  style: TextStyle(
                    color: _isIdChecked ? const Color(0xFF18B58F) : primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _inputField(
            controller: _emailController,
            hintText: '이메일',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
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
          const SizedBox(height: 10),
          _inputField(
            controller: _birthDateController,
            hintText: '생년월일 (YYYY-MM-DD)',
            icon: Icons.calendar_month_outlined,
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: 14),
          _buildGenderSelector(),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(
          child: _genderButton(
            label: '남성',
            value: 'MALE',
            icon: Icons.male_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _genderButton(
            label: '여성',
            value: 'FEMALE',
            icon: Icons.female_rounded,
          ),
        ),
      ],
    );
  }

  Widget _genderButton({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final selected = _gender == value;

    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        decoration: BoxDecoration(
          color: selected ? primaryBlue.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? primaryBlue : borderColor,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? primaryBlue : grayText, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? primaryBlue : grayText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
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
                '회원가입',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }

  Widget _buildLoginGuide() {
    return Center(
      child: GestureDetector(
        onTap: _goToLogin,
        child: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: '이미 계정이 있으신가요?  ',
                style: TextStyle(
                  color: grayText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: '로그인',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
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
            child: Icon(icon, color: grayText, size: 22),
          ),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
}
