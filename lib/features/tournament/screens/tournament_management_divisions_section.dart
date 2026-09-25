import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _matchTypes = ['SINGLES', 'DOUBLES', 'MIXED_DOUBLES'];
const _bracketTypes = [
  'SINGLE_ELIMINATION',
  'DOUBLE_ELIMINATION',
  'ROUND_ROBIN',
  'GROUP_STAGE_KNOCKOUT',
];

class TournamentManagementDivisionsSection extends ConsumerStatefulWidget {
  const TournamentManagementDivisionsSection({
    super.key,
    required this.tournament,
  });
  final Tournament tournament;

  @override
  ConsumerState<TournamentManagementDivisionsSection> createState() =>
      _TournamentManagementDivisionsSectionState();
}

class _TournamentManagementDivisionsSectionState
    extends ConsumerState<TournamentManagementDivisionsSection> {
  late Future<List<Map<String, dynamic>>> _divisionsFuture;
  bool _isBusy = false;
  String? _mutationError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _divisionsFuture = ref
      .read(tournamentManagementRepositoryProvider)
      .getManageDivisions(widget.tournament.id);
  void _reload() => setState(() {
    _mutationError = null;
    _load();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _divisionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return TournamentManagementError(onRetry: _reload);
        final divisions = snapshot.data ?? const <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TournamentManagementSectionCard(
              title: l10n.tournamentManagementDivisions,
              subtitle: l10n.tournamentManagementDivisionsDescription,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _isBusy ? null : _createDivision,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.tournamentManagementAddDivision),
                    ),
                  ),
                  if (_mutationError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      l10n.tournamentManagementActionError,
                      style: TextStyle(color: context.colors.error),
                    ),
                  ],
                  if (divisions.isEmpty)
                    TournamentManagementEmpty(
                      title: l10n.tournamentManagementDivisionsEmpty,
                      subtitle:
                          l10n.tournamentManagementDivisionsEmptyDescription,
                      icon: Icons.category_outlined,
                    )
                  else ...[
                    const SizedBox(height: 12),
                    for (final division in divisions) ...[
                      _DivisionCard(
                        division: division,
                        isBusy: _isBusy,
                        onRename: () => _renameDivision(division),
                        onConfigure: () => _configureDivision(division),
                        onDelete: () => _deleteDivision(division),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              ),
            ),
            if (divisions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _TournamentSeedsSection(
                tournamentId: widget.tournament.id,
                divisions: divisions,
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _createDivision() async {
    final values = await showDialog<_DivisionValues>(
      context: context,
      builder: (context) => _DivisionDialog(tournament: widget.tournament),
    );
    if (values == null || !mounted) return;
    await _mutate(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .createDivision(widget.tournament.id, values.toCreatePayload()),
    );
  }

  Future<void> _renameDivision(Map<String, dynamic> division) async {
    final divisionId = _divisionId(division);
    if (divisionId.isEmpty) return;
    final controller = TextEditingController(text: _divisionName(division));
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(controller: controller),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    final name = value.trim();
    if (name.isEmpty) {
      _showMessage(
        AppLocalizations.of(context)!.tournamentManagementRequiredFields,
      );
      return;
    }
    await _mutate(
      () => ref.read(tournamentManagementRepositoryProvider).updateDivision(
        divisionId,
        {'name': name},
      ),
    );
  }

  Future<void> _configureDivision(Map<String, dynamic> division) async {
    final divisionId = _divisionId(division);
    if (divisionId.isEmpty) return;
    final values = await showDialog<_DivisionConfigValues>(
      context: context,
      builder: (context) => _DivisionConfigDialog(division: division),
    );
    if (values == null || !mounted) return;
    await _mutate(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .updateDivisionConfig(
            widget.tournament.id,
            divisionId,
            values.toPayload(),
          ),
    );
  }

  Future<void> _deleteDivision(Map<String, dynamic> division) async {
    final l10n = AppLocalizations.of(context)!;
    final divisionId = _divisionId(division);
    if (divisionId.isEmpty) return;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementDeleteDivision,
      message: l10n.tournamentManagementDeleteDivisionConfirm(
        _divisionName(division),
      ),
      confirmLabel: l10n.tournamentManagementDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _mutate(
      () => ref
          .read(tournamentManagementRepositoryProvider)
          .deleteDivision(divisionId),
    );
  }

  Future<void> _mutate<T>(Future<T> Function() operation) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _mutationError = null;
    });
    try {
      await operation();
      if (mounted) _reload();
    } catch (_) {
      if (mounted) setState(() => _mutationError = 'error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _DivisionValues {
  const _DivisionValues({
    required this.name,
    required this.matchType,
    required this.bracketType,
    required this.maxParticipants,
  });
  final String name;
  final String matchType;
  final String bracketType;
  final int? maxParticipants;

  Map<String, dynamic> toCreatePayload() => {
    'name': name,
    'matchType': matchType,
    'bracketType': bracketType,
    if (maxParticipants != null) 'maxParticipants': maxParticipants,
  };
}

class _DivisionDialog extends StatefulWidget {
  const _DivisionDialog({required this.tournament});
  final Tournament tournament;

  @override
  State<_DivisionDialog> createState() => _DivisionDialogState();
}

class _DivisionDialogState extends State<_DivisionDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _max = TextEditingController();
  late String _matchType = _normalize(
    widget.tournament.format.toUpperCase(),
    _matchTypes,
    'DOUBLES',
  );
  late String _bracketType = _normalize(
    widget.tournament.bracketType.toUpperCase(),
    _bracketTypes,
    'SINGLE_ELIMINATION',
  );
  bool _hasError = false;

  @override
  void dispose() {
    _name.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.tournamentManagementAddDivision),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.tournamentManagementDivisionName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _matchType,
              decoration: InputDecoration(
                labelText: l10n.tournamentManagementMatchType,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final value in _matchTypes)
                  DropdownMenuItem(
                    value: value,
                    child: Text(_matchTypeLabel(l10n, value)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _matchType = value);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _bracketType,
              decoration: InputDecoration(
                labelText: l10n.tournamentManagementBracketType,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final value in _bracketTypes)
                  DropdownMenuItem(
                    value: value,
                    child: Text(_bracketTypeLabel(l10n, value)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _bracketType = value);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _max,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.tournamentManagementMaxParticipants,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_hasError)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.tournamentManagementRequiredFields,
                  style: TextStyle(color: context.colors.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.tournamentManagementCancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.tournamentManagementSave),
        ),
      ],
    );
  }

  void _save() {
    final name = _name.text.trim();
    final rawMax = _max.text.trim();
    final max = rawMax.isEmpty ? null : int.tryParse(rawMax);
    if (name.isEmpty || (rawMax.isNotEmpty && (max == null || max < 1))) {
      setState(() => _hasError = true);
      return;
    }
    Navigator.pop(
      context,
      _DivisionValues(
        name: name,
        matchType: _matchType,
        bracketType: _bracketType,
        maxParticipants: max,
      ),
    );
  }
}

class _NameDialog extends StatelessWidget {
  const _NameDialog({required this.controller});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.tournamentManagementRenameDivision),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.tournamentManagementDivisionName,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.tournamentManagementCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(l10n.tournamentManagementSave),
        ),
      ],
    );
  }
}

class _DivisionConfigValues {
  const _DivisionConfigValues({
    required this.matchType,
    required this.bracketType,
    required this.maxParticipants,
  });
  final String matchType;
  final String bracketType;
  final int? maxParticipants;
  Map<String, dynamic> toPayload() => {
    'matchType': matchType,
    'bracketType': bracketType,
    'maxParticipants': maxParticipants,
  };
}

class _DivisionConfigDialog extends StatefulWidget {
  const _DivisionConfigDialog({required this.division});
  final Map<String, dynamic> division;
  @override
  State<_DivisionConfigDialog> createState() => _DivisionConfigDialogState();
}

class _DivisionConfigDialogState extends State<_DivisionConfigDialog> {
  late String _matchType = _normalize(
    (widget.division['matchType'] ?? 'DOUBLES').toString(),
    _matchTypes,
    'DOUBLES',
  );
  late String _bracketType = _normalize(
    (widget.division['bracketType'] ?? 'SINGLE_ELIMINATION').toString(),
    _bracketTypes,
    'SINGLE_ELIMINATION',
  );
  late final TextEditingController _max = TextEditingController(
    text: widget.division['maxParticipants']?.toString() ?? '',
  );
  bool _hasError = false;
  @override
  void dispose() {
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.tournamentManagementDivisionConfiguration),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _matchType,
              decoration: InputDecoration(
                labelText: l10n.tournamentManagementMatchType,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final value in _matchTypes)
                  DropdownMenuItem(
                    value: value,
                    child: Text(_matchTypeLabel(l10n, value)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _matchType = value);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _bracketType,
              decoration: InputDecoration(
                labelText: l10n.tournamentManagementBracketType,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final value in _bracketTypes)
                  DropdownMenuItem(
                    value: value,
                    child: Text(_bracketTypeLabel(l10n, value)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _bracketType = value);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _max,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.tournamentManagementMaxParticipants,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_hasError)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.tournamentManagementRequiredFields,
                  style: TextStyle(color: context.colors.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.tournamentManagementCancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.tournamentManagementSave),
        ),
      ],
    );
  }

  void _save() {
    final raw = _max.text.trim();
    final value = raw.isEmpty ? null : int.tryParse(raw);
    if (raw.isNotEmpty && (value == null || value < 1)) {
      setState(() => _hasError = true);
      return;
    }
    Navigator.pop(
      context,
      _DivisionConfigValues(
        matchType: _matchType,
        bracketType: _bracketType,
        maxParticipants: value,
      ),
    );
  }
}

class _DivisionCard extends StatelessWidget {
  const _DivisionCard({
    required this.division,
    required this.isBusy,
    required this.onRename,
    required this.onConfigure,
    required this.onDelete,
  });
  final Map<String, dynamic> division;
  final bool isBusy;
  final VoidCallback onRename;
  final VoidCallback onConfigure;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final match = (division['matchType'] ?? '').toString().toUpperCase();
    final bracket = (division['bracketType'] ?? '').toString().toUpperCase();
    final maximum = division['maxParticipants']?.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _divisionName(division),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_matchTypeLabel(l10n, match)} · ${_bracketTypeLabel(l10n, bracket)}${maximum == null ? '' : ' · ${l10n.tournamentManagementMaxParticipants}: $maximum'}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: !isBusy,
            onSelected: (value) {
              if (value == 'rename') onRename();
              if (value == 'config') onConfigure();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rename',
                child: Text(l10n.tournamentManagementRenameDivision),
              ),
              PopupMenuItem(
                value: 'config',
                child: Text(l10n.tournamentManagementDivisionConfiguration),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  l10n.tournamentManagementDelete,
                  style: TextStyle(color: colors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TournamentSeedsSection extends ConsumerStatefulWidget {
  const _TournamentSeedsSection({
    required this.tournamentId,
    required this.divisions,
  });
  final String tournamentId;
  final List<Map<String, dynamic>> divisions;
  @override
  ConsumerState<_TournamentSeedsSection> createState() =>
      _TournamentSeedsSectionState();
}

class _TournamentSeedsSectionState
    extends ConsumerState<_TournamentSeedsSection> {
  String? _divisionId;
  Future<List<OrganizerOpsParticipant>>? _participantsFuture;
  final Map<String, int?> _seeds = {};
  bool _isBusy = false;
  String? _error;

  String? get _activeDivisionId {
    final ids = widget.divisions
        .map(_divisionIdFor)
        .where((id) => id.isNotEmpty)
        .toSet();
    if (_divisionId != null && ids.contains(_divisionId)) return _divisionId;
    return ids.isEmpty ? null : ids.first;
  }

  void _loadParticipants(String? divisionId) {
    if (divisionId == null) {
      _participantsFuture = Future.value(const <OrganizerOpsParticipant>[]);
      return;
    }
    _participantsFuture = ref
        .read(tournamentRepositoryProvider)
        .getOrganizerParticipants(widget.tournamentId, divisionId: divisionId);
    _seeds.clear();
  }

  @override
  void initState() {
    super.initState();
    _divisionId = _activeDivisionId;
    _loadParticipants(_divisionId);
  }

  @override
  void didUpdateWidget(covariant _TournamentSeedsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_divisionId == null ||
        !widget.divisions.any(
          (division) => _divisionIdFor(division) == _divisionId,
        )) {
      _divisionId = _activeDivisionId;
      _loadParticipants(_divisionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final divisionId = _activeDivisionId;
    return TournamentManagementSectionCard(
      title: l10n.tournamentManagementSeeding,
      subtitle: l10n.tournamentManagementSeedingDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: divisionId,
            decoration: InputDecoration(
              labelText: l10n.tournamentManagementDivision,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final division in widget.divisions)
                DropdownMenuItem(
                  value: _divisionIdFor(division),
                  child: Text(_divisionName(division)),
                ),
            ],
            onChanged: _isBusy
                ? null
                : (value) {
                    if (value != null)
                      setState(() {
                        _divisionId = value;
                        _loadParticipants(value);
                        _error = null;
                      });
                  },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isBusy || divisionId == null ? null : _autoSeed,
                icon: _isBusy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: Text(l10n.tournamentManagementAutoSeed),
              ),
              FilledButton.icon(
                onPressed: _isBusy || divisionId == null ? null : _saveSeeds,
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.tournamentManagementSaveSeeds),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error == 'validation'
                  ? l10n.tournamentManagementSeedValidationError
                  : l10n.tournamentManagementActionError,
              style: TextStyle(color: context.colors.error),
            ),
          ],
          const SizedBox(height: 10),
          if (_participantsFuture == null)
            TournamentManagementEmpty(
              title: l10n.tournamentManagementParticipantsEmpty,
              icon: Icons.groups_outlined,
            )
          else
            FutureBuilder<List<OrganizerOpsParticipant>>(
              future: _participantsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  );
                if (snapshot.hasError)
                  return TournamentManagementError(
                    onRetry: () =>
                        setState(() => _loadParticipants(divisionId)),
                  );
                final participants =
                    snapshot.data ?? const <OrganizerOpsParticipant>[];
                if (participants.isEmpty)
                  return TournamentManagementEmpty(
                    title: l10n.tournamentManagementParticipantsEmpty,
                    icon: Icons.groups_outlined,
                  );
                return Column(
                  children: [
                    for (final participant in participants)
                      _SeedRow(
                        participant: participant,
                        onChanged: (value) => _seeds[participant.id] = value,
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _autoSeed() async {
    if (_isBusy || _activeDivisionId == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.tournamentManagementAutoSeed,
      message: l10n.tournamentManagementAutoSeedConfirm,
      confirmLabel: l10n.tournamentManagementAutoSeed,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .autoSeedParticipants(
            widget.tournamentId,
            divisionId: _activeDivisionId,
          );
      if (!mounted) return;
      setState(() => _loadParticipants(_activeDivisionId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tournamentManagementSeedsSaved)),
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _saveSeeds() async {
    if (_isBusy || _activeDivisionId == null) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final participants = await _participantsFuture;
      if (!mounted || participants == null || participants.isEmpty) return;
      final currentSeeds = {
        for (final participant in participants)
          participant.id: _seeds.containsKey(participant.id)
              ? _seeds[participant.id]
              : participant.seed,
      };
      final clearedExistingSeed = participants.any(
        (participant) =>
            participant.seed != null &&
            _seeds.containsKey(participant.id) &&
            _seeds[participant.id] == null,
      );
      final values = currentSeeds.values.whereType<int>().toList();
      if (clearedExistingSeed ||
          values.any((value) => value < 1) ||
          values.toSet().length != values.length) {
        setState(() => _error = 'validation');
        return;
      }
      await ref
          .read(tournamentManagementRepositoryProvider)
          .updateTournamentSeeds(widget.tournamentId, [
            for (final participant in participants)
              if (currentSeeds[participant.id] case final int seed)
                {'participantId': participant.id, 'seed': seed},
          ]);
      if (!mounted) return;
      setState(() => _loadParticipants(_activeDivisionId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tournamentManagementSeedsSaved)),
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
}

class _SeedRow extends StatelessWidget {
  const _SeedRow({required this.participant, required this.onChanged});
  final OrganizerOpsParticipant participant;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              participant.teamName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textPrimary),
            ),
          ),
          SizedBox(
            width: 88,
            child: TextFormField(
              key: ValueKey('${participant.id}-${participant.seed}'),
              initialValue: participant.seed?.toString() ?? '',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                )!.tournamentManagementSeed,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => onChanged(int.tryParse(value.trim())),
            ),
          ),
        ],
      ),
    );
  }
}

String _divisionId(Map<String, dynamic> division) =>
    (division['id'] ?? division['divisionId'] ?? '').toString();
String _divisionIdFor(Map<String, dynamic> division) => _divisionId(division);
String _divisionName(Map<String, dynamic> division) =>
    (division['name'] ?? '').toString();
String _normalize(String value, List<String> values, String fallback) =>
    values.contains(value.toUpperCase()) ? value.toUpperCase() : fallback;

String _matchTypeLabel(AppLocalizations l10n, String value) =>
    switch (value.toUpperCase()) {
      'SINGLES' => l10n.tournamentManagementMatchSingles,
      'DOUBLES' => l10n.tournamentManagementMatchDoubles,
      'MIXED_DOUBLES' => l10n.tournamentManagementMatchMixedDoubles,
      _ => l10n.tournamentManagementStatusOther,
    };

String _bracketTypeLabel(AppLocalizations l10n, String value) => switch (value
    .toUpperCase()) {
  'SINGLE_ELIMINATION' => l10n.tournamentManagementBracketSingleElimination,
  'DOUBLE_ELIMINATION' => l10n.tournamentManagementBracketDoubleElimination,
  'ROUND_ROBIN' => l10n.tournamentManagementBracketRoundRobin,
  'GROUP_STAGE_KNOCKOUT' => l10n.tournamentManagementBracketGroupThenKnockout,
  _ => l10n.tournamentManagementStatusOther,
};
