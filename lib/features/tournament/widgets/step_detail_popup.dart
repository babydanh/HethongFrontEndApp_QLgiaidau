import 'package:app_quanly_giaidau/core/dialogs/popup_dialog.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/tournament_step_summary.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_edit_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Search box and "only missing" switch appear once the list is this long.
const _controlsMinDivisions = 6;

/// Opens the detail popup of one progress step: status ring, the todo box and
/// the per-division list. "Đi tới" / "Mở" close the popup first, then hand the
/// [StepTarget] to [onGo]; "Tải lại" closes it and calls [onRetry]. The popup
/// never writes data.
Future<void> showStepDetailPopup(
  BuildContext context, {
  required StepKey step,
  required StepSummary summary,
  required ValueChanged<StepTarget> onGo,
  VoidCallback? onRetry,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    sheetAnimationStyle: popupSheetAnimation,
    builder: (sheetContext) {
      void leaveThen(VoidCallback action) {
        Navigator.of(sheetContext).pop();
        action();
      }

      return TournamentEditSheet(
        title: _stepTitle(l10n, step),
        child: _StepDetailBody(
          state: summary.steps.firstWhere((s) => s.key == step),
          divisions: summary.divisions,
          onGo: (target) => leaveThen(() => onGo(target)),
          onRetry: onRetry == null ? null : () => leaveThen(onRetry),
        ),
      );
    },
  );
}

String _stepTitle(AppLocalizations l10n, StepKey key) => switch (key) {
  StepKey.registration => l10n.lifecycleStepOpen,
  StepKey.schedule => l10n.lifecycleStepSchedule,
  StepKey.inProgress => l10n.lifecycleStepRunning,
  StepKey.completed => l10n.lifecycleStepDone,
};

String _statusLabel(AppLocalizations l10n, StepStatus status) =>
    switch (status) {
      StepStatus.done => l10n.stepPopup_statusDone,
      StepStatus.attention => l10n.stepPopup_statusAttention,
      StepStatus.missing => l10n.stepPopup_statusMissing,
      StepStatus.current => l10n.stepPopup_statusCurrent,
      StepStatus.upcoming => l10n.stepPopup_statusUpcoming,
      StepStatus.loading => l10n.stepPopup_statusLoading,
      StepStatus.disabled => l10n.stepPopup_statusDisabled,
    };

Color _statusColor(StepStatus status) => switch (status) {
  StepStatus.done => LavishColors.ok,
  StepStatus.attention => LavishColors.warn,
  StepStatus.missing => LavishColors.bad,
  StepStatus.current => LavishColors.accent,
  _ => const Color(0xFF98A2B3),
};

String _todoLabel(AppLocalizations l10n, StepTodo todo) {
  final count = todo.count ?? 0;
  final name = '${todo.params['name'] ?? ''}';
  return switch (todo.labelKey) {
    'venue' => l10n.stepTodo_venue,
    'dates' => l10n.stepTodo_dates,
    'deadline' => l10n.stepTodo_deadline,
    'emptyDivisions' => l10n.stepTodo_emptyDivisions(count),
    'unpaid' => l10n.stepTodo_unpaid(count),
    'teamsWaiting' => l10n.stepTodo_teamsWaiting(count),
    'openDuringPlay' => l10n.stepTodo_openDuringPlay(count),
    'noBracket' => l10n.stepTodo_noBracket(name),
    'noCourt' => l10n.stepTodo_noCourt(count),
    'noTime' => l10n.stepTodo_noTime(count),
    'disputed' => l10n.stepTodo_disputed(count),
    'late' => l10n.stepTodo_late(count),
    'unfinishedMatches' => l10n.stepTodo_unfinishedMatches(count),
    'endDateExpected' => l10n.stepTodo_endDateExpected,
    _ => l10n.stepTodo_loadFailed,
  };
}

class _StepDetailBody extends StatelessWidget {
  const _StepDetailBody({
    required this.state,
    required this.divisions,
    required this.onGo,
    required this.onRetry,
  });

  final StepProgress state;
  final List<StepDivisionRow> divisions;
  final ValueChanged<StepTarget> onGo;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('step-popup-body'),
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _Header(state: state),
        const SizedBox(height: 12),
        _TodoBox(state: state, onGo: onGo, onRetry: onRetry),
        const SizedBox(height: 16),
        _DivisionsSection(divisions: divisions, onGo: onGo),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final StepProgress state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = LavishColors.of(context);
    final status = _statusLabel(l10n, state.state);
    final todoCount = state.todos.length;
    final subtitle = todoCount > 0
        ? l10n.stepPopup_subtitleTodos(status, todoCount)
        : status;
    final color = _statusColor(state.state);
    final showRing =
        state.state != StepStatus.loading && state.state != StepStatus.disabled;
    return Row(
      children: [
        if (showRing)
          Semantics(
            label: l10n.stepPopup_percentSr(state.percent),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: state.percent / 100,
                    strokeWidth: 5,
                    color: color,
                    backgroundColor: colors.line,
                  ),
                  Text(
                    '${state.percent}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (showRing) const SizedBox(width: 12),
        Expanded(
          child: Text(
            subtitle,
            key: const ValueKey('step-popup-subtitle'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _TodoBox extends StatelessWidget {
  const _TodoBox({
    required this.state,
    required this.onGo,
    required this.onRetry,
  });

  final StepProgress state;
  final ValueChanged<StepTarget> onGo;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (state.state) {
      case StepStatus.loading:
        return _note(context, l10n.stepPopup_loadingReason);
      case StepStatus.disabled:
        return const SizedBox.shrink();
      case _ when state.todos.isNotEmpty:
        return Column(
          children: [
            for (final todo in state.todos)
              _TodoRow(todo: todo, onGo: onGo, onRetry: onRetry),
          ],
        );
      case StepStatus.done || StepStatus.current:
        return _note(context, l10n.stepPopup_todoDone);
      case StepStatus.upcoming:
        return _note(context, l10n.stepPopup_todoNotYet);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _note(BuildContext context, String text) => Container(
    key: const ValueKey('step-popup-note'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: LavishColors.of(context).rowLine,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(text),
  );
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.todo,
    required this.onGo,
    required this.onRetry,
  });

  final StepTodo todo;
  final ValueChanged<StepTarget> onGo;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final retry = todo.retry;
    final VoidCallback? action = retry ? onRetry : () => onGo(todo.target);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        key: ValueKey('step-popup-todo-${todo.key}'),
        children: [
          Expanded(child: Text(_todoLabel(l10n, todo))),
          const SizedBox(width: 8),
          TextButton(
            key: ValueKey('step-popup-go-${todo.key}'),
            onPressed: action,
            child: Text(retry ? l10n.stepPopup_retry : l10n.stepPopup_goTo),
          ),
        ],
      ),
    );
  }
}

class _DivisionsSection extends StatefulWidget {
  const _DivisionsSection({required this.divisions, required this.onGo});

  final List<StepDivisionRow> divisions;
  final ValueChanged<StepTarget> onGo;

  @override
  State<_DivisionsSection> createState() => _DivisionsSectionState();
}

class _DivisionsSectionState extends State<_DivisionsSection> {
  late bool _onlyMissing = widget.divisions.any((d) => d.missing);
  String _query = '';

  bool get _hasControls => widget.divisions.length >= _controlsMinDivisions;

  List<StepDivisionRow> get _shown {
    if (!_hasControls) return widget.divisions;
    final needle = _query.trim().toLowerCase();
    return widget.divisions
        .where(
          (d) =>
              (!_onlyMissing || d.missing) &&
              (needle.isEmpty || d.name.toLowerCase().contains(needle)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shown = _shown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.stepPopup_divisionsTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_hasControls) _controls(l10n),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                widget.divisions.isEmpty
                    ? l10n.stepPopup_noDivisions
                    : l10n.stepPopup_emptyFiltered,
              ),
            ),
          )
        else
          for (final d in shown) _row(l10n, d),
      ],
    );
  }

  Widget _controls(AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      children: [
        TextField(
          key: const ValueKey('step-popup-search'),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: l10n.stepPopup_searchPlaceholder,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          key: const ValueKey('step-popup-filter'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: true, label: Text(l10n.stepPopup_onlyMissing)),
            ButtonSegment(
              value: false,
              label: Text(l10n.stepPopup_all(widget.divisions.length)),
            ),
          ],
          selected: {_onlyMissing},
          onSelectionChanged: (value) =>
              setState(() => _onlyMissing = value.first),
        ),
      ],
    ),
  );

  Widget _row(AppLocalizations l10n, StepDivisionRow d) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      key: ValueKey('step-popup-division-${d.id}'),
      children: [
        Icon(
          d.missing ? Icons.error_outline_rounded : Icons.check_circle_outline,
          size: 18,
          color: d.missing ? LavishColors.warn : LavishColors.ok,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(d.name)),
        TextButton(
          key: ValueKey('step-popup-open-${d.id}'),
          onPressed: () => widget.onGo(d.target),
          child: Semantics(
            label: l10n.stepPopup_openLabel(d.name),
            child: Text(l10n.stepPopup_open),
          ),
        ),
      ],
    ),
  );
}
