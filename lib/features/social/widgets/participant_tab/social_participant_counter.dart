import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SocialParticipantCounter extends StatefulWidget {
  const SocialParticipantCounter({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.onValidityChanged,
  });

  final int initialValue;
  final ValueChanged<int> onChanged;
  final ValueChanged<bool>? onValidityChanged;

  @override
  State<SocialParticipantCounter> createState() =>
      _SocialParticipantCounterState();
}

class _SocialParticipantCounterState extends State<SocialParticipantCounter> {
  late int _value;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _controller = TextEditingController(text: '$_value');
  }

  @override
  void didUpdateWidget(covariant SocialParticipantCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
      _controller.text = '$_value';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _change(int delta) {
    final next = (_value + delta).clamp(2, 64);
    if (next == _value) return;
    setState(() {
      _value = next;
      _controller.value = TextEditingValue(
        text: '$_value',
        selection: TextSelection.collapsed(offset: '$_value'.length),
      );
    });
    widget.onChanged(next);
    widget.onValidityChanged?.call(true);
  }

  void _onInputChanged(String value) {
    final parsed = int.tryParse(value);
    final valid = parsed != null && parsed >= 2 && parsed <= 64;
    widget.onValidityChanged?.call(valid);
    if (!valid || parsed == _value) return;
    setState(() => _value = parsed);
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.person_outline_rounded,
              color: AppTheme.primary,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.socialParticipantCountLabel,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const ValueKey('social-max-slots-input'),
                controller: _controller,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: l10n.socialMaxSlotsLabel,
                  isDense: true,
                  filled: true,
                  fillColor: colors.bgCard,
                  errorMaxLines: 2,
                ),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  return parsed != null && parsed >= 2 && parsed <= 64
                      ? null
                      : l10n.socialMaxSlotsInvalid;
                },
                onChanged: _onInputChanged,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: l10n.socialParticipantCountDecrease,
              onPressed: _value <= 2 ? null : () => _change(-1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            IconButton(
              tooltip: l10n.socialParticipantCountIncrease,
              onPressed: _value >= 64 ? null : () => _change(1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}
