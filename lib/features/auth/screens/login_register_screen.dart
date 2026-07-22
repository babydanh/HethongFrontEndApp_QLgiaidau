import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginRegisterScreen extends ConsumerStatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  ConsumerState<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends ConsumerState<LoginRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final fullName = _fullNameController.text.trim();

    bool success = false;
    if (_isRegisterMode) {
      success = await ref.read(authProvider.notifier).registerWithEmailPassword(
            email,
            password,
            fullName,
          );
    } else {
      success = await ref.read(authProvider.notifier).loginWithEmailPassword(
            email,
            password,
          );
    }

    if (!mounted) return;

    if (success) {
      ref.invalidate(userProfileProvider);
      ref.invalidate(userRankingsProvider);
      context.go("/login-loading");
    } else {
      final auth = ref.read(authProvider);
      setState(() {
        _isLoading = false;
        _errorMessage = auth.errorMessage ??
            (_isRegisterMode ? "Đăng ký thất bại" : "Đăng nhập thất bại");
      });
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
        scopes: ['email'],
      );
      // Xoá cache tài khoản cũ để luôn hiện account picker
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception("Không nhận được ID Token từ Google");
      }
      bool success = await ref.read(authProvider.notifier).loginWithGoogle(idToken);
      if (!mounted) return;
      if (success) {
        ref.invalidate(userProfileProvider);
        ref.invalidate(userRankingsProvider);
        context.go("/login-loading");
      } else {
        final auth = ref.read(authProvider);
        setState(() {
          _isLoading = false;
          _errorMessage = auth.errorMessage ?? "Đăng nhập Google thất bại";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Lỗi Google Sign-In: ${e.toString()}";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;
    final primaryBgColor = colors.bgDark;
    final textPrimaryColor = colors.textPrimary;
    final textSecondaryColor = colors.textSecondary;
    final ctaBgColor = AppTheme.primary;
    final ctaTextColor = Colors.white;

    return Scaffold(
      backgroundColor: primaryBgColor,
      body: Stack(
        children: [
          // Background Radial Glow
          Positioned(
            top: -screenSize.height * 0.2,
            right: -screenSize.width * 0.3,
            child: Container(
              width: screenSize.width * 1.0,
              height: screenSize.width * 1.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isDark ? Colors.transparent : const Color(0xFF2979FF).withValues(alpha: 0.4),
                    const Color(0xFF2979FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // VNSPORT Logo (Animated Hero)
                    SizedBox(
                      height: 70,
                      width: 260,
                      child: Hero(
                        tag: "vnsport_logo",
                        child: Transform.scale(
                          scale: 1.6,
                          alignment: Alignment.centerLeft,
                          child: SvgPicture.asset(
                            "assets/images/vndcsport.svg",
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 10),

                    // Title
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _isRegisterMode
                            ? "Đăng ký\nthành viên"
                            : "Đăng nhập\ntài khoản",
                        key: ValueKey<bool>(_isRegisterMode),
                        style: TextStyle(
                          fontSize: 34.0,
                          fontWeight: FontWeight.w900,
                          color: textPrimaryColor,
                          height: 1.2,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _isRegisterMode
                            ? "Gia nhập cộng đồng thể thao VNSPORT."
                            : "Truy cập để quản lý các giải đấu của bạn.",
                        key: ValueKey<bool>(_isRegisterMode),
                        style: TextStyle(
                          fontSize: 14.5,
                          color: textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error Alert Box
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.colors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.colors.error.withValues(alpha: 0.2),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: context.colors.error,
                              size: 18.0,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: context.colors.error,
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().shake(duration: 400.ms),

                    // Form Fields Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: _isRegisterMode
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTextInput(
                                      controller: _fullNameController,
                                      label: "Họ và tên",
                                      hint: "Nhập đầy đủ họ tên",
                                      icon: Icons.person_outline,
                                      validator: (val) {
                                        if (_isRegisterMode &&
                                            (val == null || val.trim().isEmpty)) {
                                          return "Vui lòng nhập họ và tên";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                        _buildTextInput(
                          controller: _emailController,
                          label: "Địa chỉ Email",
                          hint: "yourname@example.com",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Vui lòng nhập email";
                            }
                            if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
                                .hasMatch(val.trim())) {
                              return "Định dạng email không hợp lệ";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextInput(
                          controller: _passwordController,
                          label: "Mật khẩu",
                          hint: "Nhập mật khẩu của bạn",
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: isDark ? Colors.white70 : Colors.black54,
                              size: 18.0,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Vui lòng nhập mật khẩu";
                            }
                            if (val.length < 6) {
                              return "Mật khẩu phải từ 6 ký tự trở lên";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Forgot Password
                        if (!_isRegisterMode)
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => context.push('/forgot-password'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                child: Text(
                                  'Quên mật khẩu?',
                                  style: TextStyle(
                                    color: const Color(0xFF2979FF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Action Button
                        SizedBox(
                          height: 54,
                          child: TextButton(
                            onPressed: _isLoading ? null : _submit,
                            style: TextButton.styleFrom(
                              backgroundColor: ctaBgColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: ctaTextColor,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      _isRegisterMode ? "Đăng ký" : "Đăng nhập",
                                      key: ValueKey<bool>(_isRegisterMode),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        color: ctaTextColor,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "hoặc tiếp tục với",
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Google Button
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _submitGoogle,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                            icon: Image.network(
                              "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png",
                              height: 18.0,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.g_mobiledata,
                                size: 24,
                              ),
                            ),
                            label: Text(
                              "Google",
                              style: TextStyle(
                                color: textPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                      ],
                    ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                    const SizedBox(height: 24),

                    // Toggle Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isRegisterMode ? "Đã có tài khoản?" : "Chưa có tài khoản?",
                          style: TextStyle(color: textSecondaryColor, fontSize: 14.0),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isRegisterMode = !_isRegisterMode;
                              _errorMessage = null;
                            });
                          },
                          child: Text(
                            _isRegisterMode ? "Đăng nhập ngay" : "Đăng ký ngay",
                            style: const TextStyle(
                              color: Color(0xFF2979FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 350.ms),
                    const SizedBox(height: 16),

                    // Skip Button
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go("/home"),
                        child: Text(
                          "Khám phá không cần đăng nhập",
                          style: TextStyle(
                            color: textSecondaryColor.withValues(alpha: 0.7),
                            fontSize: 13.0,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    FormFieldValidator<String>? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: textPrimaryColor.withValues(alpha: 0.85),
              letterSpacing: 0.1,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: TextStyle(color: textPrimaryColor, fontSize: 15.0),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 14.5,
            ),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.015),
            prefixIcon: Icon(
              icon,
              color: isDark ? Colors.white54 : Colors.black54,
              size: 18.0,
            ),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFF2979FF), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: context.colors.error.withValues(alpha: 0.4),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: context.colors.error,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
