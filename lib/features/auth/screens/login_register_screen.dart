import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_quanly_giaidau/core/utils/token_generator.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class LoginRegisterScreen extends ConsumerStatefulWidget {
  final String? redirectPath;

  const LoginRegisterScreen({super.key, this.redirectPath});

  @override
  ConsumerState<LoginRegisterScreen> createState() =>
      _LoginRegisterScreenState();
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

  Widget _buildAppleSignInButton() {
    return SignInWithAppleButton(
      onPressed: _isLoading ? null : _submitApple,
      style: SignInWithAppleButtonStyle.black,
      borderRadius: BorderRadius.circular(12.0),
      text: AppLocalizations.of(context)!.loginRegister_appleSignInButton,
    );
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
      success = await ref
          .read(authProvider.notifier)
          .registerWithEmailPassword(email, password, fullName);
    } else {
      success = await ref
          .read(authProvider.notifier)
          .loginWithEmailPassword(email, password);
    }

    if (!mounted) return;

    if (success) {
      ref.invalidate(userProfileProvider);
      ref.invalidate(userRankingsProvider);
      context.go("/login-loading", extra: widget.redirectPath);
    } else {
      final auth = ref.read(authProvider);
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoading = false;
        _errorMessage =
            auth.errorMessage ??
            (_isRegisterMode
                ? l10n.loginRegister_registerFailed
                : l10n.loginRegister_loginFailed);
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
        clientId:
            defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS
            ? dotenv.env['GOOGLE_IOS_CLIENT_ID']
            : null,
        serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
        scopes: ['email'],
      );
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      if (!mounted) return;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception(
          AppLocalizations.of(context)!.loginRegister_googleTokenMissing,
        );
      }
      bool success = await ref
          .read(authProvider.notifier)
          .loginWithGoogle(idToken);
      if (!mounted) return;
      if (success) {
        ref.invalidate(userProfileProvider);
        ref.invalidate(userRankingsProvider);
        context.go("/login-loading", extra: widget.redirectPath);
      } else {
        final auth = ref.read(authProvider);
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isLoading = false;
          _errorMessage =
              auth.errorMessage ?? l10n.loginRegister_googleLoginFailed;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorParser.parse(
          e,
          l10n.loginRegister_googleLoginError,
        );
      });
    }
  }

  Future<void> _submitApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Apple expects the SHA-256 nonce in the authorization request. Keep
      // the raw nonce for the backend so it can verify the returned token.
      final rawNonce = TokenGenerator.generateAppleNonce();
      final appleNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await SignInWithApple.getAppleIDCredential(
        nonce: appleNonce,
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      if (!mounted) return;
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception(
          AppLocalizations.of(context)!.loginRegister_appleTokenMissing,
        );
      }
      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((s) => s != null && s.trim().isNotEmpty).join(' ');
      bool success = await ref
          .read(authProvider.notifier)
          .loginWithApple(
            idToken,
            nonce: rawNonce,
            fullName: fullName.isNotEmpty ? fullName : null,
          );
      if (!mounted) return;
      if (success) {
        ref.invalidate(userProfileProvider);
        ref.invalidate(userRankingsProvider);
        context.go("/login-loading", extra: widget.redirectPath);
      } else {
        final auth = ref.read(authProvider);
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isLoading = false;
          _errorMessage =
              auth.errorMessage ?? l10n.loginRegister_appleLoginFailed;
        });
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorParser.parse(
          e,
          l10n.loginRegister_appleLoginError,
        );
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorParser.parse(
          e,
          l10n.loginRegister_appleLoginError,
        );
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: primaryBgColor,
      body: Stack(
        children: [
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
                    isDark
                        ? Colors.transparent
                        : const Color(0xFF2979FF).withValues(alpha: 0.4),
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
                    SizedBox(
                      height: 48,
                      width: 240,
                      child: Hero(
                        tag: "Sporto_logo",
                        child: Image.asset(
                          "assets/images/sporto_v1_with_text.png",
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 10),

                    // Title
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _isRegisterMode ? l10n.registerTitle : l10n.loginTitle,
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
                            ? l10n.loginRegister_registerSubtitle
                            : l10n.loginRegister_loginSubtitle,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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
                                      label: l10n.fullNameLabel,
                                      hint: l10n.loginRegister_fullNameHint,
                                      icon: Icons.person_outline,
                                      validator: (val) {
                                        if (_isRegisterMode &&
                                            (val == null ||
                                                val.trim().isEmpty)) {
                                          return l10n
                                              .loginRegister_fullNameRequired;
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
                          label: l10n.emailLabel,
                          hint: l10n.loginRegister_emailHint,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n.loginRegister_emailRequired;
                            }
                            if (!RegExp(
                              r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
                            ).hasMatch(val.trim())) {
                              return l10n.loginRegister_emailInvalid;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextInput(
                          controller: _passwordController,
                          label: l10n.passwordLabel,
                          hint: l10n.loginRegister_passwordHint,
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
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return l10n.loginRegister_passwordRequired;
                            }
                            if (val.length < 6) {
                              return l10n.loginRegister_passwordMinLength;
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 4,
                                ),
                                child: Text(
                                  l10n.loginRegister_forgotPassword,
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
                                      _isRegisterMode
                                          ? l10n.registerButton
                                          : l10n.loginButton,
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
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                l10n.orContinueWith,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Social Buttons (Nằm dọc)
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _submitGoogle,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black12,
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  backgroundColor: Colors.transparent,
                                ),
                                icon: SvgPicture.asset(
                                  'assets/logos/google_g.svg',
                                  width: 20,
                                  height: 20,
                                ),
                                label: Text(
                                  l10n.loginRegister_googleSignInButton,
                                  style: TextStyle(
                                    color: textPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15.0,
                                  ),
                                ),
                              ),
                            ),
                            if (defaultTargetPlatform == TargetPlatform.iOS ||
                                defaultTargetPlatform ==
                                    TargetPlatform.macOS) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: _buildAppleSignInButton(),
                              ),
                            ],
                          ],
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
                          _isRegisterMode ? l10n.hasAccount : l10n.noAccount,
                          style: TextStyle(
                            color: textSecondaryColor,
                            fontSize: 14.0,
                          ),
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
                            _isRegisterMode
                                ? l10n.loginRegister_loginNowAction
                                : l10n.registerNow,
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
                          l10n.exploreWithoutLogin,
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
    final textPrimaryColor = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F172A);

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
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.black.withValues(alpha: 0.015),
            prefixIcon: Icon(
              icon,
              color: isDark ? Colors.white54 : Colors.black54,
              size: 18.0,
            ),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(0xFF2979FF),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: context.colors.error.withValues(alpha: 0.4),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: context.colors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
