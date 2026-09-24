import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class SocialParticipantCounter extends StatefulWidget {
  const SocialParticipantCounter({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final int initialValue;
  final ValueChanged<int> onChanged;

  @override
  State<SocialParticipantCounter> createState() =>
      _SocialParticipantCounterState();
}

class _SocialParticipantCounterState extends State<SocialParticipantCounter> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant SocialParticipantCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
    }
  }

  void _change(int delta) {
    final next = (_value + delta).clamp(2, 64);
    if (next == _value) return;
    setState(() => _value = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        const Icon(
          Icons.person_outline_rounded,
          color: AppTheme.primary,
          size: 22,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Số người chơi',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),
        _button(context, Icons.remove, () => _change(-1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '$_value',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
        _button(context, Icons.add, () => _change(1)),
      ],
    );
  }

  Widget _button(BuildContext context, IconData icon, VoidCallback onTap) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, size: 18, color: colors.textPrimary),
      ),
    );
  }
}
