import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _submitting = false;
  bool _success = false;
  bool _obscurePw = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới';
    }
    if (val.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  String? _validateConfirm(String? val) {
    if (val == null || val.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (val != _pwCtrl.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  String _friendlyError(Object error) {
    final msg = error.toString().replaceFirst('Exception: ', '');
    final lower = msg.toLowerCase();
    if (lower.contains('socket') ||
        lower.contains('connection') ||
        lower.contains('timeout')) {
      return 'Không thể kết nối máy chủ. Vui lòng thử lại.';
    }
    if (lower.contains('token') &&
        (lower.contains('invalid') || lower.contains('expired'))) {
      return 'Liên kết đặt lại mật khẩu không hợp lệ hoặc đã hết hạn. Vui lòng yêu cầu gửi lại.';
    }
    if (lower.contains('400') ||
        lower.contains('invalid') ||
        lower.contains('expired')) {
      return 'Liên kết đặt lại mật khẩu không hợp lệ hoặc đã hết hạn. Vui lòng yêu cầu gửi lại.';
    }
    return 'Không thể đặt lại mật khẩu. Vui lòng thử lại.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(dioClientProvider)
          .dio
          .post(
            '/auth/reset-password',
            data: {'token': widget.token, 'password': _pwCtrl.text},
          );
      if (!mounted) return;
      setState(() => _success = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e)),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token.trim().isEmpty) {
      return Scaffold(
        backgroundColor: context.colors.bgDark,
        appBar: AppBar(
          title: const Text('Đặt lại mật khẩu'),
          centerTitle: true,
          backgroundColor: context.colors.bgDark,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.link_off_rounded,
                  size: 64,
                  color: context.colors.warning,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Liên kết không hợp lệ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Liên kết đặt lại mật khẩu không hợp lệ hoặc đã bị thiếu thông tin.',
                  style: TextStyle(color: context.colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: const Text('Yêu cầu gửi lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        title: const Text('Đặt lại mật khẩu'),
        centerTitle: true,
        backgroundColor: context.colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: context.colors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _success ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: context.colors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            size: 40,
            color: context.colors.success,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Đặt lại mật khẩu thành công!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Mật khẩu của bạn đã được cập nhật.',
          style: TextStyle(color: context.colors.textSecondary),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Đăng nhập'),
        ),
      ],
    ),
  );

  Widget _buildForm() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: context.colors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            size: 32,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Tạo mật khẩu mới',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Mật khẩu tối thiểu 6 ký tự.',
          style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _pwCtrl,
          obscureText: _obscurePw,
          style: TextStyle(color: context.colors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới',
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: context.colors.textMuted,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePw
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: context.colors.textMuted,
              ),
              onPressed: () => setState(() => _obscurePw = !_obscurePw),
            ),
            filled: true,
            fillColor: context.colors.bgDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: _validatePassword,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          style: TextStyle(color: context.colors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Xác nhận mật khẩu',
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: context.colors.textMuted,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: context.colors.textMuted,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            filled: true,
            fillColor: context.colors.bgDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: _validateConfirm,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_submitting ? 'Đang xử lý...' : 'Đặt lại mật khẩu'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
