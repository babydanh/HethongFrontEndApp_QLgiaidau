import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _pwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _submitting = false;
  bool _success = false;

  @override
  void dispose() { _pwCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_pwCtrl.text.length < 6) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu tối thiểu 6 ký tự'))); return; }
    if (_pwCtrl.text != _confirmCtrl.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu không khớp'))); return; }
    setState(() => _submitting = true);
    try {
      await ref.read(dioClientProvider).dio.post('/auth/reset-password', data: {'token': widget.token, 'password': _pwCtrl.text});
      setState(() => _success = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally { if (mounted) setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(title: const Text('Đặt lại mật khẩu'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _success ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: context.colors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: const Icon(Icons.check_circle_rounded, size: 40, color: Colors.green)),
    const SizedBox(height: 20),
    const Text('Đặt lại mật khẩu thành công!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: () => context.go('/login'), child: const Text('Đăng nhập')),
  ]));

  Widget _buildForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 40),
    Container(width: 64, height: 64, decoration: BoxDecoration(color: context.colors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.lock_reset_rounded, size: 32, color: Colors.blue)),
    const SizedBox(height: 20),
    const Text('Tạo mật khẩu mới', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
    const SizedBox(height: 24),
    TextField(controller: _pwCtrl, obscureText: true, style: TextStyle(color: context.colors.textPrimary),
      decoration: InputDecoration(labelText: 'Mật khẩu mới', prefixIcon: Icon(Icons.lock_outline_rounded, color: context.colors.textMuted),
        filled: true, fillColor: context.colors.bgDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
    const SizedBox(height: 16),
    TextField(controller: _confirmCtrl, obscureText: true, style: TextStyle(color: context.colors.textPrimary),
      decoration: InputDecoration(labelText: 'Xác nhận mật khẩu', prefixIcon: Icon(Icons.lock_outline_rounded, color: context.colors.textMuted),
        filled: true, fillColor: context.colors.bgDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
    const SizedBox(height: 24),
    SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
      onPressed: _submitting ? null : _submit,
      icon: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
      label: Text(_submitting ? 'Đang xử lý...' : 'Đặt lại mật khẩu'),
      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    )),
  ]);
}
