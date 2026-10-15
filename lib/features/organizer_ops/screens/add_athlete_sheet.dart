import 'dart:async';

import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/add_athlete_candidate.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddAthleteSheet extends ConsumerStatefulWidget {
  const AddAthleteSheet({
    super.key,
    required this.tournament,
    required this.divisionId,
    required this.divisionName,
    required this.divisionEntryFee,
    required this.effectiveEntryFee,
    required this.participants,
    required this.onRefresh,
  });

  final Tournament tournament;
  final String divisionId;
  final String divisionName;
  final double? divisionEntryFee;
  final double? effectiveEntryFee;
  final List<OrganizerOpsParticipant> participants;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<AddAthleteSheet> createState() => _AddAthleteSheetState();
}

class _AddAthleteSheetState extends ConsumerState<AddAthleteSheet> {
  static const _directNameMax = 255;
  static const _searchDebounce = Duration(milliseconds: 250);

  final _searchController = TextEditingController();
  final _directNameController = TextEditingController();
  final _footballTeams = <OrganizerOpsParticipant>[];
  final _candidates = <_SourcedCandidate>[];
  String? _selectedCandidateId;

  late final bool _isFootball;
  late final bool _canAutoApprove;
  _AddAthleteTab _activeTab = _AddAthleteTab.accounts;
  String _query = '';
  String? _selectedTeamParticipantId;
  String? _candidateError;
  String? _directError;
  Timer? _searchTimer;
  int _candidateRequestVersion = 0;
  bool _loadingCandidates = false;
  bool _mutationInFlight = false;
  bool _refreshing = false;
  bool _staleNotice = false;
  bool _requiresRefresh = false;

  @override
  void initState() {
    super.initState();
    final rules = widget.tournament.sportRules;
    final scoring = rules?['scoring'];
    _isFootball =
        rules?['kind'] == 'FOOTBALL' ||
        (scoring is Map && scoring['kind'] == 'FOOTBALL');
    final effectiveFee =
        widget.effectiveEntryFee ??
        widget.divisionEntryFee ??
        widget.tournament.entryFee ??
        0;
    _canAutoApprove =
        widget.tournament.rawStatus == 'REGISTRATION_OPEN' && effectiveFee <= 0;
    _footballTeams.addAll(
      widget.participants.where(
        (participant) => participant.footballTeamId?.isNotEmpty == true,
      ),
    );
    if (!_isFootball) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadCandidates('', null));
      });
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _candidateRequestVersion++;
    _searchController.dispose();
    _directNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_mutationInFlight,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SizedBox.expand(
                  child: Material(
                    key: const ValueKey('add-athlete-sheet'),
                    color: colors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                const SizedBox(height: 18),
                                _buildHeader(context, l10n),
                                if (_isFootball) ...[
                                  const SizedBox(height: 20),
                                  _buildTeamPicker(context, l10n),
                                ],
                                const SizedBox(height: 18),
                                _buildTabs(context, l10n),
                                if (_staleNotice) ...[
                                  const SizedBox(height: 12),
                                  _buildStaleNotice(context, l10n),
                                ],
                                const SizedBox(height: 16),
                                if (_activeTab == _AddAthleteTab.accounts)
                                  _buildAccountContent(context, l10n)
                                else
                                  _buildDirectEntry(context, l10n),
                              ],
                            ),
                          ),
                        ),
                        if (_activeTab == _AddAthleteTab.accounts)
                          _buildCandidateFooter(context, l10n),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.person_add_alt_1_rounded, color: colors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.opsAddAthleteTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.opsAddAthleteDescription,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.tournament.name} · ${widget.divisionName}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: const ValueKey('add-athlete-close'),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: _mutationInFlight
              ? null
              : () => unawaited(Navigator.of(context).maybePop()),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _buildTeamPicker(BuildContext context, AppLocalizations l10n) {
    if (_footballTeams.isEmpty) {
      return Text(
        l10n.opsAddAthleteNoTeams,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    return DropdownButtonFormField<String>(
      key: const ValueKey('add-athlete-team'),
      initialValue: _selectedTeamParticipantId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.opsAddAthleteTeam,
        border: const OutlineInputBorder(),
      ),
      hint: Text(l10n.opsAddAthleteSelectTeam),
      items: _footballTeams
          .map(
            (team) => DropdownMenuItem<String>(
              value: team.id,
              child: Text(team.teamName, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: _mutationInFlight || _requiresRefresh
          ? null
          : _selectFootballTeam,
    );
  }

  Widget _buildTabs(BuildContext context, AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(l10n.opsAddAthleteAccounts),
          selected: _activeTab == _AddAthleteTab.accounts,
          onSelected: (_) => _selectTab(_AddAthleteTab.accounts),
        ),
        if (!_isFootball)
          ChoiceChip(
            label: Text(l10n.opsAddAthleteDirect),
            selected: _activeTab == _AddAthleteTab.direct,
            onSelected: (_) => _selectTab(_AddAthleteTab.direct),
          ),
      ],
    );
  }

  Widget _buildStaleNotice(BuildContext context, AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _requiresRefresh
                  ? l10n.opsAddAthleteRefreshFailed
                  : l10n.opsAddAthleteOutcomeUnknown,
              style: TextStyle(color: colors.onTertiaryContainer),
            ),
          ),
          if (_requiresRefresh)
            TextButton(
              onPressed: _refreshing ? null : _refreshAfterUncertainOutcome,
              child: _refreshing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.opsAddAthleteRefresh),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountContent(BuildContext context, AppLocalizations l10n) {
    final isTeamMissing = _isFootball && _selectedTeamParticipantId == null;
    final query = _query.trim();
    final needsNameSearchHint =
        query.contains('@') || (query.isNotEmpty && query.length < 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('add-athlete-search'),
          controller: _searchController,
          enabled:
              !_mutationInFlight &&
              !_requiresRefresh &&
              !_refreshing &&
              !isTeamMissing,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            labelText: l10n.opsAddAthleteSearch,
            border: const OutlineInputBorder(),
          ),
        ),
        if (isTeamMissing) ...[
          const SizedBox(height: 8),
          Text(l10n.opsAddAthleteTeamRequired),
        ],
        if (_candidateError != null) ...[
          const SizedBox(height: 12),
          Text(
            _candidateError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_loadingCandidates) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(l10n.opsAddAthleteLoading),
        ] else if (!isTeamMissing && _candidateError == null) ...[
          const SizedBox(height: 12),
          if (needsNameSearchHint)
            Text(l10n.opsAddAthleteSearchNameHint)
          else if (_candidates.isEmpty)
            Text(
              query.isEmpty
                  ? l10n.opsAddAthleteNoCandidates
                  : l10n.opsAddAthleteEmpty,
            )
          else
            ..._candidates.map(
              (candidate) => _buildCandidateCard(context, l10n, candidate),
            ),
        ],
      ],
    );
  }

  Widget _buildCandidateCard(
    BuildContext context,
    AppLocalizations l10n,
    _SourcedCandidate entry,
  ) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = _selectedCandidateId == entry.candidate.userId;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: isSelected ? colors.secondaryContainer : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey(
          'add-athlete-candidate-select-${entry.candidate.userId}',
        ),
        onTap: _canSubmit
            ? () => setState(() {
                _selectedCandidateId = isSelected
                    ? null
                    : entry.candidate.userId;
              })
            : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.surface,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.candidate.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final source in entry.sources)
                            Text(
                              source == AddAthleteSource.friends
                                  ? l10n.opsAddAthleteFriends
                                  : l10n.opsAddAthleteClub,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? colors.primary : colors.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildCandidateFooter(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final colors = Theme.of(context).colorScheme;
    final candidate = _selectedCandidate;
    final enabled =
        _canSubmit && (!_isFootball || _selectedTeamParticipantId != null);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: _isFootball
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('add-athlete-candidate-main'),
                    onPressed: candidate == null || !enabled
                        ? null
                        : () => unawaited(
                            _submitCandidate(
                              candidate,
                              role: FootballRosterRole.main,
                            ),
                          ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: _mutationInFlight
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.opsAddAthleteMain),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('add-athlete-candidate-reserve'),
                    onPressed: candidate == null || !enabled
                        ? null
                        : () => unawaited(
                            _submitCandidate(
                              candidate,
                              role: FootballRosterRole.reserve,
                            ),
                          ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: Text(l10n.opsAddAthleteReserve),
                  ),
                ),
              ],
            )
          : FilledButton.icon(
              key: const ValueKey('add-athlete-candidate-submit'),
              onPressed: candidate == null || !enabled
                  ? null
                  : () => unawaited(_submitCandidate(candidate)),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              icon: _mutationInFlight
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded),
              label: Text(l10n.opsAddAthleteAddAction),
            ),
    );
  }

  Widget _buildDirectEntry(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('add-athlete-direct-name'),
          controller: _directNameController,
          enabled: !_mutationInFlight && !_requiresRefresh && !_refreshing,
          textInputAction: TextInputAction.done,
          onChanged: (value) {
            setState(() {
              _directError = value.length > _directNameMax
                  ? l10n.opsAddAthleteNameTooLong
                  : null;
            });
          },
          onSubmitted: (_) => unawaited(_submitDirectName()),
          decoration: InputDecoration(
            labelText: l10n.opsAddAthleteName,
            border: const OutlineInputBorder(),
            counterText: '${_directNameController.text.length}/$_directNameMax',
            errorText: _directError,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('add-athlete-direct-submit'),
          onPressed: _canSubmit ? () => unawaited(_submitDirectName()) : null,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: Text(l10n.opsAddAthlete),
        ),
      ],
    );
  }

  bool get _canSubmit =>
      !_mutationInFlight && !_refreshing && !_requiresRefresh;
  _SourcedCandidate? get _selectedCandidate {
    final selectedId = _selectedCandidateId;
    if (selectedId == null) return null;
    for (final candidate in _candidates) {
      if (candidate.candidate.userId == selectedId) return candidate;
    }
    return null;
  }

  void _selectFootballTeam(String? participantId) {
    _searchTimer?.cancel();
    setState(() {
      _selectedTeamParticipantId = participantId;
      _selectedCandidateId = null;
      _candidateError = null;
      _candidates.clear();
      _loadingCandidates = participantId != null;
    });
    if (participantId != null) {
      unawaited(_loadCandidates(_query, participantId));
    } else {
      _candidateRequestVersion++;
    }
  }

  void _selectTab(_AddAthleteTab tab) {
    if (tab == _activeTab || _mutationInFlight || _requiresRefresh) return;
    _searchTimer?.cancel();
    _candidateRequestVersion++;
    setState(() {
      _activeTab = tab;
      _candidateError = null;
      _candidates.clear();
      _selectedCandidateId = null;
      _loadingCandidates =
          tab == _AddAthleteTab.accounts &&
          (!_isFootball || _selectedTeamParticipantId != null);
      _directError = null;
    });
    if (tab == _AddAthleteTab.accounts &&
        (!_isFootball || _selectedTeamParticipantId != null)) {
      unawaited(_loadCandidates(_query, _selectedTeamParticipantId));
    }
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _candidateRequestVersion++;
    final query = value.trim();
    final canSearch =
        query.isEmpty || (!query.contains('@') && query.length >= 2);
    setState(() {
      _query = value;
      _candidateError = null;
      _selectedCandidateId = null;
      _candidates.clear();
      _staleNotice = false;
      _loadingCandidates = canSearch;
    });
    if (!canSearch) return;
    _searchTimer = Timer(_searchDebounce, () {
      unawaited(_loadCandidates(value, _selectedTeamParticipantId));
    });
  }

  Future<void> _loadCandidates(String query, String? participantId) async {
    final requestVersion = ++_candidateRequestVersion;
    final normalizedQuery = query.trim();
    if (normalizedQuery.isNotEmpty &&
        (normalizedQuery.contains('@') || normalizedQuery.length < 2)) {
      if (mounted && requestVersion == _candidateRequestVersion) {
        setState(() {
          _candidates.clear();
          _selectedCandidateId = null;
          _candidateError = null;
          _loadingCandidates = false;
        });
      }
      return;
    }
    if (_isFootball && (participantId == null || participantId.isEmpty)) {
      if (mounted) {
        setState(() {
          _candidates.clear();
          _selectedCandidateId = null;
          _candidateError = null;
          _loadingCandidates = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loadingCandidates = true;
        _candidateError = null;
        _selectedCandidateId = null;
      });
    }
    final l10n = AppLocalizations.of(context)!;
    try {
      final sources = AddAthleteSource.values;
      final sourceLists = await Future.wait(
        sources.map(
          (source) => ref
              .read(tournamentManagementRepositoryProvider)
              .listAddAthleteCandidates(
                widget.tournament.id,
                source: source,
                query: normalizedQuery,
                participantId: _isFootball ? participantId : null,
              ),
        ),
      );
      if (!mounted || requestVersion != _candidateRequestVersion) return;
      final merged = <String, _SourcedCandidate>{};
      for (var sourceIndex = 0; sourceIndex < sources.length; sourceIndex++) {
        for (final candidate in sourceLists[sourceIndex]) {
          final entry = merged.putIfAbsent(
            candidate.userId,
            () => _SourcedCandidate(candidate: candidate),
          );
          entry.sources.add(sources[sourceIndex]);
        }
      }
      setState(() {
        _candidates
          ..clear()
          ..addAll(merged.values);
        _loadingCandidates = false;
      });
    } catch (error) {
      if (!mounted || requestVersion != _candidateRequestVersion) return;
      setState(() {
        _candidates.clear();
        _candidateError = ErrorParser.parse(
          error,
          l10n.opsAddAthleteFailed,
          l10n,
        );
        _loadingCandidates = false;
      });
    }
  }

  Future<void> _submitCandidate(
    _SourcedCandidate entry, {
    FootballRosterRole? role,
  }) async {
    if (!_canSubmit) return;
    if (_isFootball && (_selectedTeamParticipantId == null || role == null)) {
      return;
    }
    setState(() => _mutationInFlight = true);
    try {
      final participantId = await ref
          .read(tournamentManagementRepositoryProvider)
          .addAthleteCandidate(
            widget.tournament.id,
            source: entry.sources.first,
            userId: entry.candidate.userId,
            tournamentDivisionId: _isFootball ? null : widget.divisionId,
            participantId: _isFootball ? _selectedTeamParticipantId : null,
            role: role,
          );
      await _finishSuccessfulAdd(participantId);
      if (mounted && !_isFootball) {
        await _loadCandidates(_query, null);
      } else if (mounted && _selectedTeamParticipantId != null) {
        await _loadCandidates(_query, _selectedTeamParticipantId);
      }
    } catch (error) {
      await _handleUncertainFailure(error);
    } finally {
      if (mounted) {
        setState(() {
          _mutationInFlight = false;
          _selectedCandidateId = null;
        });
      }
    }
  }

  Future<void> _submitDirectName() async {
    if (!_canSubmit) return;
    final l10n = AppLocalizations.of(context)!;
    final name = _directNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _directError = l10n.opsAddAthleteNameRequired);
      return;
    }
    if (name.length > _directNameMax) {
      setState(() => _directError = l10n.opsAddAthleteNameTooLong);
      return;
    }

    setState(() {
      _mutationInFlight = true;
      _directError = null;
    });
    try {
      final participantId = await ref
          .read(tournamentManagementRepositoryProvider)
          .addAthleteDirect(
            widget.tournament.id,
            name: name,
            tournamentDivisionId: widget.divisionId,
          );
      _directNameController.clear();
      await _finishSuccessfulAdd(participantId);
    } catch (error) {
      await _handleUncertainFailure(error);
    } finally {
      if (mounted) setState(() => _mutationInFlight = false);
    }
  }

  Future<void> _finishSuccessfulAdd(String participantId) async {
    final l10n = AppLocalizations.of(context)!;
    final approvalFailed = await _tryAutoApprove(participantId);
    final refreshed = await _tryRefreshRoster();
    if (!mounted) return;
    setState(() {
      _staleNotice = !refreshed;
      _requiresRefresh = !refreshed;
    });
    _showMessage(
      approvalFailed
          ? l10n.opsAddAthleteApprovalFailed
          : refreshed
          ? l10n.opsAddAthleteSuccess
          : l10n.opsAddAthleteRefreshFailed,
    );
  }

  Future<bool> _tryAutoApprove(String participantId) async {
    if (!_canAutoApprove || _isFootball) return false;
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .updateParticipantStatus(
            widget.tournament.id,
            participantId,
            'COMPLETE',
          );
      return false;
    } catch (_) {
      return true;
    }
  }

  Future<void> _handleUncertainFailure(Object error) async {
    if (mounted) {
      setState(() {
        _staleNotice = true;
        _requiresRefresh = true;
      });
    }
    final refreshed = await _tryRefreshRoster();
    if (!mounted) return;
    setState(() => _requiresRefresh = !refreshed);
    if (refreshed) {
      final l10n = AppLocalizations.of(context)!;
      _showMessage(ErrorParser.parse(error, l10n.opsAddAthleteFailed, l10n));
      if (_activeTab == _AddAthleteTab.accounts) {
        await _loadCandidates(_query, _selectedTeamParticipantId);
      }
    } else {
      _showMessage(AppLocalizations.of(context)!.opsAddAthleteRefreshFailed);
    }
  }

  Future<void> _refreshAfterUncertainOutcome() async {
    if (_refreshing || _mutationInFlight) return;
    setState(() => _refreshing = true);
    final refreshed = await _tryRefreshRoster();
    if (!mounted) return;
    setState(() => _requiresRefresh = !refreshed);
    if (refreshed && _activeTab == _AddAthleteTab.accounts) {
      await _loadCandidates(_query, _selectedTeamParticipantId);
    }
    if (mounted) setState(() => _refreshing = false);
  }

  Future<bool> _tryRefreshRoster() async {
    try {
      await widget.onRefresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _AddAthleteTab { accounts, direct }

class _SourcedCandidate {
  _SourcedCandidate({required this.candidate});

  final AddAthleteCandidate candidate;
  final Set<AddAthleteSource> sources = {};
}
