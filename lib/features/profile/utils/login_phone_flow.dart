import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/contact_identity.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sets or changes the phone used to log in (`PATCH /users/profile/login-phone`).
/// The phone is sent as typed; the server normalizes it and keeps it
/// unverified (no SMS/OTP yet).
Future<void> startLoginPhoneFlow(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const _LoginPhoneDialog(),
);

/// Owns its text controllers so they outlive the dialog's exit animation.
class _LoginPhoneDialog extends ConsumerStatefulWidget {
  const _LoginPhoneDialog();

  @override
  ConsumerState<_LoginPhoneDialog> createState() => _LoginPhoneDialogState();
}

class _LoginPhoneDialogState extends ConsumerState<_LoginPhoneDialog> {
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _phoneError;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneCtrl.text.trim();
    if (classifyIdentifier(phone) != ContactKind.phone) {
      setState(() => _phoneError = l10n.settingsPhoneInvalid);
      return;
    }
    final password = _passwordCtrl.text;
    setState(() {
      _phoneError = null;
      _isSubmitting = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(userRepositoryProvider)
          .setLoginPhone(
            phone: phone,
            currentPassword: password.isEmpty ? null : password,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(userProfileProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsLoginPhoneSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(SnackBar(content: Text(_errorText(e, l10n))));
    }
  }

  /// The repository rethrows Backend errors as `Exception(<localized text>)`;
  /// show that text instead of the generic fallback.
  String _errorText(Object e, AppLocalizations l10n) {
    if (e is DioException) return ErrorParser.parse(e, '', l10n);
    final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    return msg.isEmpty ? l10n.errorParserFallback : msg;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: context.colors.bgCard,
      title: Text(l10n.settingsLoginPhone),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsLoginPhoneSubtitle,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('login-phone-input'),
              controller: _phoneCtrl,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.infoPhone,
                errorText: _phoneError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('login-phone-password'),
              controller: _passwordCtrl,
              enabled: !_isSubmitting,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.changePassword_currentLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.settingsLoginPhoneSave),
        ),
      ],
    );
  }
}
