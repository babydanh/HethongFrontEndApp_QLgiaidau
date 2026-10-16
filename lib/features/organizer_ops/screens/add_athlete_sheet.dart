import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
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
    required this.divisionMatchType,
    required this.divisionEntryFee,
    required this.effectiveEntryFee,
    required this.participants,
    required this.onRefresh,
  });

  final Tournament tournament;
  final String divisionId;
  final String divisionName;
  /// matchType của division (SINGLES, DOUBLES, MIXED_DOUBLES...); null = không bật ghép cặp.
  final String? divisionMatchType;
  final double? divisionEntryFee;
  final double? effectiveEntryFee;
  final List<OrganizerOpsParticipant> participants;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<AddAthleteSheet> createState() => _AddAthleteSheetState();
}

class _AddAthleteSheetState extends ConsumerState<AddAthleteSheet> {
  static const _directNameMax = 255;
  static const _directEmailMax = 254;
  static const _candidateLimit = 25;
  static const _searchDebounce = Duration(milliseconds: 250);
  static const _pairSourceOrder = [
    AddAthleteSource.friends,
    AddAthleteSource.club,
    AddAthleteSource.email,
  ];

  final _searchController = TextEditingController();
  final _directNameController = TextEditingController();
  final _directEmailController = TextEditingController();
  final _footballTeams = <OrganizerOpsParticipant>[];
  // Kết quả tìm theo tên (bạn bè + CLB), đã gộp theo userId.
  final _candidates = <_SourcedCandidate>[];
  // Kết quả tìm theo email; null khi chưa có kết quả cho truy vấn hiện tại.
  List<_SourcedCandidate>? _emailResults;
  // Danh sách đang chọn, giữ thứ tự bấm (quyết định nhãn cặp).
  final _selected = <_SourcedCandidate>[];
  // userId đã thêm thành công trong phiên mở sheet.
  final _addedUserIds = <String>{};
  // userId đang được xử lý, để hiện spinner đúng dòng.
  final _pendingUserIds = <String>{};

  late final bool _isFootball;
  late final bool _canAutoApprove;
  late final bool _canUsePairMode;
  _AddAthleteTab _activeTab = _AddAthleteTab.accounts;
  bool _pairMode = false;
  String _query = '';
  String? _loadedCandidateQuery;
  String? _selectedTeamParticipantId;
  String? _candidateError;
  String? _emailError;
  String? _directError;
  String? _batchSummary;
  Timer? _searchTimer;
  int _candidateRequestVersion = 0;
  int _emailRequestVersion = 0;
  bool _loadingCandidates = false;
  bool _searchingEmail = false;
  bool _mutationInFlight = false;
  bool _refreshing = false;
  bool _staleNotice = false;
  bool _requiresRefresh = false;

  bool get _canSubmit =>
      !_mutationInFlight && !_refreshing && !_requiresRefresh;
  bool get _isEmailQuery => _query.trim().contains('@');
  bool get _pairingActive => _canUsePairMode && _pairMode;

  /// Nguồn chung của mọi VĐV đang chọn; null nếu không có nguồn nào chung.
  AddAthleteSource? get _pairSource {
    if (!_pairingActive) return null;
    for (final source in _pairSourceOrder) {
      if (_selected.every((entry) => entry.sources.contains(source))) {
        return source;
      }
    }
    return null;
  }

  bool get _pairSelectionReady => _pairSource != null && _selected.length >= 2;

  bool get _submitDisabled {
    if (!_canSubmit) return true;
    return _pairingActive ? !_pairSelectionReady : _selected.isEmpty;
  }

  @override
  void initState() {
    super.initState();
    final rules = widget.tournament.sportRules;
    final scoring = rules?['scoring'];
    _isFootball =
        rules?['kind'] == 'FOOTBALL' ||
        (scoring is Map && scoring['kind'] == 'FOOTBALL');
    final matchType = widget.divisionMatchType?.trim().toUpperCase();
    _canUsePairMode =
        !_isFootball && (matchType == 'DOUBLES' || matchType == 'MIXED_DOUBLES');
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
        if (mounted) unawaited(_loadCandidates(''));
      });
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _candidateRequestVersion++;
    _emailRequestVersion++;
    _searchController.dispose();
    _directNameController.dispose();
    _directEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
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
                    color: colors.bgCard,
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
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.opsAddAthleteTitle,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.opsAddAthleteDescription,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.tournament.name} · ${widget.divisionName}',
                style: textTheme.labelMedium?.copyWith(
                  color: colors.textMuted,
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
    final colors = context.colors;
    if (_footballTeams.isEmpty) {
      return Text(
        l10n.opsAddAthleteNoTeams,
        style: TextStyle(color: colors.error),
      );
    }
    return DropdownButtonFormField<String>(
      key: const ValueKey('add-athlete-team'),
      initialValue: _selectedTeamParticipantId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.opsAddAthleteTeam,
        border: const OutlineInputBorder(),
        hint: Text(l10n.opsAddAthleteSelectTeam),
      ),
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
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _requiresRefresh
                  ? l10n.opsAddAthleteRefreshFailed
                  : l10n.opsAddAthleteOutcomeUnknown,
              style: TextStyle(color: colors.textPrimary),
            ),
          ),
          if (_requiresRefresh)
            TextButton(
              onPressed: _refreshing
                  ? null
                  : () => unawaited(_refreshAfterUncertainOutcome()),
              child: _refreshing ? _spinner() : Text(l10n.opsAddAthleteRefresh),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountContent(BuildContext context, AppLocalizations l10n) {
    final colors = context.colors;
    final isTeamMissing = _isFootball && _selectedTeamParticipantId == null;
    final query = _query.trim();
    final emailMode = _isEmailQuery;
    final searchable = _searchModeFor(query) != _SearchMode.none;
    final visible = emailMode
        ? (_emailResults ?? const <_SourcedCandidate>[])
        : _candidates;
    final error = emailMode ? _emailError : _candidateError;
    final loading = emailMode ? _searchingEmail : _loadingCandidates;
    final showResults = emailMode
        ? _emailResults != null
        : _loadedCandidateQuery == query && searchable;
    final selectedIds = {for (final entry in _selected) entry.candidate.userId};
    final resultRows = showResults
        ? visible
              .where((entry) => !selectedIds.contains(entry.candidate.userId))
              .toList(growable: false)
        : const <_SourcedCandidate>[];
    final rows = [..._selected, ...resultRows];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('add-athlete-search'),
          controller: _searchController,
          enabled: _canSubmit && !isTeamMissing,
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
          Text(
            l10n.opsAddAthleteTeamRequired,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
        if (!isTeamMissing && query.isNotEmpty && !searchable) ...[
          const SizedBox(height: 8),
          Text(
            l10n.opsAddAthleteSearchHint,
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
        ],
        if (_canUsePairMode) ...[
          const SizedBox(height: 8),
          SwitchListTile(
            key: const ValueKey('add-athlete-pair-toggle'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.opsAddAthletePairToggle),
            value: _pairMode,
            onChanged: _mutationInFlight
                ? null
                : (value) => setState(() {
                    _batchSummary = null;
                    _pairMode = value;
                  }),
          ),
          if (_pairingActive && !_pairSelectionReady)
            Text(
              l10n.opsAddAthletePairRequirement,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
        ],
        if (_selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.opsAddAthleteSelectedCount(_selected.length),
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (_selected.length >= _candidateLimit) ...[
          const SizedBox(height: 4),
          Text(
            l10n.opsAddAthleteSelectionLimit,
            style: TextStyle(color: colors.error, fontSize: 12),
          ),
        ],
        if (_batchSummary != null) ...[
          const SizedBox(height: 8),
          Text(_batchSummary!, style: TextStyle(color: colors.textSecondary)),
        ],
        if (!isTeamMissing && error != null) ...[
          const SizedBox(height: 12),
          Text(error, style: TextStyle(color: colors.error)),
        ],
        if (!isTeamMissing && error == null && loading) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            l10n.opsAddAthleteLoading,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
        if (!isTeamMissing &&
            error == null &&
            !loading &&
            showResults &&
            visible.isEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              query.isEmpty
                  ? l10n.opsAddAthleteNoCandidates
                  : l10n.opsAddAthleteEmpty,
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
        ],
        if (!isTeamMissing)
          for (final entry in rows) _buildCandidateRow(context, l10n, entry),
      ],
    );
  }

  Widget _buildCandidateRow(
    BuildContext context,
    AppLocalizations l10n,
    _SourcedCandidate entry,
  ) {
    final colors = context.colors;
    final userId = entry.candidate.userId;
    final isSelected = _selected.any((item) => item.candidate.userId == userId);
    final isAdded = _addedUserIds.contains(userId);
    final disabled =
        _mutationInFlight ||
        isAdded ||
        (!isSelected && _selected.length >= _candidateLimit);
    final isPending = _pendingUserIds.contains(userId);
    final pairBadge = _pairBadge(context, l10n, userId);
    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: isSelected ? colors.bgElevated : colors.bgCard,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('add-athlete-candidate-select-$userId'),
        onTap: disabled ? null : () => _toggleCandidate(entry),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.bgSurface,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.primary,
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
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final source in entry.sources)
                            Text(
                              _sourceLabel(l10n, source),
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (pairBadge != null) ...[const SizedBox(width: 8), pairBadge],
                if (isPending) ...[
                  const SizedBox(width: 8),
                  _spinner(),
                ],
                if (isAdded) ...[
                  const SizedBox(width: 8),
                  Text(
                    l10n.opsAddAthleteAdded,
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                ],
                const SizedBox(width: 8),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? AppTheme.primary : colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _pairBadge(
    BuildContext context,
    AppLocalizations l10n,
    String userId,
  ) {
    if (!_pairingActive) return null;
    final index = _selected.indexWhere(
      (item) => item.candidate.userId == userId,
    );
    if (index < 0) return null;
    final colors = context.colors;
    final isWaiting = index == _selected.length - 1 && index.isEven;
    final label = isWaiting
        ? l10n.opsAddAthletePairWaiting
        : l10n.opsAddAthletePairGroup(String.fromCharCode(65 + index ~/ 2));
    final accent = isWaiting ? colors.warning : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  String _sourceLabel(AppLocalizations l10n, AddAthleteSource source) {
    return switch (source) {
      AddAthleteSource.friends => l10n.opsAddAthleteFriends,
      AddAthleteSource.club => l10n.opsAddAthleteClub,
      AddAthleteSource.email => l10n.opsAddAthleteEmail,
    };
  }

  Widget _buildCandidateFooter(BuildContext context, AppLocalizations l10n) {
    final colors = context.colors;
    final Widget actions;
    if (_isFootball) {
      final teamReady =
          _canSubmit && _selectedTeamParticipantId != null && _selected.isNotEmpty;
      actions = Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              key: const ValueKey('add-athlete-candidate-main'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: teamReady
                  ? () => unawaited(
                      _submitSelected(role: FootballRosterRole.main),
                    )
                  : null,
              icon: _mutationInFlight
                  ? _spinner()
                  : const Icon(Icons.check_rounded),
              label: Text(l10n.opsAddAthleteMain),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              key: const ValueKey('add-athlete-candidate-reserve'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: teamReady
                  ? () => unawaited(
                      _submitSelected(role: FootballRosterRole.reserve),
                    )
                  : null,
              child: Text(l10n.opsAddAthleteReserve),
            ),
          ),
        ],
      );
    } else {
      final count = _selected.length;
      actions = FilledButton.icon(
        key: const ValueKey('add-athlete-candidate-submit'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
        onPressed: _submitDisabled
            ? null
            : () => unawaited(
                _pairingActive ? _submitPairs() : _submitSelected(),
              ),
        icon: _mutationInFlight
            ? _spinner()
            : const Icon(Icons.person_add_alt_1_rounded),
        label: Text(
          _pairingActive
              ? l10n.opsAddAthletePairSubmit
              : count > 0
              ? l10n.opsAddAthleteAddSelectedCount(count)
              : l10n.opsAddAthleteAddAction,
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: actions,
    );
  }

  Widget _buildDirectEntry(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('add-athlete-direct-name'),
          controller: _directNameController,
          enabled: _canSubmit,
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            setState(() {
              _directError = value.length > _directNameMax
                  ? l10n.opsAddAthleteNameTooLong
                  : null;
            });
          },
          decoration: InputDecoration(
            labelText: l10n.opsAddAthleteName,
            border: const OutlineInputBorder(),
            counterText: '${_directNameController.text.length}/$_directNameMax',
            errorText: _directError,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('add-athlete-direct-email'),
          controller: _directEmailController,
          enabled: _canSubmit,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          maxLength: _directEmailMax,
          onSubmitted: (_) => unawaited(_submitGuest()),
          decoration: InputDecoration(
            labelText: l10n.opsAddAthleteGuestEmail,
            helperText: l10n.opsAddAthleteGuestEmailHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('add-athlete-direct-submit'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
          onPressed: _canSubmit ? () => unawaited(_submitGuest()) : null,
          icon: _mutationInFlight
              ? _spinner()
              : const Icon(Icons.person_add_alt_1_rounded),
          label: Text(l10n.opsAddAthlete),
        ),
      ],
    );
  }

  Widget _spinner() {
    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  void _selectTab(_AddAthleteTab tab) {
    if (tab == _activeTab || _mutationInFlight || _requiresRefresh) return;
    _searchTimer?.cancel();
    _candidateRequestVersion++;
    _emailRequestVersion++;
    setState(() {
      _activeTab = tab;
      _candidateError = null;
      _emailError = null;
      _candidates.clear();
      _emailResults = null;
      _loadedCandidateQuery = null;
      _selected.clear();
      _batchSummary = null;
      _loadingCandidates = false;
      _searchingEmail = false;
      _directError = null;
    });
    if (tab == _AddAthleteTab.accounts &&
        (!_isFootball || _selectedTeamParticipantId != null)) {
      _runSearchNow(_query.trim());
    }
  }

  void _selectFootballTeam(String? participantId) {
    if (_mutationInFlight || _requiresRefresh) return;
    _searchTimer?.cancel();
    _candidateRequestVersion++;
    _emailRequestVersion++;
    setState(() {
      _selectedTeamParticipantId = participantId;
      _selected.clear();
      _candidates.clear();
      _emailResults = null;
      _loadedCandidateQuery = null;
      _candidateError = null;
      _emailError = null;
      _batchSummary = null;
      _staleNotice = false;
      _loadingCandidates = false;
      _searchingEmail = false;
    });
    if (participantId != null) _runSearchNow(_query.trim());
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _candidateRequestVersion++;
    _emailRequestVersion++;
    final query = value.trim();
    final mode = _searchModeFor(query);
    setState(() {
      _query = value;
      _candidateError = null;
      _emailError = null;
      _candidates.clear();
      _emailResults = null;
      _loadedCandidateQuery = null;
      _staleNotice = false;
      _loadingCandidates = mode == _SearchMode.names;
      _searchingEmail = mode == _SearchMode.email;
    });
    if (mode == _SearchMode.none) return;
    _searchTimer = Timer(_searchDebounce, () {
      if (mounted) _runSearchNow(query);
    });
  }

  void _runSearchNow(String query) {
    final mode = _searchModeFor(query);
    if (mode == _SearchMode.names) {
      unawaited(_loadCandidates(query));
    } else if (mode == _SearchMode.email) {
      unawaited(_searchEmail(query));
    }
  }

  void _toggleCandidate(_SourcedCandidate entry) {
    final userId = entry.candidate.userId;
    final index = _selected.indexWhere(
      (item) => item.candidate.userId == userId,
    );
    setState(() {
      _batchSummary = null;
      if (index >= 0) {
        _selected.removeAt(index);
      } else if (_selected.length < _candidateLimit) {
        _selected.add(entry);
      }
    });
  }

  Future<void> _loadCandidates(String query) async {
    final requestVersion = ++_candidateRequestVersion;
    final participantId = _selectedTeamParticipantId;
    if (_isFootball && (participantId == null || participantId.isEmpty)) {
      if (mounted) {
        setState(() {
          _candidates.clear();
          _loadedCandidateQuery = null;
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
      });
    }
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(tournamentManagementRepositoryProvider);
    const sources = [AddAthleteSource.friends, AddAthleteSource.club];
    try {
      final sourceLists = await Future.wait(
        sources.map(
          (source) => repository.listAddAthleteCandidates(
            widget.tournament.id,
            source: source,
            query: query,
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
        _loadedCandidateQuery = query;
        _loadingCandidates = false;
      });
    } catch (error) {
      if (!mounted || requestVersion != _candidateRequestVersion) return;
      setState(() {
        _candidates.clear();
        _loadedCandidateQuery = null;
        _candidateError = ErrorParser.parse(
          error,
          l10n.opsAddAthleteFailed,
          l10n,
        );
        _loadingCandidates = false;
      });
    }
  }

  Future<void> _searchEmail(String email) async {
    final participantId = _selectedTeamParticipantId;
    if (_isFootball && (participantId == null || participantId.isEmpty)) {
      return;
    }
    final requestVersion = ++_emailRequestVersion;
    final l10n = AppLocalizations.of(context)!;
    if (mounted) {
      setState(() {
        _searchingEmail = true;
        _emailError = null;
        _emailResults = null;
      });
    }
    try {
      final items = await ref
          .read(tournamentManagementRepositoryProvider)
          .searchAddAthleteCandidates(
            widget.tournament.id,
            email: email,
            participantId: _isFootball ? participantId : null,
          );
      if (!mounted || requestVersion != _emailRequestVersion) return;
      final mapped = items.map(_entryFromSearch).toList(growable: false);
      setState(() {
        if (mapped.any((entry) => entry == null)) {
          _emailResults = null;
          _emailError = l10n.opsAddAthleteSearchFailed;
        } else {
          _emailResults = mapped
              .whereType<_SourcedCandidate>()
              .toList(growable: false);
        }
      });
    } catch (error) {
      if (!mounted || requestVersion != _emailRequestVersion) return;
      setState(() {
        _emailResults = null;
        _emailError = ErrorParser.parse(
          error,
          l10n.opsAddAthleteSearchFailed,
          l10n,
        );
      });
    } finally {
      if (mounted && requestVersion == _emailRequestVersion) {
        setState(() => _searchingEmail = false);
      }
    }
  }

  _SourcedCandidate? _entryFromSearch(AddAthleteSearchCandidate item) {
    if (item.sources.isEmpty) return null;
    final entry = _SourcedCandidate(
      candidate: AddAthleteCandidate(
        userId: item.userId,
        fullName: item.fullName,
      ),
    );
    entry.sources.addAll(item.sources);
    return entry;
  }

  Future<void> _reloadAfterMutation({required bool failed}) async {
    final query = _query.trim();
    if (query.contains('@')) {
      if (failed && mounted) setState(() => _emailResults = null);
      return;
    }
    if (_searchModeFor(query) == _SearchMode.names) {
      await _loadCandidates(query);
    }
  }

  Future<void> _submitSelected({FootballRosterRole? role}) async {
    if (!_canSubmit || _selected.isEmpty) return;
    if (_isFootball && (_selectedTeamParticipantId == null || role == null)) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(tournamentManagementRepositoryProvider);
    final selection = List<_SourcedCandidate>.of(_selected);
    setState(() {
      _mutationInFlight = true;
      _staleNotice = false;
      _batchSummary = null;
      _pendingUserIds
        ..clear()
        ..addAll(selection.map((entry) => entry.candidate.userId));
    });
    var addedCount = 0;
    var approvalFailureCount = 0;
    var failedIndex = -1;
    Object? failure;
    try {
      // Thêm tuần tự như web: dừng ở lỗi đầu tiên, các VĐV sau đó chưa được thử.
      for (var index = 0; index < selection.length; index++) {
        final entry = selection[index];
        final userId = entry.candidate.userId;
        try {
          final participantId = await repository.addAthleteCandidate(
            widget.tournament.id,
            source: entry.sources.first,
            userId: userId,
            tournamentDivisionId: _isFootball ? null : widget.divisionId,
            participantId: _isFootball ? _selectedTeamParticipantId : null,
            role: role,
          );
          addedCount++;
          if (mounted) {
            setState(() {
              _addedUserIds.add(userId);
              _selected.removeWhere((item) => item.candidate.userId == userId);
              _pendingUserIds.remove(userId);
            });
          }
          if (await _tryAutoApprove(participantId)) approvalFailureCount++;
        } catch (error) {
          failure = error;
          failedIndex = index;
          break;
        }
      }
      if (!mounted) return;
      final failedError = failure;
      final messages = <String>[];
      if (failedError != null) {
        final unattempted = selection.length - failedIndex - 1;
        setState(() {
          _batchSummary = l10n.opsAddAthletePartialSummary(
            addedCount,
            1,
            unattempted,
          );
        });
        messages.add(
          ErrorParser.parse(failedError, l10n.opsAddAthleteFailed, l10n),
        );
      } else if (addedCount > 1) {
        messages.add(l10n.opsAddAthleteMultipleSuccess(addedCount));
      } else if (addedCount == 1) {
        messages.add(l10n.opsAddAthleteSuccess);
      }
      if (approvalFailureCount > 0) {
        messages.add(l10n.opsAddAthleteApprovalFailed);
      }
      if (addedCount > 0 || failedError != null) {
        final refreshed = await _tryRefreshRoster();
        if (!mounted) return;
        setState(() {
          _staleNotice = failedError != null || !refreshed;
          _requiresRefresh = !refreshed;
        });
      }
      if (messages.isNotEmpty) _showMessage(messages.join('\n'));
      await _reloadAfterMutation(failed: failedError != null);
    } finally {
      if (mounted) {
        setState(() {
          _mutationInFlight = false;
          _pendingUserIds.clear();
        });
      }
    }
  }

  Future<void> _submitPairs() async {
    final source = _pairSource;
    if (!_canSubmit || !_pairSelectionReady || source == null) return;
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(tournamentManagementRepositoryProvider);
    final userIds = _selected
        .map((entry) => entry.candidate.userId)
        .toList(growable: false);
    setState(() {
      _mutationInFlight = true;
      _staleNotice = false;
      _batchSummary = null;
      _pendingUserIds
        ..clear()
        ..addAll(userIds);
    });
    try {
      final pairs = await repository.addAthletePairs(
        widget.tournament.id,
        source: source,
        tournamentDivisionId: widget.divisionId,
        userIds: userIds,
      );
      final pendingCount = pairs.where((pair) => pair.isPendingPartner).length;
      final pairCount = pairs.length - pendingCount;
      if (!mounted) return;
      setState(() {
        _addedUserIds.addAll(userIds);
        _selected.clear();
      });
      _showMessage(l10n.opsAddAthletePairSuccess(pairCount, pendingCount));
      final refreshed = await _tryRefreshRoster();
      if (!mounted) return;
      setState(() {
        _staleNotice = !refreshed;
        _requiresRefresh = !refreshed;
      });
      await _reloadAfterMutation(failed: false);
    } catch (error) {
      await _handleUncertainFailure(error);
    } finally {
      if (mounted) {
        setState(() {
          _mutationInFlight = false;
          _pendingUserIds.clear();
        });
      }
    }
  }

  Future<void> _submitGuest() async {
    if (!_canSubmit) return;
    final l10n = AppLocalizations.of(context)!;
    final name = _directNameController.text.trim();
    final email = _directEmailController.text.trim();
    if (name.isEmpty && email.isEmpty) {
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
            name: name.isEmpty ? email.split('@').first : name,
            email: email.isEmpty ? null : email,
            tournamentDivisionId: widget.divisionId,
          );
      _directNameController.clear();
      _directEmailController.clear();
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
    final l10n = AppLocalizations.of(context)!;
    if (refreshed) {
      _showMessage(ErrorParser.parse(error, l10n.opsAddAthleteFailed, l10n));
      if (_activeTab == _AddAthleteTab.accounts) {
        await _reloadAfterMutation(failed: true);
      }
    } else {
      _showMessage(l10n.opsAddAthleteRefreshFailed);
    }
  }

  Future<void> _refreshAfterUncertainOutcome() async {
    if (_refreshing || _mutationInFlight) return;
    setState(() => _refreshing = true);
    final refreshed = await _tryRefreshRoster();
    if (!mounted) return;
    setState(() => _requiresRefresh = !refreshed);
    if (refreshed && _activeTab == _AddAthleteTab.accounts) {
      await _reloadAfterMutation(failed: false);
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

/// Chế độ tìm kiếm theo truy vấn; khớp quy tắc của AddAthleteModal web.
enum _SearchMode { none, names, email }

const _nameSearchMax = 100;

_SearchMode _searchModeFor(String query) {
  if (query.isEmpty) return _SearchMode.names;
  if (query.contains('@')) {
    return query.length >= 2 ? _SearchMode.email : _SearchMode.none;
  }
  return query.length >= 2 && query.length <= _nameSearchMax
      ? _SearchMode.names
      : _SearchMode.none;
}

class _SourcedCandidate {
  _SourcedCandidate({required this.candidate});

  final AddAthleteCandidate candidate;
  final Set<AddAthleteSource> sources = {};
}
