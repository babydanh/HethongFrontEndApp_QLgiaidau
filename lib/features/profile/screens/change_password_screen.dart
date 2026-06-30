import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _hasMinLength(String pwd) => pwd.length >= 6;
  bool _hasUppercase(String pwd) => pwd.contains(RegExp(r'[A-Z]'));
  bool _hasNumber(String pwd) => pwd.contains(RegExp(r'[0-9]'));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // UI only — simulate API call delay
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đổi mật khẩu thành công'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
    context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final newPassword = _newPasswordController.text;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.go('/profile'),
        ),
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Form card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2979FF).withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current password
                    const _FieldLabel(text: 'Mật khẩu hiện tại'),
                    const SizedBox(height: 6),
                    AppTextFormField(
                      controller: _currentPasswordController,
                      hint: 'Nhập mật khẩu hiện tại',
                      obscureText: _obscureCurrent,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: _obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      onSuffixIconPressed: () {
                        setState(() => _obscureCurrent = !_obscureCurrent);
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Vui lòng nhập mật khẩu hiện tại';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // New password
                    const _FieldLabel(text: 'Mật khẩu mới'),
                    const SizedBox(height: 6),
                    AppTextFormField(
                      controller: _newPasswordController,
                      hint: 'Nhập mật khẩu mới',
                      obscureText: _obscureNew,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: _obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      onSuffixIconPressed: () {
                        setState(() => _obscureNew = !_obscureNew);
                      },
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Vui lòng nhập mật khẩu mới';
                        }
                        if (val.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password requirements
                    _buildRequirementRow(
                      'Có ít nhất 6 ký tự',
                      _hasMinLength(newPassword),
                    ),
                    const SizedBox(height: 6),
                    _buildRequirementRow(
                      'Có ít nhất 1 chữ hoa',
                      _hasUppercase(newPassword),
                    ),
                    const SizedBox(height: 6),
                    _buildRequirementRow(
                      'Có ít nhất 1 chữ số',
                      _hasNumber(newPassword),
                    ),
                    const SizedBox(height: 20),

                    // Confirm password
                    const _FieldLabel(text: 'Xác nhận mật khẩu mới'),
                    const SizedBox(height: 6),
                    AppTextFormField(
                      controller: _confirmPasswordController,
                      hint: 'Nhập lại mật khẩu mới',
                      obscureText: _obscureConfirm,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      onSuffixIconPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Vui lòng xác nhận mật khẩu mới';
                        }
                        if (val != _newPasswordController.text) {
                          return 'Mật khẩu xác nhận không khớp';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: context.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Đổi mật khẩu',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Help text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: const Color(0xFF2979FF).withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mật khẩu phải có ít nhất 6 ký tự, bao gồm chữ hoa và chữ số để bảo mật tài khoản của bạn.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2979FF).withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: isMet ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isMet ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }
}
