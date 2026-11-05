import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  static bool _hasMinLength(String p) => p.length >= 6;
  static bool _hasUppercase(String p) => p.contains(RegExp(r'[A-Z]'));
  static bool _hasNumber(String p) => p.contains(RegExp(r'[0-9]'));

  bool get _valid =>
      _current.text.isNotEmpty &&
      _hasMinLength(_new.text) &&
      _hasUppercase(_new.text) &&
      _hasNumber(_new.text) &&
      _confirm.text == _new.text;

  void _onChanged(String _) => setState(() => _error = null);

  String _errorText(Object e, AppLocalizations l10n) {
    if (e is DioException) {
      return ErrorParser.parse(e, l10n.changePassword_errorGeneric, l10n);
    }
    final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    return msg.isEmpty ? l10n.changePassword_errorGeneric : msg;
  }

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(userRepositoryProvider)
          .changePassword(_current.text, _new.text);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.changePassword_success),
          backgroundColor: LavishColors.ok,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/profile');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _errorText(e, AppLocalizations.of(context)!));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pwd = _new.text;
    final met = [
      _hasMinLength(pwd),
      _hasUppercase(pwd),
      _hasNumber(pwd),
    ];
    final mismatch = _confirm.text.isNotEmpty && _confirm.text != pwd;

    return LavishScaffold(
      title: l10n.changePassword_title,
      onBack: () => context.go('/profile'),
      bottom: LavishStickyBar(
        label: l10n.changePassword_button,
        busy: _busy,
        error: _error,
        onPressed: _valid && !_busy ? _submit : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LavishTextField(
            label: l10n.changePassword_currentLabel,
            controller: _current,
            obscure: true,
            enabled: !_busy,
            onChanged: _onChanged,
          ),
          const SizedBox(height: 14),
          LavishTextField(
            label: l10n.changePassword_newLabel,
            controller: _new,
            obscure: true,
            enabled: !_busy,
            onChanged: _onChanged,
          ),
          const SizedBox(height: 10),
          _StrengthBar(score: met.where((m) => m).length),
          const SizedBox(height: 6),
          _Requirement(l10n.changePassword_minLength, met[0]),
          _Requirement(l10n.changePassword_uppercase, met[1]),
          _Requirement(l10n.changePassword_number, met[2]),
          const SizedBox(height: 14),
          LavishTextField(
            label: l10n.changePassword_confirmLabel,
            controller: _confirm,
            obscure: true,
            enabled: !_busy,
            errorText: mismatch ? l10n.changePassword_mismatch : null,
            onChanged: _onChanged,
          ),
        ],
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    final active = score <= 1
        ? LavishColors.bad
        : score == 2
        ? LavishColors.warn
        : LavishColors.ok;
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i < score ? active : c.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement(this.text, this.met);

  final String text;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    final color = met ? LavishColors.ok : c.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
