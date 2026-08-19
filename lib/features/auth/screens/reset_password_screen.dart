import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    if (_pwCtrl.text.length < 6) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.resetPassword_minLengthError))); return; }
    if (_pwCtrl.text != _confirmCtrl.text) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.resetPassword_mismatchError))); return; }
    setState(() => _submitting = true);
    try {
      await ref.read(dioClientProvider).dio.post(
        '/auth/reset-password',
        data: {'token': widget.token, 'password': _pwCtrl.text},
      );
      if (!mounted) return;
      setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        final l10n2 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorParser.parse(e, l10n2.resetPassword_errorGeneric))));
      }
    } finally { if (mounted) setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(title: Text(l10n.resetPassword_title), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _success ? _buildSuccess(l10n) : _buildForm(l10n),
      ),
    );
  }

  Widget _buildSuccess(AppLocalizations l10n) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: context.colors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: const Icon(Icons.check_circle_rounded, size: 40, color: Colors.green)),
    const SizedBox(height: 20),
    Text(l10n.resetPassword_successTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: () => context.go('/login'), child: Text(l10n.loginButton)),
  ]));

  Widget _buildForm(AppLocalizations l10n) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 40),
    Container(width: 64, height: 64, decoration: BoxDecoration(color: context.colors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.lock_reset_rounded, size: 32, color: Colors.blue)),
    const SizedBox(height: 20),
    Text(l10n.resetPassword_createNewPassword, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
    const SizedBox(height: 24),
    TextField(controller: _pwCtrl, obscureText: true, style: TextStyle(color: context.colors.textPrimary),
      decoration: InputDecoration(labelText: l10n.resetPassword_newPasswordLabel, prefixIcon: Icon(Icons.lock_outline_rounded, color: context.colors.textMuted),
        filled: true, fillColor: context.colors.bgDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
    const SizedBox(height: 16),
    TextField(controller: _confirmCtrl, obscureText: true, style: TextStyle(color: context.colors.textPrimary),
      decoration: InputDecoration(labelText: l10n.resetPassword_confirmPasswordLabel, prefixIcon: Icon(Icons.lock_outline_rounded, color: context.colors.textMuted),
        filled: true, fillColor: context.colors.bgDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
    const SizedBox(height: 24),
    SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
      onPressed: _submitting ? null : _submit,
      icon: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
      label: Text(_submitting ? l10n.resetPassword_submitting : l10n.resetPassword_resetButton),
      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    )),
  ]);
}