import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _submitting = false;
  bool _sent = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) return;
    setState(() => _submitting = true);
    try {
      await ref.read(dioClientProvider).dio.post('/auth/forgot-password', data: {'email': email});
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally { if (mounted) setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(title: const Text('Quên mật khẩu'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent ? _buildSent() : _buildForm(),
      ),
    );
  }

  Widget _buildSent() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: context.colors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: const Icon(Icons.mark_email_read_rounded, size: 40, color: Colors.green)),
    const SizedBox(height: 20),
    const Text('Email đã được gửi!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    Text('Vui lòng kiểm tra hộp thư ${_emailCtrl.text.trim()} để đặt lại mật khẩu.', style: TextStyle(color: context.colors.textSecondary), textAlign: TextAlign.center),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: () => context.go('/login'), child: const Text('Quay lại đăng nhập')),
  ]));

  Widget _buildForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 40),
    Container(width: 64, height: 64, decoration: BoxDecoration(color: context.colors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.lock_reset_rounded, size: 32, color: Colors.blue)),
    const SizedBox(height: 20),
    const Text('Quên mật khẩu?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    Text('Nhập email của bạn, chúng tôi sẽ gửi liên kết đặt lại mật khẩu.', style: TextStyle(color: context.colors.textSecondary, fontSize: 14)),
    const SizedBox(height: 24),
    TextField(
      controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
      style: TextStyle(color: context.colors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Email', hintText: 'your@email.com',
        prefixIcon: Icon(Icons.email_outlined, color: context.colors.textMuted),
        filled: true, fillColor: context.colors.bgDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    const SizedBox(height: 24),
    SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
      onPressed: _submitting ? null : _submit,
      icon: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
      label: Text(_submitting ? 'Đang gửi...' : 'Gửi yêu cầu'),
      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    )),
  ]);
}
