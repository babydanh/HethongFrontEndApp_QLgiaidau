import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const courtCountMin = 1;
const courtCountMax = 50;

/// Court count as − [number] +: starts at [courtCountMin], the number can be
/// typed, and every path keeps the value inside [courtCountMin]..[courtCountMax].
/// [onChanged] fires with the clamped value; a half-typed empty field counts as
/// the minimum and is rewritten when the field loses focus.
class CourtCountStepper extends StatefulWidget {
  const CourtCountStepper({
    super.key,
    required this.onChanged,
    this.initialValue = courtCountMin,
    this.fieldKey,
  });

  final ValueChanged<int> onChanged;
  final int initialValue;

  /// Key of the number field (tests type into it).
  final Key? fieldKey;

  @override
  State<CourtCountStepper> createState() => _CourtCountStepperState();
}

class _CourtCountStepperState extends State<CourtCountStepper> {
  late int _value = _clamp(widget.initialValue);
  late final _controller = TextEditingController(text: '$_value');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _showValue();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  static int _clamp(int value) => value.clamp(courtCountMin, courtCountMax);

  void _showValue() {
    final text = '$_value';
    if (_controller.text != text) _controller.text = text;
  }

  void _set(int value, {required bool rewriteText}) {
    final next = _clamp(value);
    final changed = next != _value;
    setState(() => _value = next);
    if (rewriteText) _showValue();
    if (changed) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          key: const ValueKey('court-count-minus'),
          tooltip: l10n.courtCountDecrease,
          constraints: const BoxConstraints.tightFor(
            width: kMinTouchTarget,
            height: kMinTouchTarget,
          ),
          onPressed: _value > courtCountMin
              ? () => _set(_value - 1, rewriteText: true)
              : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        SizedBox(
          width: 64,
          child: TextField(
            key: widget.fieldKey,
            controller: _controller,
            focusNode: _focus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            decoration: const InputDecoration(isDense: true),
            // Typing below the minimum counts as the minimum and the text is
            // only rewritten on blur, so a half-typed number is not fought;
            // above the maximum it snaps back at once.
            onChanged: (text) {
              final typed = int.tryParse(text) ?? courtCountMin;
              _set(typed, rewriteText: typed > courtCountMax);
            },
          ),
        ),
        IconButton.outlined(
          key: const ValueKey('court-count-plus'),
          tooltip: l10n.courtCountIncrease,
          constraints: const BoxConstraints.tightFor(
            width: kMinTouchTarget,
            height: kMinTouchTarget,
          ),
          onPressed: _value < courtCountMax
              ? () => _set(_value + 1, rewriteText: true)
              : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}
