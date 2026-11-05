import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Lavish screen frame: dark page, back arrow, title, white body, sticky bottom.
class LavishScaffold extends StatelessWidget {
  const LavishScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
    this.bottom,
    this.onBack,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? bottom;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: l10n.lavishBack,
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: Text(title),
        actions: actions,
      ),
      body: LavishSurface(child: body),
      bottomNavigationBar: bottom,
    );
  }
}

/// Outlined input: 12px radius, 1.5px `chipLine` border, 15 / 800 text.
class LavishTextField extends StatefulWidget {
  const LavishTextField({
    super.key,
    required this.label,
    this.controller,
    this.errorText,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.trailing,
    this.onChanged,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  State<LavishTextField> createState() => _LavishTextFieldState();
}

class _LavishTextFieldState extends State<LavishTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hide = widget.obscure && _hidden;
    final suffix = widget.obscure
        ? IconButton(
            icon: Icon(
              _hidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
            ),
            tooltip: _hidden
                ? l10n.lavishPasswordShow
                : l10n.lavishPasswordHide,
            onPressed: () => setState(() => _hidden = !_hidden),
          )
        : widget.trailing;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 1.5),
    );
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: hide,
      keyboardType: widget.keyboardType,
      maxLines: hide ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: c.text,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(fontSize: 13, color: c.muted),
        errorText: widget.errorText,
        suffixIcon: suffix,
        border: border(c.chipLine),
        enabledBorder: border(c.chipLine),
        focusedBorder: border(LavishColors.accent),
        errorBorder: border(LavishColors.bad),
        focusedErrorBorder: border(LavishColors.bad),
      ),
    );
  }
}

/// Bottom bar with an optional inline error above a full-width button.
class LavishStickyBar extends StatelessWidget {
  const LavishStickyBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.error,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    final message = error;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (message != null) ...[
                _LavishInlineError(text: message),
                const SizedBox(height: 8),
              ],
              LavishButton(label: label, onPressed: onPressed, busy: busy),
            ],
          ),
        ),
      ),
    );
  }
}

class _LavishInlineError extends StatelessWidget {
  const _LavishInlineError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: LavishColors.bad.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: LavishColors.bad.withValues(alpha: 0.35)),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, color: LavishColors.bad),
    ),
  );
}

/// One figure cell: 18 / 800 value over an 11.5 muted label.
class LavishStat extends StatelessWidget {
  const LavishStat({
    super.key,
    required this.label,
    required this.value,
    this.tone = LavishTone.neutral,
  });

  final String label;
  final String value;
  final LavishTone tone;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: tone == LavishTone.neutral ? c.text : c.pillText(tone),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: c.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Even-column row of [LavishStat]s (up to 4 columns), split by `line`.
class LavishStatGrid extends StatelessWidget {
  const LavishStatGrid({super.key, required this.items});

  static const _maxColumns = 4;

  final List<LavishStat> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final c = LavishColors.of(context);
    final rows = <List<LavishStat>>[
      for (var i = 0; i < items.length; i += _maxColumns)
        items.sublist(i, (i + _maxColumns).clamp(0, items.length)),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _columnsFor(rows, r); i++) ...[
                    if (i > 0) VerticalDivider(width: 1, color: c.line),
                    Expanded(
                      child: i < rows[r].length
                          ? Center(child: rows[r][i])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  int _columnsFor(List<List<LavishStat>> rows, int index) =>
      rows.length == 1 ? rows[index].length : _maxColumns;
}

/// Centers [child]; in a bounded-height parent it scrolls when the content is
/// taller than the space (small screens, large text) and stays pull-to-refresh
/// friendly. In an unbounded parent (e.g. inside a ListView) it just centers.
class _LavishStateBody extends StatelessWidget {
  const _LavishStateBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) return Center(child: child);
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

/// Centred icon, short title and an optional outline action.
class LavishEmptyState extends StatelessWidget {
  const LavishEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    final label = action;
    return _LavishStateBody(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LavishIconBox(
              size: 56,
              tone: LavishTone.neutral,
              child: Icon(icon, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 14),
              LavishButton(
                label: label,
                onPressed: onAction,
                kind: LavishButtonKind.outline,
                dense: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Load failure: warning icon, message (default from l10n) and a retry button.
class LavishErrorState extends StatelessWidget {
  const LavishErrorState({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return _LavishStateBody(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LavishIconBox(
              size: 56,
              tone: LavishTone.bad,
              child: Icon(Icons.error_outline_rounded, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              message ?? l10n.lavishErrorDefault,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
            const SizedBox(height: 14),
            LavishButton(
              label: l10n.lavishRetry,
              onPressed: onRetry,
              kind: LavishButtonKind.outline,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder rows shaped like a [LavishRow] with a circle avatar.
class LavishRowSkeleton extends StatelessWidget {
  const LavishRowSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    return SkeletonScope(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.rowLine)),
              ),
              child: const Row(
                children: [
                  SkeletonCircle(size: 34),
                  SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 140, height: 13),
                        SizedBox(height: 6),
                        SkeletonBox(width: 90, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
