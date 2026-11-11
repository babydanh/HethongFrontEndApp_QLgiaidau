import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_create_settings.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_quick_suggestion.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// What the organizer confirmed: the merged `roundConfig` to save and the
/// seeding type to send with `generate-bracket`.
class BracketCreateResult {
  const BracketCreateResult({
    required this.roundConfig,
    required this.seedingType,
  });

  final Map<String, dynamic> roundConfig;
  final String seedingType;
}

/// Settings popup shown before creating a Round Robin / group-stage bracket
/// (like the Web setup). Teams are not placed here: the organizer drags them
/// on the bracket once it exists.
class BracketCreateSheet extends StatefulWidget {
  const BracketCreateSheet({
    super.key,
    required this.bracketType,
    required this.participantCount,
    required this.roundConfig,
  });

  /// `ROUND_ROBIN` or `GROUP_STAGE_KNOCKOUT`.
  final String bracketType;
  final int participantCount;
  final Map<String, dynamic>? roundConfig;

  static Future<BracketCreateResult?> show(
    BuildContext context, {
    required String bracketType,
    required int participantCount,
    required Map<String, dynamic>? roundConfig,
  }) => showModalBottomSheet<BracketCreateResult>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BracketCreateSheet(
      bracketType: bracketType,
      participantCount: participantCount,
      roundConfig: roundConfig,
    ),
  );

  @override
  State<BracketCreateSheet> createState() => _BracketCreateSheetState();
}

class _BracketCreateSheetState extends State<BracketCreateSheet> {
  late BracketCreateSettings _settings;
  late final BracketQuickSuggestion? _suggestion;
  final _groups = TextEditingController();
  final _teamsPerGroup = TextEditingController();
  final _advancing = TextEditingController();
  final _rounds = TextEditingController();

  bool get _roundRobin => widget.bracketType.toUpperCase() == 'ROUND_ROBIN';

  @override
  void initState() {
    super.initState();
    _suggestion = bracketQuickSuggestion(
      bracketType: widget.bracketType,
      participantCount: widget.participantCount,
    );
    _settings = initialBracketCreateSettings(
      bracketType: widget.bracketType,
      participantCount: widget.participantCount,
      roundConfig: widget.roundConfig,
    );
    _syncControllers();
  }

  @override
  void dispose() {
    _groups.dispose();
    _teamsPerGroup.dispose();
    _advancing.dispose();
    _rounds.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _groups.text = '${_settings.numGroups}';
    _teamsPerGroup.text = '${_settings.teamsPerGroup}';
    _advancing.text = '${_settings.teamsAdvancing}';
    _rounds.text = '${_settings.roundsToPlay}';
  }

  int get _capacity => _settings.numGroups * _settings.teamsPerGroup;

  bool get _overCapacity => !_roundRobin && _capacity < widget.participantCount;

  bool get _differsFromSuggestion {
    final s = _suggestion;
    if (s == null) return false;
    if (_roundRobin) return s.roundsToPlay != _settings.roundsToPlay;
    return s.groups != _settings.numGroups ||
        s.teamsPerGroup != _settings.teamsPerGroup ||
        s.teamsAdvancing != _settings.teamsAdvancing;
  }

  void _applySuggestion() {
    final s = _suggestion;
    if (s == null) return;
    setState(() {
      _settings = _settings.copyWith(
        numGroups: s.groups,
        teamsPerGroup: s.teamsPerGroup,
        teamsAdvancing: s.teamsAdvancing,
        roundsToPlay: s.roundsToPlay,
      );
      _syncControllers();
    });
  }

  void _confirm() {
    if (_overCapacity) return;
    Navigator.of(context).pop(
      BracketCreateResult(
        roundConfig: buildBracketCreateRoundConfig(
          bracketType: widget.bracketType,
          existing: widget.roundConfig,
          settings: _settings,
        ),
        seedingType: _roundRobin ? 'RANDOM' : _settings.seedingType,
      ),
    );
  }

  Widget _numberField({
    required String key,
    required String label,
    required TextEditingController controller,
    required ValueChanged<int> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      key: ValueKey(key),
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (text) {
        final parsed = int.tryParse(text.trim());
        if (parsed != null) setState(() => onChanged(parsed));
      },
    ),
  );

  Widget _choiceRow({
    required String label,
    required String keyPrefix,
    required String selected,
    required List<(String, String)> options,
    required ValueChanged<String> onSelected,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (value, text) in options)
                ChoiceChip(
                  key: ValueKey('$keyPrefix-$value'),
                  label: Text(text),
                  selected: selected == value,
                  onSelected: (_) => onSelected(value),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _suggestionRow(AppLocalizations l10n) {
    final s = _suggestion!;
    final text = _roundRobin
        ? l10n.bracketCreate_suggestionLegs(s.roundsToPlay ?? 1)
        : l10n.bracketCreate_suggestion(
            s.groups ?? 0,
            s.teamsPerGroup ?? 0,
            s.teamsAdvancing ?? 0,
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('bracket-create-apply-suggestion'),
            onPressed: _applySuggestion,
            child: Text(l10n.bracketCreate_apply),
          ),
        ],
      ),
    );
  }

  List<Widget> _groupStageFields(AppLocalizations l10n) => [
    _numberField(
      key: 'bracket-create-groups',
      label: l10n.divisionEditorNumGroups,
      controller: _groups,
      onChanged: (v) => _settings = _settings.copyWith(numGroups: v),
    ),
    _numberField(
      key: 'bracket-create-teams-per-group',
      label: l10n.divisionEditorTeamsPerGroup,
      controller: _teamsPerGroup,
      onChanged: (v) => _settings = _settings.copyWith(teamsPerGroup: v),
    ),
    _numberField(
      key: 'bracket-create-advancing',
      label: l10n.divisionEditorTeamsAdvancing,
      controller: _advancing,
      onChanged: (v) => _settings = _settings.copyWith(teamsAdvancing: v),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TournamentManageSheet(
      title: l10n.bracketCreate_title,
      heightFactor: 0.8,
      actions: [
        FilledButton(
          key: const ValueKey('bracket-create-confirm'),
          onPressed: _overCapacity ? null : _confirm,
          child: Text(l10n.bracketMgmt_create),
        ),
        TextButton(
          key: const ValueKey('bracket-create-cancel'),
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(l10n.bracketMgmt_cancel),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_suggestion != null && _differsFromSuggestion)
            _suggestionRow(l10n),
          if (!_roundRobin) ..._groupStageFields(l10n),
          _numberField(
            key: 'bracket-create-rounds',
            label: l10n.divisionEditorGroupStageRounds,
            controller: _rounds,
            onChanged: (v) => _settings = _settings.copyWith(roundsToPlay: v),
          ),
          if (!_roundRobin) ...[
            _choiceRow(
              label: l10n.divisionEditorPlayoffFormat,
              keyPrefix: 'bracket-create-playoff',
              selected: _settings.playoffType,
              options: [
                ('SINGLE_ELIMINATION', l10n.divisionEditorPlayoffSingle),
                ('DOUBLE_ELIMINATION', l10n.divisionEditorPlayoffDouble),
              ],
              onSelected: (v) => setState(
                () => _settings = _settings.copyWith(playoffType: v),
              ),
            ),
            _choiceRow(
              label: l10n.divisionEditorSeedingType,
              keyPrefix: 'bracket-create-seeding',
              selected: _settings.seedingType,
              options: [
                ('SEEDED', l10n.divisionEditorSeededByElo),
                ('RANDOM', l10n.divisionEditorRandomSeeding),
              ],
              onSelected: (v) => setState(
                () => _settings = _settings.copyWith(seedingType: v),
              ),
            ),
          ],
          if (_overCapacity)
            Padding(
              key: const ValueKey('bracket-create-capacity-error'),
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.bracketCreate_capacityError(
                  _capacity,
                  widget.participantCount,
                ),
                style: TextStyle(color: context.colors.error),
              ),
            ),
          Text(
            l10n.bracketCreate_dragHint,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
