import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';

class FootballScorePanel extends ConsumerWidget {
  final MatchControlParams params;
  final String team1Name;
  final String team2Name;

  const FootballScorePanel({
    super.key,
    required this.params,
    required this.team1Name,
    required this.team2Name,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scorePanelNotifierProvider(params));
    final notifier = ref.read(scorePanelNotifierProvider(params).notifier);
    final l10n = AppLocalizations.of(context)!;
    final score = state.football ?? const FootballLiveState();
    final phases = <String>[
      'FIRST_HALF',
      'HALFTIME',
      'SECOND_HALF',
      'STOPPAGE_TIME',
      'FULL_TIME',
      'EXTRA_TIME_FIRST_HALF',
      'EXTRA_TIME_BREAK',
      'EXTRA_TIME_SECOND_HALF',
      'PENALTY_SHOOTOUT',
      'COMPLETED',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _TeamScore(
                      name: team1Name,
                      score: score.team1Goals,
                      onAdd: () => notifier.footballAddGoal(true),
                      onRemove: () => notifier.footballRemoveGoal(true),
                      disabled: state.isSubmitting,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _TeamScore(
                      name: team2Name,
                      score: score.team2Goals,
                      onAdd: () => notifier.footballAddGoal(false),
                      onRemove: () => notifier.footballRemoveGoal(false),
                      disabled: state.isSubmitting,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FootballTimeFields(
                      minute: score.minute,
                      addedMinute: score.addedMinute,
                      onMinuteSubmitted: notifier.footballSetMinute,
                      onAddedMinuteSubmitted: notifier.footballSetAddedMinute,
                      disabled: state.isSubmitting,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: score.phase,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.footballScore_status,
                        isDense: true,
                      ),
                      items: phases
                          .map(
                            (phase) => DropdownMenuItem(
                              value: phase,
                              child: Text(
                                _label(l10n, phase),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: state.isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                notifier.footballSetPhase(value);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (score.team1Goals == score.team2Goals)
            _ShootoutFields(
              team1Name: team1Name,
              team2Name: team2Name,
              team1Goals: score.shootoutTeam1Goals,
              team2Goals: score.shootoutTeam2Goals,
              disabled: state.isSubmitting,
              onChanged: (team1Goals, team2Goals) =>
                  notifier.footballSetShootout(
                    team1Goals: team1Goals,
                    team2Goals: team2Goals,
                  ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final event in const [
                    'YELLOW_CARD',
                    'RED_CARD',
                    'FOUL',
                    'PENALTY_GOAL',
                    'SUBSTITUTION',
                  ])
                    OutlinedButton.icon(
                      onPressed: state.isSubmitting
                          ? null
                          : () => _showTeamPicker(
                              context,
                              ref,
                              params,
                              event,
                              _eventLabel(l10n, event),
                            ),
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      label: Text(_eventLabel(l10n, event)),
                    ),
                ],
              ),
            ),
          ),
          if (score.events.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.footballScore_events,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    for (final event in score.events.reversed.take(8))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "${event.minute}${event.addedMinute > 0 ? '+${event.addedMinute}' : ''}' · ${_eventLabel(l10n, event.type)} · ${event.isTeam1 ? team1Name : team2Name}",
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (state.errorMessage case final message?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  static String _eventLabel(AppLocalizations l10n, String type) =>
      switch (type) {
        'GOAL' => l10n.footballScore_goal,
        'PENALTY_GOAL' => l10n.footballScore_penaltyGoal,
        'YELLOW_CARD' => l10n.footballScore_yellowCard,
        'RED_CARD' => l10n.footballScore_redCard,
        'FOUL' => l10n.footballScore_foul,
        'SUBSTITUTION' => l10n.footballScore_substitution,
        _ => type,
      };

  static Future<void> _showTeamPicker(
    BuildContext context,
    WidgetRef ref,
    MatchControlParams params,
    String type,
    String label,
  ) async {
    final team = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '$label · ${AppLocalizations.of(sheetContext)!.footballScore_team1}',
              ),
              onTap: () => Navigator.pop(sheetContext, true),
            ),
            ListTile(
              title: Text(
                '$label · ${AppLocalizations.of(sheetContext)!.footballScore_team2}',
              ),
              onTap: () => Navigator.pop(sheetContext, false),
            ),
          ],
        ),
      ),
    );
    if (team != null && context.mounted) {
      ref
          .read(scorePanelNotifierProvider(params).notifier)
          .footballAddEvent(type, team);
    }
  }

  static String _label(AppLocalizations l10n, String phase) => switch (phase) {
    'FIRST_HALF' => l10n.footballScore_firstHalf,
    'HALFTIME' => l10n.footballScore_halftime,
    'SECOND_HALF' => l10n.footballScore_secondHalf,
    'STOPPAGE_TIME' => l10n.footballScore_stoppageTime,
    'FULL_TIME' => l10n.footballScore_fullTime,
    'EXTRA_TIME_FIRST_HALF' => l10n.footballScore_extraTimeFirstHalf,
    'EXTRA_TIME_BREAK' => l10n.footballScore_extraTimeBreak,
    'EXTRA_TIME_SECOND_HALF' => l10n.footballScore_extraTimeSecondHalf,
    'PENALTY_SHOOTOUT' => l10n.footballScore_penaltyShootout,
    'COMPLETED' => l10n.footballScore_completed,
    _ => phase,
  };
}

class _TeamScore extends StatelessWidget {
  final String name;
  final int score;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool disabled;

  const _TeamScore({
    required this.name,
    required this.score,
    required this.onAdd,
    required this.onRemove,
    this.disabled = false,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      Text(
        '$score',
        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: disabled || score == 0 ? null : onRemove,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            onPressed: disabled ? null : onAdd,
            icon: const Icon(Icons.add_circle, color: Colors.green),
          ),
        ],
      ),
    ],
  );
}

class _ShootoutFields extends StatefulWidget {
  final String team1Name;
  final String team2Name;
  final int? team1Goals;
  final int? team2Goals;
  final void Function(int? team1Goals, int? team2Goals) onChanged;
  final bool disabled;

  const _ShootoutFields({
    required this.team1Name,
    required this.team2Name,
    required this.team1Goals,
    required this.team2Goals,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  State<_ShootoutFields> createState() => _ShootoutFieldsState();
}

class _ShootoutFieldsState extends State<_ShootoutFields> {
  late final TextEditingController _team1Controller;
  late final TextEditingController _team2Controller;

  @override
  void initState() {
    super.initState();
    _team1Controller = TextEditingController(
      text: widget.team1Goals?.toString() ?? '',
    );
    _team2Controller = TextEditingController(
      text: widget.team2Goals?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _ShootoutFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.team1Goals != oldWidget.team1Goals &&
        widget.team1Goals?.toString() != _team1Controller.text) {
      _team1Controller.text = widget.team1Goals?.toString() ?? '';
    }
    if (widget.team2Goals != oldWidget.team2Goals &&
        widget.team2Goals?.toString() != _team2Controller.text) {
      _team2Controller.text = widget.team2Goals?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    super.dispose();
  }

  int? _parseOptionalScore(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : int.tryParse(trimmed);
  }

  void _emit() => widget.onChanged(
    _parseOptionalScore(_team1Controller.text),
    _parseOptionalScore(_team2Controller.text),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _team1Controller,
                keyboardType: TextInputType.number,
                readOnly: widget.disabled,
                decoration: InputDecoration(
                  labelText:
                      '${widget.team1Name} · ${l10n.footballScore_penaltyLabel}',
                  isDense: true,
                ),
                onChanged: (_) => _emit(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _team2Controller,
                keyboardType: TextInputType.number,
                readOnly: widget.disabled,
                decoration: InputDecoration(
                  labelText:
                      '${widget.team2Name} · ${l10n.footballScore_penaltyLabel}',
                  isDense: true,
                ),
                onChanged: (_) => _emit(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FootballTimeFields extends StatefulWidget {
  final int minute;
  final int addedMinute;
  final ValueChanged<int> onMinuteSubmitted;
  final ValueChanged<int> onAddedMinuteSubmitted;
  final bool disabled;

  const _FootballTimeFields({
    required this.minute,
    required this.addedMinute,
    required this.onMinuteSubmitted,
    required this.onAddedMinuteSubmitted,
    this.disabled = false,
  });

  @override
  State<_FootballTimeFields> createState() => _FootballTimeFieldsState();
}

class _FootballTimeFieldsState extends State<_FootballTimeFields> {
  late final TextEditingController _minuteController;
  late final TextEditingController _addedMinuteController;

  @override
  void initState() {
    super.initState();
    _minuteController = TextEditingController(text: widget.minute.toString());
    _addedMinuteController = TextEditingController(
      text: widget.addedMinute.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _FootballTimeFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.minute != oldWidget.minute &&
        _minuteController.text != widget.minute.toString()) {
      _minuteController.text = widget.minute.toString();
    }
    if (widget.addedMinute != oldWidget.addedMinute &&
        _addedMinuteController.text != widget.addedMinute.toString()) {
      _addedMinuteController.text = widget.addedMinute.toString();
    }
  }

  @override
  void dispose() {
    _minuteController.dispose();
    _addedMinuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minuteController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.footballScore_minute,
              isDense: true,
            ),
            onSubmitted: (value) =>
                widget.onMinuteSubmitted(int.tryParse(value) ?? widget.minute),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _addedMinuteController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.footballScore_addedMinute,
              isDense: true,
            ),
            onSubmitted: (value) => widget.onAddedMinuteSubmitted(
              int.tryParse(value) ?? widget.addedMinute,
            ),
          ),
        ),
      ],
    );
  }
}
