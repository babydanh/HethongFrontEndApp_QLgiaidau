import 'package:flutter/material.dart';

/// Building blocks of the Lavish design (`quan-ly-giai-ui-audit`, style.css).
///
/// Every size, weight, colour and spacing below is copied from that CSS
/// (13px body, `.hd` 11px/800 uppercase, `.li` row 11/14, `.chip`, `.pill`,
/// `.btn`, `.sw`), set explicitly so the Material text theme never makes the
/// text bigger than the design. Light values are the design's own; in dark
/// mode the same roles map to the app's dark palette.
enum LavishTone { accent, ok, bad, warn, neutral }

class LavishColors {
  const LavishColors._({
    required this.surface,
    required this.text,
    required this.muted,
    required this.line,
    required this.rowLine,
    required this.chipLine,
    required this.faint,
    required this.dark,
  });

  static const _light = LavishColors._(
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF101828),
    muted: Color(0xFF475467),
    line: Color(0xFFE4E7EC),
    rowLine: Color(0xFFF2F4F7),
    chipLine: Color(0xFFD0D5DD),
    faint: Color(0xFF98A2B3),
    dark: false,
  );

  static const _dark = LavishColors._(
    surface: Color(0xFF0F172A),
    text: Color(0xFFF1F5F9),
    muted: Color(0xFF94A3B8),
    line: Color(0xFF334155),
    rowLine: Color(0xFF1E293B),
    chipLine: Color(0xFF475569),
    faint: Color(0xFF64748B),
    dark: true,
  );

  static LavishColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  /// `--ac` / `--ok` / `--bad` / `--warn`.
  static const accent = Color(0xFF1D8BF5);
  static const ok = Color(0xFF12B76A);
  static const bad = Color(0xFFF04438);
  static const warn = Color(0xFFF79009);

  final Color surface;
  final Color text;
  final Color muted;
  final Color line;
  final Color rowLine;
  final Color chipLine;
  final Color faint;
  final bool dark;

  /// Icon colour of an `.ib` box and the base of a tone.
  Color solid(LavishTone tone) => switch (tone) {
    LavishTone.accent => accent,
    LavishTone.ok => ok,
    LavishTone.bad => bad,
    LavishTone.warn => warn,
    LavishTone.neutral => muted,
  };

  /// `--acbg` / `--okbg` / `--badbg` / `--warnbg` / `#f2f4f7`.
  Color soft(LavishTone tone) {
    if (dark) return solid(tone).withValues(alpha: 0.18);
    return switch (tone) {
      LavishTone.accent => const Color(0xFFE8F3FF),
      LavishTone.ok => const Color(0xFFDCFAE6),
      LavishTone.bad => const Color(0xFFFEE4E2),
      LavishTone.warn => const Color(0xFFFEF0C7),
      LavishTone.neutral => const Color(0xFFF2F4F7),
    };
  }

  /// Label colour of a `.pill`.
  Color pillText(LavishTone tone) {
    if (dark) return solid(tone);
    return switch (tone) {
      LavishTone.accent => const Color(0xFF175CD3),
      LavishTone.ok => const Color(0xFF067647),
      LavishTone.bad => const Color(0xFFB42318),
      LavishTone.warn => const Color(0xFFB54708),
      LavishTone.neutral => muted,
    };
  }
}

/// White (design `.phone`) background behind a Lavish screen.
class LavishSurface extends StatelessWidget {
  const LavishSurface({super.key, required this.child});

  final Widget child;

  // Material (not a ColoredBox) so ListTile / InkWell children can paint ink.
  @override
  Widget build(BuildContext context) =>
      Material(color: LavishColors.of(context).surface, child: child);
}

/// `.hd`: 11px / 800 / .06em uppercase group title.
class LavishGroupHeader extends StatelessWidget {
  const LavishGroupHeader(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.66,
                color: c.muted,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// `.li`: list row with 11px gaps, 11/14 padding and a 1px bottom line.
class LavishRow extends StatelessWidget {
  const LavishRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing = const <Widget>[],
    this.onTap,
    this.background,
    this.subtitleMaxLines = 2,
    this.titleColor,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> trailing;
  final VoidCallback? onTap;
  final Color? background;
  final int subtitleMaxLines;

  /// Overrides the title colour (e.g. red for a destructive action).
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    return Material(
      color: background ?? Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.rowLine)),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 11)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: titleColor ?? c.text,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: subtitleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                          color: c.muted,
                        ),
                      ),
                  ],
                ),
              ),
              for (final widget in trailing) ...[
                const SizedBox(width: 11),
                widget,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `.ib`: rounded 10px square holding an icon or a short glyph.
class LavishIconBox extends StatelessWidget {
  const LavishIconBox({
    super.key,
    required this.child,
    this.tone = LavishTone.accent,
    this.size = 34,
    this.onTap,
    this.tooltip,
  });

  final Widget child;
  final LavishTone tone;
  final double size;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    final fg = c.solid(tone);
    Widget box = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.soft(tone),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconTheme(
        data: IconThemeData(color: fg, size: 16),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: fg,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          child: child,
        ),
      ),
    );
    if (onTap != null) {
      box = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: box,
        ),
      );
    }
    final label = tooltip;
    return label == null ? box : Tooltip(message: label, child: box);
  }
}

/// `.pill`: 11px / 800 rounded label.
class LavishPill extends StatelessWidget {
  const LavishPill(this.label, {super.key, this.tone = LavishTone.accent});

  final String label;
  final LavishTone tone;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: c.soft(tone),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: c.pillText(tone),
        ),
      ),
    );
  }
}

/// `.chip`: 1px bordered pill button, 12px / 700, optional "v" chevron.
class LavishChipButton extends StatelessWidget {
  const LavishChipButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.chevron = false,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool chevron;

  /// `.chip.on`: filled with the accent colour, white label.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.white : c.text,
        backgroundColor: selected ? LavishColors.accent : c.surface,
        side: BorderSide(color: selected ? LavishColors.accent : c.chipLine),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.padded,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.fade),
          ),
          if (chevron) ...[
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
          ],
        ],
      ),
    );
  }
}

/// Pick-one tile of the Web division form (`choiceButtonClass`): 8px radius,
/// 1px border, 2px accent border and accent text once selected. With [icon] the
/// glyph sits in a 32px rounded box on the left (`choiceIconBoxClass`);
/// [trailing] takes the right edge (the format illustration trigger).
class LavishChoiceTile extends StatelessWidget {
  const LavishChoiceTile({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.icon,
    this.trailing,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final Widget? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    final accent = LavishColors.accent;
    final fg = selected ? accent : c.text;
    return Opacity(
      // A disabled selected tile keeps full contrast; the others fade.
      opacity: onPressed == null && !selected ? 0.6 : 1,
      child: Material(
        color: c.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? accent : c.chipLine,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: icon == null ? 40 : 48),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                icon == null ? 10 : 6,
                4,
                trailing == null ? 10 : 0,
                4,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected
                            ? accent.withValues(alpha: 0.10)
                            : c.faint,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? accent.withValues(alpha: 0.40)
                              : c.chipLine,
                        ),
                      ),
                      child: IconTheme(
                        data: IconThemeData(
                          size: 16,
                          color: selected ? accent : c.muted,
                        ),
                        child: icon!,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: icon == null
                          ? TextAlign.center
                          : TextAlign.start,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum LavishButtonKind { primary, outline, danger }

/// `.btn` (+ `.out`, `.bd`, `.dis`): 12px radius, 11px padding, 13px / 800.
/// Full width by default so it can sit in a padded block or an `Expanded`.
class LavishButton extends StatelessWidget {
  const LavishButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = LavishButtonKind.primary,
    this.icon,
    this.busy = false,
    this.buttonKey,
    this.dense = false,
  });

  /// Key of the inner Material button (the widget key stays on the wrapper).
  final Key? buttonKey;
  final String label;
  final VoidCallback? onPressed;
  final LavishButtonKind kind;
  final Widget? icon;
  final bool busy;

  /// Slimmer button (34px, 8px padding) that keeps a full 48px tap area.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.all(11);
    const textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w800);
    final minimum = Size(0, dense ? 34 : 42);
    final tapTarget = dense
        ? MaterialTapTargetSize.padded
        : MaterialTapTargetSize.shrinkWrap;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy) ...[
          const SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: 4),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    if (kind == LavishButtonKind.primary) {
      return FilledButton(
        key: buttonKey,
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: LavishColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.dark ? c.line : const Color(0xFFE4E7EC),
          disabledForegroundColor: c.faint,
          shape: shape,
          padding: padding,
          minimumSize: minimum,
          tapTargetSize: tapTarget,
          textStyle: textStyle,
        ),
        child: content,
      );
    }
    final color = kind == LavishButtonKind.danger
        ? LavishColors.bad
        : LavishColors.accent;
    return OutlinedButton(
      key: buttonKey,
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: c.surface,
        foregroundColor: color,
        disabledForegroundColor: c.faint,
        side: BorderSide(
          color: onPressed == null && !busy ? c.chipLine : color,
          width: 1.5,
        ),
        shape: shape,
        padding: padding,
        minimumSize: minimum,
        tapTargetSize: tapTarget,
        textStyle: textStyle,
      ),
      child: content,
    );
  }
}

/// `.sw`: 38x22 switch, green when on, 18px white thumb.
class LavishSwitch extends StatelessWidget {
  const LavishSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      onTap: enabled ? () => onChanged!(!value) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38,
            height: 22,
            decoration: BoxDecoration(
              color: value ? LavishColors.ok : c.chipLine,
              borderRadius: BorderRadius.circular(999),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x4D000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
