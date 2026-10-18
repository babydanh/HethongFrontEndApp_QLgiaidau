import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_stage_utils.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_camera_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/schedule_fullscreen_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_duration.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_actions.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_schedule_court_grid.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/add_athlete_sheet.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/match_schedule.dart';
import 'package:app_quanly_giaidau/providers/organizer_ops_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tab views a host can embed. Indexes match the standalone tab order.
enum OrganizerOpsView { overview, matches, bracket, roster, activity, camera }

/// Khung nhìn danh sách trận trong tab vận hành: lưới sân × giờ hoặc danh sách.
enum OrganizerOpsMatchesView { grid, list }

class OrganizerOpsScreen extends ConsumerStatefulWidget {
  const OrganizerOpsScreen({
    super.key,
    required this.tournamentId,
    this.initialDivisionId,
    this.view,
    this.onDivisionChanged,
    this.initialFocusMatchId,
    this.isEmbedded = false,
    this.overlapHandles = const [],
    this.initialMatchesView = OrganizerOpsMatchesView.list,
  });

  final String tournamentId;
  final String? initialDivisionId;
  final OrganizerOpsView? view;
  final ValueChanged<String?>? onDivisionChanged;
  final String? initialFocusMatchId;
  final bool isEmbedded;
  final List<SliverOverlapAbsorberHandle> overlapHandles;

  /// Hub quản lý truyền `grid` để vào tab là thấy lưới sân ngay.
  final OrganizerOpsMatchesView initialMatchesView;

  @override
  ConsumerState<OrganizerOpsScreen> createState() => _OrganizerOpsScreenState();
}

class _OrganizerOpsScreenState extends ConsumerState<OrganizerOpsScreen> {
  String? _selectedDivisionId;
  String _rosterFilter = 'ALL';
  String _rosterQuery = '';
  int _selectedTab = 1;
  String _opsMatchFilter = 'ongoing';
  String? _focusedMatchId;
  late OrganizerOpsMatchesView _matchesView;

  /// Bản nháp xếp tự động chờ áp dụng trên lưới; rỗng khi không có bản nháp.
  List<MatchModel> _draftMatches = const [];
  int _draftSkipped = 0;
  ({int done, int total})? _draftProgress;

  @override
  void initState() {
    super.initState();
    _selectedDivisionId = widget.initialDivisionId;
    _focusedMatchId = widget.initialFocusMatchId;
    if (_focusedMatchId != null) _opsMatchFilter = 'all';
    _selectedTab = widget.view?.index ?? OrganizerOpsView.matches.index;
    _matchesView = widget.initialMatchesView;
    // Lưới phải thấy cả trận chưa đấu để xếp lịch, nên mặc định "tất cả" khi
    // vào bằng lưới; người dùng vẫn đổi bộ lọc được như thường.
    if (_matchesView == OrganizerOpsMatchesView.grid) _opsMatchFilter = 'all';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return tournamentAsync.when(
      loading: () => _OpsScaffold(
        title: l10n.opsTitle,
        isEmbedded: widget.isEmbedded,
        onBack: () => _goBack(context),
        body: const _OpsLoadingBody(),
      ),
      error: (error, _) => _OpsScaffold(
        title: l10n.opsTitle,
        isEmbedded: widget.isEmbedded,
        onBack: () => _goBack(context),
        body: _OpsErrorBody(
          message:
              '${l10n.opsLoadFailed}\n${ErrorParser.parse(error, l10n.opsLoadFailed, l10n)}',
          onRetry: () =>
              ref.invalidate(tournamentProvider(widget.tournamentId)),
        ),
      ),
      data: (tournament) {
        if (tournament == null) {
          return _OpsScaffold(
            title: l10n.opsTitle,
            isEmbedded: widget.isEmbedded,
            onBack: () => _goBack(context),
            body: _OpsErrorBody(
              message: l10n.tournamentNotFound,
              onRetry: () =>
                  ref.invalidate(tournamentProvider(widget.tournamentId)),
            ),
          );
        }

        return _buildLoaded(context, l10n, tournament);
      },
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    AppLocalizations l10n,
    Tournament tournament,
  ) {
    final colors = context.colors;
    final isReadOnly = _isReadOnlyTournament(tournament.status);
    final divisionsAsync = ref.watch(
      tournamentDivisionsProvider(widget.tournamentId),
    );

    return _OpsScaffold(
      title: tournament.name,
      isEmbedded: widget.isEmbedded,
      subtitle: l10n.opsOrganizerOnly,
      onBack: () => _goBack(context),
      actions: [
        IconButton(
          tooltip: l10n.opsRefresh,
          onPressed: () {
            ref.invalidate(tournamentProvider(widget.tournamentId));
            ref.invalidate(tournamentDivisionsProvider(widget.tournamentId));
            if (_selectedDivisionId != null) {
              ref.invalidate(
                managedMatchesWithDivisionProvider((
                  tournamentId: widget.tournamentId,
                  divisionId: _selectedDivisionId,
                )),
              );
              ref.invalidate(
                organizerOpsReadModelProvider((
                  tournamentId: widget.tournamentId,
                  divisionId: _selectedDivisionId!,
                )),
              );
            }
          },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: divisionsAsync.when(
        loading: () => const _OpsLoadingBody(),
        error: (error, _) => _OpsErrorBody(
          message:
              '${l10n.opsLoadFailed}\n${ErrorParser.parse(error, l10n.opsLoadFailed, l10n)}',
          onRetry: () =>
              ref.invalidate(tournamentDivisionsProvider(widget.tournamentId)),
        ),
        data: (rawDivisions) {
          final divisions = rawDivisions
              .map(_OpsDivision.fromJson)
              .where((division) => division.id.isNotEmpty)
              .toList(growable: false);
          if (divisions.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(tournamentProvider(widget.tournamentId));
                ref.invalidate(
                  tournamentDivisionsProvider(widget.tournamentId),
                );
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  ...widget.overlapHandles.map(
                    (handle) => SliverOverlapInjector(handle: handle),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: _OpsReadOnlyNotice(
                        icon: Icons.category_outlined,
                        title: l10n.opsDivision,
                        message: l10n.opsEmptyDivision,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final selectedDivisionId = _resolveDivisionId(divisions);
          final selectedDivision = divisions.firstWhere(
            (division) => division.id == selectedDivisionId,
          );
          final matchesAsync = ref.watch(
            managedMatchesWithDivisionProvider((
              tournamentId: widget.tournamentId,
              divisionId: selectedDivisionId,
            )),
          );
          final opsReadAsync = ref.watch(
            organizerOpsReadModelProvider((
              tournamentId: widget.tournamentId,
              divisionId: selectedDivisionId!,
            )),
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tournamentProvider(widget.tournamentId));
              ref.invalidate(tournamentDivisionsProvider(widget.tournamentId));
              ref.invalidate(
                managedMatchesWithDivisionProvider((
                  tournamentId: widget.tournamentId,
                  divisionId: selectedDivisionId,
                )),
              );
              ref.invalidate(
                organizerOpsReadModelProvider((
                  tournamentId: widget.tournamentId,
                  divisionId: selectedDivisionId,
                )),
              );
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                ...widget.overlapHandles.map(
                  (handle) => SliverOverlapInjector(handle: handle),
                ),
                if (widget.view == null)
                  SliverToBoxAdapter(
                    child: _OpsContextHeader(
                      tournament: tournament,
                      division: divisions.firstWhere(
                        (item) => item.id == selectedDivisionId,
                        orElse: () => divisions.first,
                      ),
                      colors: colors,
                    ),
                  ),
                if (widget.view == null ||
                    !(_selectedTab == 1 &&
                        _matchesView == OrganizerOpsMatchesView.grid))
                  SliverToBoxAdapter(
                    child: _OpsDivisionSelector(
                      divisions: divisions,
                      selectedDivisionId: selectedDivisionId,
                      onChanged: (value) {
                        setState(() {
                          _selectedDivisionId = value;
                          _rosterFilter = 'ALL';
                          if (widget.view == null) _selectedTab = 1;
                          _opsMatchFilter = 'ongoing';
                        });
                        widget.onDivisionChanged?.call(value);
                      },
                    ),
                  ),
                if (widget.view == null)
                  SliverToBoxAdapter(
                    child: _OpsTabBar(
                      selectedIndex: _selectedTab,
                      onChanged: (value) =>
                          setState(() => _selectedTab = value),
                    ),
                  ),
                if (_selectedTab == 0)
                  SliverToBoxAdapter(
                    child: _OpsOverview(
                      tournament: tournament,
                      divisions: divisions,
                      matchesAsync: matchesAsync,
                      readOnly: isReadOnly,
                    ),
                  )
                else if (_selectedTab == 1)
                  _buildMatchesSliver(
                    context,
                    matchesAsync,
                    readOnly: isReadOnly,
                    divisionId: selectedDivisionId,
                    divisionOptions: [
                      for (final division in divisions)
                        (id: division.id, name: division.name),
                    ],
                    selectedFilter: _opsMatchFilter,
                    focusedMatchId: _focusedMatchId,
                    onFilterChanged: (value) =>
                        setState(() => _opsMatchFilter = value),
                    onRetry: () => ref.invalidate(
                      managedMatchesWithDivisionProvider((
                        tournamentId: widget.tournamentId,
                        divisionId: selectedDivisionId,
                      )),
                    ),
                  )
                else if (_selectedTab == 2)
                  SliverToBoxAdapter(
                    child: _OpsBracketPreview(
                      tournamentId: widget.tournamentId,
                      divisionId: selectedDivisionId,
                      readOnly: isReadOnly,
                    ),
                  )
                else if (_selectedTab == 3)
                  _buildRosterSliver(
                    context,
                    opsReadAsync,
                    tournament: tournament,
                    division: selectedDivision,
                    readOnly: isReadOnly,
                  )
                else if (_selectedTab == 4)
                  _buildActivitySliver(context, opsReadAsync)
                else
                  // The camera board owns its scroll view, so this sliver
                  // must hand it a bounded height instead of sizing to it.
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: TournamentManagementCameraSection(
                      tournamentId: widget.tournamentId,
                      divisionId: selectedDivisionId,
                      readOnly: isReadOnly,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivitySliver(
    BuildContext context,
    AsyncValue<OrganizerOpsReadModel> opsAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return opsAsync.when(
      loading: () => const SliverToBoxAdapter(child: _OpsInlineLoading()),
      error: (error, _) => SliverToBoxAdapter(
        child: _OpsErrorBody(
          message: ErrorParser.parse(error, l10n.opsLoadFailed, l10n),
          onRetry: () => ref.invalidate(
            organizerOpsReadModelProvider((
              tournamentId: widget.tournamentId,
              divisionId: _selectedDivisionId!,
            )),
          ),
        ),
      ),
      data: (readModel) {
        if (readModel.auditEntries.isEmpty) {
          return SliverToBoxAdapter(
            child: _OpsReadOnlyNotice(
              icon: Icons.history_rounded,
              title: l10n.opsAudit,
              message: l10n.opsNoActivity,
            ),
          );
        }
        return SliverList.builder(
          itemCount: readModel.auditEntries.length,
          itemBuilder: (context, index) =>
              _OpsActivityCard(entry: readModel.auditEntries[index]),
        );
      },
    );
  }

  Widget _buildRosterSliver(
    BuildContext context,
    AsyncValue<OrganizerOpsReadModel> opsAsync, {
    required Tournament tournament,
    required _OpsDivision division,
    required bool readOnly,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return opsAsync.when(
      loading: () => const SliverToBoxAdapter(child: _OpsInlineLoading()),
      error: (error, _) => SliverToBoxAdapter(
        child: _OpsErrorBody(
          message: ErrorParser.parse(error, l10n.opsLoadFailed, l10n),
          onRetry: () => ref.invalidate(
            organizerOpsReadModelProvider((
              tournamentId: widget.tournamentId,
              divisionId: _selectedDivisionId!,
            )),
          ),
        ),
      ),
      data: (readModel) {
        final allParticipants = readModel.participants;
        if (allParticipants.isEmpty) {
          if (readOnly) {
            return SliverToBoxAdapter(
              child: _OpsReadOnlyNotice(
                icon: Icons.people_alt_outlined,
                title: l10n.opsRoster,
                message: l10n.opsNoParticipants,
              ),
            );
          }
          return SliverList.list(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _OpsReadOnlyNotice(
                  icon: Icons.people_alt_outlined,
                  title: l10n.opsRoster,
                  message: l10n.opsNoParticipants,
                ),
              ),
              _buildAddAthleteAction(
                context,
                tournament,
                division,
                allParticipants,
              ),
            ],
          );
        }

        final participants = switch (_rosterFilter) {
          'PAID' =>
            allParticipants
                .where((participant) => participant.isPaid)
                .toList(growable: false),
          'UNPAID' =>
            allParticipants
                .where((participant) => !participant.isPaid)
                .toList(growable: false),
          'KICKED' =>
            allParticipants
                .where((participant) => participant.isKicked)
                .toList(growable: false),
          _ => allParticipants,
        };
        final query = _rosterQuery.trim().toLowerCase();
        final visibleParticipants = query.isEmpty
            ? participants
            : participants
                  .where(
                    (participant) =>
                        participant.teamName.toLowerCase().contains(query) ||
                        participant.members.any(
                          (member) =>
                              member.fullName.toLowerCase().contains(query),
                        ),
                  )
                  .toList(growable: false);
        final actionOffset = readOnly ? 0 : 1;
        final itemCount =
            2 +
            actionOffset +
            (visibleParticipants.isEmpty ? 1 : visibleParticipants.length);
        return SliverList.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _OpsReadOnlyNotice(
                  icon: Icons.info_outline_rounded,
                  title: l10n.opsRoster,
                  message: l10n.opsContextHint,
                ),
              );
            }
            if (index == 1) {
              return _OpsRosterFilterBar(
                selectedFilter: _rosterFilter,
                onSearchChanged: (query) =>
                    setState(() => _rosterQuery = query),
                onChanged: (filter) => setState(() => _rosterFilter = filter),
              );
            }
            if (!readOnly && index == 2) {
              return _buildAddAthleteAction(
                context,
                tournament,
                division,
                allParticipants,
              );
            }
            if (visibleParticipants.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _OpsReadOnlyNotice(
                  icon: Icons.search_off_rounded,
                  title: l10n.opsRoster,
                  message: l10n.opsNoFilteredParticipants,
                ),
              );
            }
            final participant = visibleParticipants[index - 2 - actionOffset];
            return _OpsParticipantCard(
              participant: participant,
              onKick: readOnly || participant.isKicked
                  ? null
                  : () => _showKickParticipantSheet(context, participant),
            );
          },
        );
      },
    );
  }

  Widget _buildAddAthleteAction(
    BuildContext context,
    Tournament tournament,
    _OpsDivision division,
    List<OrganizerOpsParticipant> participants,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const ValueKey('organizer-ops-add-athlete'),
          onPressed: () => _showAddAthleteSheet(
            context,
            tournament: tournament,
            division: division,
            participants: participants,
          ),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: Text(l10n.opsAddAthlete),
        ),
      ),
    );
  }

  Future<void> _showAddAthleteSheet(
    BuildContext context, {
    required Tournament tournament,
    required _OpsDivision division,
    required List<OrganizerOpsParticipant> participants,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      builder: (_) => AddAthleteSheet(
        tournament: tournament,
        divisionId: division.id,
        divisionName: division.name,
        divisionMatchType: division.matchType,
        divisionEntryFee: division.entryFee,
        effectiveEntryFee: division.effectiveEntryFee,
        participants: participants,
        onRefresh: () => _refreshRosterAfterAdd(division.id),
      ),
    );
  }

  Future<void> _refreshRosterAfterAdd(String divisionId) async {
    if (!mounted) return;
    final divisionsProvider = tournamentDivisionsProvider(widget.tournamentId);
    final rosterProvider = organizerOpsReadModelProvider((
      tournamentId: widget.tournamentId,
      divisionId: divisionId,
    ));
    ref.invalidate(tournamentProvider(widget.tournamentId));
    ref.invalidate(divisionsProvider);
    ref.invalidate(rosterProvider);
    await Future.wait([
      ref.read(divisionsProvider.future),
      ref.read(rosterProvider.future),
    ]);
  }

  bool _isOpsTerminalMatch(MatchModel match) {
    final status = match.status.trim().toUpperCase();
    return match.isCompleted ||
        status == 'FINISHED' ||
        match.completedAt != null ||
        match.winnerId.trim().isNotEmpty;
  }

  String _opsMatchBucket(MatchModel match) {
    final status = match.status.trim().toUpperCase();
    final missingOpponent =
        match.team1Id.trim().isEmpty || match.team2Id.trim().isEmpty;
    final isDirectAdvance =
        match.isBye || (match.winnerId.trim().isNotEmpty && missingOpponent);

    if (isDirectAdvance) return 'attention';
    if (match.isLive) return 'ongoing';
    if (_isOpsTerminalMatch(match)) return 'completed';

    final needsAttention =
        status == 'DISPUTED' ||
        missingOpponent ||
        match.scheduledTime == null ||
        status != 'SCHEDULED';
    return needsAttention ? 'attention' : 'scheduled';
  }

  List<MatchModel> _sortOpsMatches(
    List<MatchModel> matches,
    String selectedFilter,
  ) {
    const priority = <String, int>{
      'ongoing': 0,
      'scheduled': 1,
      'completed': 2,
      'attention': 3,
    };
    final visible = selectedFilter == 'all'
        ? List<MatchModel>.of(matches)
        : matches
              .where((match) => _opsMatchBucket(match) == selectedFilter)
              .toList();
    visible.sort((a, b) {
      final bucketCompare = (priority[_opsMatchBucket(a)] ?? 9).compareTo(
        priority[_opsMatchBucket(b)] ?? 9,
      );
      if (bucketCompare != 0) return bucketCompare;
      final groupCompare = (a.groupName ?? '').compareTo(b.groupName ?? '');
      if (groupCompare != 0) return groupCompare;
      final legCompare = (a.leg ?? 1).compareTo(b.leg ?? 1);
      if (legCompare != 0) return legCompare;
      return a.id.compareTo(b.id);
    });
    return visible;
  }

  List<_OpsMatchSectionData> _buildOpsMatchSections(
    List<MatchModel> matches,
    String selectedFilter,
  ) {
    const order = ['ongoing', 'scheduled', 'completed', 'attention'];
    final keys = selectedFilter == 'all' ? order : [selectedFilter];
    return [
      for (final key in keys)
        _OpsMatchSectionData(key: key, matches: _sortOpsMatches(matches, key)),
    ];
  }

  String _opsSectionTitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'ongoing' => l10n.opsOngoing,
      'scheduled' => l10n.opsScheduled,
      'completed' => l10n.opsCompleted,
      'attention' => l10n.opsAttention,
      _ => l10n.opsMatches,
    };
  }

  Widget _buildOpsMatchFilterBar(
    BuildContext context,
    AppLocalizations l10n,
    String selectedFilter,
    ValueChanged<String> onChanged,
  ) {
    final colors = context.colors;
    final filters = <({String value, String label})>[
      (value: 'ongoing', label: l10n.opsOngoing),
      (value: 'scheduled', label: l10n.opsScheduled),
      (value: 'completed', label: l10n.opsCompleted),
      (value: 'attention', label: l10n.opsAttention),
      (value: 'all', label: l10n.filterAll),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final view in OrganizerOpsMatchesView.values)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _matchesViewButton(view, colors),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: filters.map((filter) {
              final selected = selectedFilter == filter.value;
              return ChoiceChip(
                label: Text(filter.label),
                selected: selected,
                onSelected: (_) => onChanged(filter.value),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : colors.textSecondary,
                ),
                selectedColor: AppTheme.primary,
                backgroundColor: Colors.transparent,
                side: BorderSide(
                  color: selected ? AppTheme.primary : colors.border,
                ),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _matchesViewButton(
    OrganizerOpsMatchesView view,
    AppColorsExtension colors,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final selected = _matchesView == view;
    final isGrid = view == OrganizerOpsMatchesView.grid;
    return Tooltip(
      message: isGrid ? l10n.tournamentManagementSchedule : l10n.opsMatches,
      child: IconButton(
        key: ValueKey('ops-matches-view-${view.name}'),
        onPressed: () => setState(() {
          if (view == OrganizerOpsMatchesView.grid &&
              _matchesView != OrganizerOpsMatchesView.grid) {
            _opsMatchFilter = 'all';
          }
          _matchesView = view;
        }),
        iconSize: 18,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: selected ? AppTheme.primary : colors.bgCard,
          side: BorderSide(
            color: selected ? AppTheme.primary : colors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(
          isGrid ? Icons.grid_view_rounded : Icons.view_list_rounded,
          color: selected ? Colors.white : colors.textSecondary,
        ),
      ),
    );
  }

  /// Thả một trận vào ô (sân + giờ): chặn nếu chồng lấn cùng sân, nếu không thì
  /// ghi lịch rồi tải lại danh sách trận.
  Future<void> _scheduleMatchDrop({
    required BuildContext context,
    required List<MatchModel> visible,
    required String matchId,
    required String courtId,
    required String courtName,
    required DateTime scheduledAt,
    required String? divisionId,
    required int minutesPerSet,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final messenger = ScaffoldMessenger.of(context);

    MatchModel? target;
    for (final match in visible) {
      if (match.id == matchId) {
        target = match;
        break;
      }
    }
    if (target == null) return;

    if (_clashesWith(
      visible: visible,
      skipMatchId: matchId,
      courtName: courtName,
      scheduledAt: scheduledAt,
      minutes: scheduledDurationMinutes(target, minutesPerSet: minutesPerSet),
      minutesPerSet: minutesPerSet,
    )) {
      _showScheduleMessage(messenger, l10n.scheduleQuickClash);
      return;
    }

    final snapshot = await _writeSlot(
      matchId,
      ScheduleSlot(
        courtId: courtId,
        courtName: courtName,
        scheduledAt: scheduledAt,
      ),
    );
    if (!mounted) return;
    if (snapshot == null) {
      _showScheduleMessage(messenger, l10n.tournamentManagementActionError);
      return;
    }
    if (_serverMoved(snapshot, courtId: courtId, scheduledAt: scheduledAt)) {
      _showScheduleMessage(messenger, l10n.scheduleQuickServerMoved(1));
    }
    ref.invalidate(
      managedMatchesWithDivisionProvider((
        tournamentId: widget.tournamentId,
        divisionId: divisionId,
      )),
    );
  }

  /// Có trận nào trên cùng sân chồng lấn khoảng [scheduledAt, +minutes) không.
  /// Chỉ xét trận cùng ngày (giờ trên lưới là giờ trong ngày).
  bool _clashesWith({
    required List<MatchModel> visible,
    required String? skipMatchId,
    required String courtName,
    required DateTime scheduledAt,
    required int minutes,
    required int minutesPerSet,
  }) {
    final start = scheduledAt.hour * 60 + scheduledAt.minute;
    final end = start + minutes;
    for (final other in visible) {
      if (other.id == skipMatchId) continue;
      if (_courtNameOf(other) != courtName) continue;
      final at = other.scheduledTime;
      if (at == null) continue;
      if (!_sameLocalDay(at.toLocal(), scheduledAt)) continue;
      final otherStart = at.toLocal().hour * 60 + at.toLocal().minute;
      final otherEnd =
          otherStart +
          scheduledDurationMinutes(other, minutesPerSet: minutesPerSet);
      if (start < otherEnd && otherStart < end) return true;
    }
    return false;
  }

  static bool _sameLocalDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Xếp cả lô trận vào vùng ô đã chọn: kiểm hết trước, chỉ ghi khi không trận
  /// nào chồng lấn.
  Future<void> _bulkSchedule({
    required BuildContext context,
    required List<MatchModel> visible,
    required List<({String courtId, String courtName, DateTime at})> cells,
    required List<MatchModel> waiting,
    required String? divisionId,
    required int minutesPerSet,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final messenger = ScaffoldMessenger.of(context);

    final count = cells.length < waiting.length ? cells.length : waiting.length;
    if (count == 0) return;

    // Preflight: gom các khoảng đang bận **cùng ngày** rồi kiểm từng trận; lệch
    // thì chưa ghi gì.
    final day = cells.first.at;
    final busy = <({String court, int start, int end})>[
      for (final match in visible)
        if (match.scheduledTime != null &&
            _sameLocalDay(match.scheduledTime!.toLocal(), day))
          (
            court: _courtNameOf(match),
            start:
                match.scheduledTime!.toLocal().hour * 60 +
                match.scheduledTime!.toLocal().minute,
            end:
                match.scheduledTime!.toLocal().hour * 60 +
                match.scheduledTime!.toLocal().minute +
                scheduledDurationMinutes(match, minutesPerSet: minutesPerSet),
          ),
    ];
    for (var i = 0; i < count; i++) {
      final start = cells[i].at.hour * 60 + cells[i].at.minute;
      final end =
          start +
          scheduledDurationMinutes(waiting[i], minutesPerSet: minutesPerSet);
      if (busy.any(
        (b) =>
            b.court == cells[i].courtName && start < b.end && b.start < end,
      )) {
        _showScheduleMessage(messenger, l10n.tournamentManagementActionError);
        return;
      }
      busy.add((court: cells[i].courtName, start: start, end: end));
    }

    var moved = 0;
    for (var i = 0; i < count; i++) {
      final snapshot = await _writeSlot(
        waiting[i].id,
        ScheduleSlot(
          courtId: cells[i].courtId,
          courtName: cells[i].courtName,
          scheduledAt: cells[i].at,
        ),
      );
      if (!mounted) return;
      if (snapshot == null) {
        // Đã ghi được i trận trước đó; nói rõ phần đã ghi rồi tải lại để thấy
        // đúng thực tế (không có API ghi hàng loạt nên không nguyên tử).
        _showScheduleMessage(
          messenger,
          '${l10n.tournamentManagementActionError} ($i/$count)',
        );
        ref.invalidate(
          managedMatchesWithDivisionProvider((
            tournamentId: widget.tournamentId,
            divisionId: divisionId,
          )),
        );
        return;
      }
      if (_serverMoved(
        snapshot,
        courtId: cells[i].courtId,
        scheduledAt: cells[i].at,
      )) {
        moved++;
      }
    }
    if (!mounted) return;
    if (moved > 0) {
      _showScheduleMessage(messenger, l10n.scheduleQuickServerMoved(moved));
    }
    ref.invalidate(
      managedMatchesWithDivisionProvider((
        tournamentId: widget.tournamentId,
        divisionId: divisionId,
      )),
    );
  }

  static String _courtNameOf(MatchModel match) {
    final name = match.courtName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return match.court.trim();
  }

  void _showScheduleMessage(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  /// Sân của giải cho các ô chọn sân. Trả về null (đã báo lỗi) nếu không tải
  /// được hoặc giải chưa có sân.
  Future<List<ScheduleCourt>?> _loadScheduleCourts(
    AppLocalizations l10n,
    ScaffoldMessengerState messenger,
  ) async {
    try {
      final courts = parseScheduleCourts(
        await ref
            .read(tournamentManagementRepositoryProvider)
            .getVenues(widget.tournamentId),
      );
      if (courts.isNotEmpty) return courts;
      _showScheduleMessage(messenger, l10n.scheduleQuickNoCourts);
    } catch (error) {
      _showScheduleMessage(
        messenger,
        ErrorParser.parse(error, l10n.opsLoadFailed, l10n),
      );
    }
    return null;
  }

  /// Kéo một trận thả lên trận khác: đổi chỗ hai trận, hoặc đưa trận từ khay
  /// vào ô của trận đích. Kiểm trùng trước, xác nhận rồi mới ghi.
  Future<void> _swapMatches({
    required BuildContext context,
    required List<MatchModel> visible,
    required String draggedId,
    required String targetId,
    required int minutesPerSet,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final dragged = _findMatch(visible, draggedId);
    final target = _findMatch(visible, targetId);
    if (dragged == null || target == null || dragged.id == target.id) return;
    if (isScheduleLocked(dragged) || isScheduleLocked(target)) {
      _showScheduleMessage(messenger, l10n.scheduleQuickLocked);
      return;
    }
    final targetSlot = scheduleSlotOf(target);
    if (targetSlot == null) return;
    final draggedSlot = scheduleSlotOf(dragged);
    final planned = <String, ({String court, DateTime at, int minutes})?>{
      dragged.id: (
        court: targetSlot.courtName,
        at: targetSlot.scheduledAt,
        minutes: scheduledDurationMinutes(
          dragged,
          minutesPerSet: minutesPerSet,
        ),
      ),
      target.id: draggedSlot == null
          ? null
          : (
              court: draggedSlot.courtName,
              at: draggedSlot.scheduledAt,
              minutes: scheduledDurationMinutes(
                target,
                minutesPerSet: minutesPerSet,
              ),
            ),
    };
    if (_overlapsAfter(
      visible: visible,
      planned: planned,
      minutesPerSet: minutesPerSet,
    )) {
      _showScheduleMessage(messenger, l10n.scheduleQuickClash);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.scheduleQuickSwapTitle),
        content: Text(
          l10n.scheduleQuickSwapMessage(
            _pairLabel(dragged),
            _pairLabel(target),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.matchCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.scheduleQuickSwapConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final report = await runScheduleSwap(
      draggedId: dragged.id,
      draggedSlot: draggedSlot,
      targetId: target.id,
      targetSlot: targetSlot,
      write: _writeSlot,
    );
    if (!mounted) return;
    ref.invalidate(managedMatchesWithDivisionProvider);
    final outcome = switch (report.result) {
      ScheduleSwapResult.swapped => l10n.scheduleQuickSwapDone,
      ScheduleSwapResult.aborted => l10n.scheduleQuickSwapAborted,
      ScheduleSwapResult.rolledBack => l10n.scheduleQuickSwapRolledBack,
      ScheduleSwapResult.partial => l10n.scheduleQuickSwapPartial,
    };
    final moved = report.movedMatchIds.length;
    _showScheduleMessage(
      messenger,
      moved == 0
          ? outcome
          : '$outcome ${l10n.scheduleQuickServerMoved(moved)}',
    );
  }

  /// Đặt cùng thời lượng cho các trận đã chọn trong vùng. Kiểm trùng cả lô
  /// trước khi ghi; lỗi giữa chừng thì dừng và tải lại lịch.
  Future<void> _bulkDuration({
    required BuildContext context,
    required List<MatchModel> visible,
    required List<MatchModel> matches,
    required int minutes,
    required int minutesPerSet,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final editable = [
      for (final match in matches)
        if (!isScheduleLocked(match) && match.scheduledTime != null) match,
    ];
    if (editable.isEmpty) return;
    final planned = <String, ({String court, DateTime at, int minutes})?>{
      for (final match in editable)
        match.id: (
          court: _courtNameOf(match),
          at: match.scheduledTime!,
          minutes: minutes,
        ),
    };
    if (_overlapsAfter(
      visible: visible,
      planned: planned,
      minutesPerSet: minutesPerSet,
    )) {
      _showScheduleMessage(messenger, l10n.scheduleQuickClash);
      return;
    }
    var done = 0;
    for (final match in editable) {
      try {
        await ref
            .read(matchRepositoryProvider)
            .updateSchedule(
              widget.tournamentId,
              match.id,
              durationMinutes: minutes,
            );
      } catch (_) {
        if (!mounted) return;
        ref.invalidate(managedMatchesWithDivisionProvider);
        _showScheduleMessage(
          messenger,
          l10n.scheduleQuickBulkFailed(done, editable.length),
        );
        return;
      }
      done++;
    }
    if (!mounted) return;
    ref.invalidate(managedMatchesWithDivisionProvider);
    _showScheduleMessage(messenger, l10n.scheduleQuickBulkDone(done));
  }

  /// Dời cả nhóm trận đã chọn sang sân khác, giữ nguyên giờ. Kiểm trùng cả lô
  /// trước khi ghi; lỗi giữa chừng thì dừng và tải lại lịch.
  Future<void> _bulkMoveCourt({
    required BuildContext context,
    required List<MatchModel> visible,
    required List<MatchModel> matches,
    required ScheduleCourt court,
    required int minutesPerSet,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final editable = [
      for (final match in matches)
        if (!isScheduleLocked(match) && match.scheduledTime != null) match,
    ];
    if (editable.isEmpty) return;
    final planned = <String, ({String court, DateTime at, int minutes})?>{
      for (final match in editable)
        match.id: (
          court: court.name,
          at: match.scheduledTime!,
          minutes: scheduledDurationMinutes(
            match,
            minutesPerSet: minutesPerSet,
          ),
        ),
    };
    if (_overlapsAfter(
      visible: visible,
      planned: planned,
      minutesPerSet: minutesPerSet,
    )) {
      _showScheduleMessage(messenger, l10n.scheduleQuickClash);
      return;
    }
    var done = 0;
    var moved = 0;
    for (final match in editable) {
      final slot = ScheduleSlot(
        courtId: court.id,
        courtName: court.name,
        scheduledAt: match.scheduledTime!,
      );
      final saved = await _writeSlot(match.id, slot);
      if (!mounted) return;
      if (saved == null) {
        ref.invalidate(managedMatchesWithDivisionProvider);
        _showScheduleMessage(
          messenger,
          l10n.scheduleQuickBulkFailed(done, editable.length),
        );
        return;
      }
      done++;
      if (_serverMoved(
        saved,
        courtId: court.id,
        scheduledAt: slot.scheduledAt,
      )) {
        moved++;
      }
    }
    if (!mounted) return;
    ref.invalidate(managedMatchesWithDivisionProvider);
    final summary = l10n.scheduleQuickBulkDone(done);
    _showScheduleMessage(
      messenger,
      moved == 0
          ? summary
          : '$summary ${l10n.scheduleQuickServerMoved(moved)}',
    );
  }

  /// Ô trống trên lưới: chọn một trận chờ để xếp vào đúng sân và giờ đó.
  Future<void> _showEmptyCellPicker({
    required BuildContext context,
    required List<MatchModel> visible,
    required String? divisionId,
    required int minutesPerSet,
    required String courtId,
    required String courtName,
    required DateTime at,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final waiting = [
      for (final match in visible)
        if (_isWaiting(match) && !isScheduleLocked(match)) match,
    ];
    var query = '';
    final picked = await showModalBottomSheet<MatchModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final needle = query.trim().toLowerCase();
          final shown = [
            for (final match in waiting)
              if (needle.isEmpty ||
                  _pairLabel(match).toLowerCase().contains(needle))
                match,
          ];
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.scheduleQuickPickerTitle(
                      courtName,
                      _hhmm(at.hour * 60 + at.minute),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: l10n.scheduleQuickPickerSearch,
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                    onChanged: (value) => setSheetState(() => query = value),
                  ),
                  const SizedBox(height: 8),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(l10n.scheduleQuickPickerEmpty),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final match in shown)
                            ListTile(
                              key: ValueKey('schedule-picker-${match.id}'),
                              minVerticalPadding: 14,
                              title: Text(
                                _pairLabel(match),
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.pop(sheetContext, match),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (picked == null || !context.mounted) return;
    await _scheduleMatchDrop(
      context: context,
      visible: visible,
      matchId: picked.id,
      courtId: courtId,
      courtName: courtName,
      scheduledAt: at,
      divisionId: divisionId,
      minutesPerSet: minutesPerSet,
    );
  }

  /// ⚡ Xếp tự động: chọn nội dung, sân, ngày, giờ bắt đầu và thời lượng, rồi
  /// xem trước. Máy chủ chỉ tính kế hoạch, không ghi. Bản nháp hiện trên lưới
  /// và chỉ ghi khi người dùng áp dụng.
  Future<void> _showAutoScheduleSheet({
    required BuildContext context,
    required List<ScheduleDivision> divisions,
    required String? initialDivisionId,
    required Map<String, dynamic> scheduleSettings,
    required List<MatchModel> visible,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final courts = await _loadScheduleCourts(l10n, messenger);
    if (courts == null || !context.mounted) return;

    final minutesPerSet =
        (scheduleSettings['minutesPerSet'] as num?)?.toInt() ?? 15;
    final startHour = _settingHour(scheduleSettings['operatingStart'], 7);
    final endHour = _settingHour(scheduleSettings['operatingEnd'], 22);
    final startChoices = quickScheduleMinutes(
      startHour: startHour,
      endHour: endHour,
    );
    MatchModel? firstWaiting;
    for (final match in visible) {
      if (_isWaiting(match) && !isScheduleLocked(match)) {
        firstWaiting = match;
        break;
      }
    }
    var duration = firstWaiting == null
        ? 60
        : scheduledDurationMinutes(
            firstWaiting,
            minutesPerSet: minutesPerSet,
          );
    final durationOptions = <int>{...scheduleDurationOptions, duration}.toList()
      ..sort();
    final selectedDivisions = <String>{?initialDivisionId};
    if (selectedDivisions.isEmpty && divisions.isNotEmpty) {
      selectedDivisions.add(divisions.first.id);
    }
    final selectedCourts = <String>{for (final court in courts) court.id};
    var day = _dayOnly(DateTime.now());
    var startMinute = startChoices.isEmpty
        ? startHour * 60
        : startChoices.first;
    var busy = false;
    String? error;

    final result =
        await showModalBottomSheet<({List<MatchModel> drafts, int skipped})>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) {
              final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.scheduleQuickAutoTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.scheduleQuickAutoDivisions,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final division in divisions)
                          FilterChip(
                            label: Text(division.name),
                            selected: selectedDivisions.contains(division.id),
                            onSelected: (on) => setSheetState(() {
                              if (on) {
                                selectedDivisions.add(division.id);
                              } else {
                                selectedDivisions.remove(division.id);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.scheduleQuickCourt,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final court in courts)
                          FilterChip(
                            label: Text(court.name),
                            selected: selectedCourts.contains(court.id),
                            onSelected: (on) => setSheetState(() {
                              if (on) {
                                selectedCourts.add(court.id);
                              } else {
                                selectedCourts.remove(court.id);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: day,
                        );
                        if (picked == null || !context.mounted) return;
                        setSheetState(() => day = _dayOnly(picked));
                      },
                      icon: const Icon(Icons.event_rounded),
                      label: Text(
                        '${l10n.scheduleQuickDate}: ${_dateText(day)}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: startMinute,
                      decoration: InputDecoration(
                        labelText: l10n.scheduleQuickStart,
                        prefixIcon: const Icon(Icons.schedule_rounded),
                      ),
                      items: [
                        for (final minute in startChoices)
                          DropdownMenuItem<int>(
                            value: minute,
                            child: Text(_hhmm(minute)),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => startMinute = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: duration,
                      decoration: InputDecoration(
                        labelText: l10n.scheduleQuickDuration,
                        prefixIcon: const Icon(Icons.timer_outlined),
                      ),
                      items: [
                        for (final minutes in durationOptions)
                          DropdownMenuItem<int>(
                            value: minutes,
                            child: Text(l10n.scheduleQuickMinutes(minutes)),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => duration = value);
                        }
                      },
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              if (selectedDivisions.isEmpty ||
                                  selectedCourts.isEmpty) {
                                setSheetState(
                                  () => error =
                                      l10n.scheduleQuickAutoNeedSelection,
                                );
                                return;
                              }
                              setSheetState(() {
                                busy = true;
                                error = null;
                              });
                              try {
                                final preview = await _previewAutoSchedule(
                                  divisionIds: selectedDivisions,
                                  courts: [
                                    for (final court in courts)
                                      if (selectedCourts.contains(court.id))
                                        court,
                                  ],
                                  day: day,
                                  startMinute: startMinute,
                                  endHour: endHour,
                                  durationMinutes: duration,
                                );
                                if (!sheetContext.mounted) return;
                                if (preview.drafts.isEmpty) {
                                  setSheetState(() {
                                    busy = false;
                                    error = l10n.scheduleQuickAutoNoFit;
                                  });
                                  return;
                                }
                                Navigator.pop(sheetContext, preview);
                              } catch (failure) {
                                if (!sheetContext.mounted) return;
                                setSheetState(() {
                                  busy = false;
                                  error = ErrorParser.parse(
                                    failure,
                                    l10n.opsLoadFailed,
                                    l10n,
                                  );
                                });
                              }
                            },
                      icon: busy
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_fix_high_rounded),
                      label: Text(l10n.scheduleQuickAutoPreview),
                    ),
                  ],
                ),
              );
            },
          ),
        );
    if (result == null || !mounted) return;
    setState(() {
      _draftMatches = result.drafts;
      _draftSkipped = result.skipped;
      _draftProgress = null;
    });
  }

  /// Lấy trận chờ của các nội dung đã chọn rồi nhờ máy chủ xếp thử. Không ghi.
  Future<({List<MatchModel> drafts, int skipped})> _previewAutoSchedule({
    required Set<String> divisionIds,
    required List<ScheduleCourt> courts,
    required DateTime day,
    required int startMinute,
    required int endHour,
    required int durationMinutes,
  }) async {
    final waiting = <MatchModel>[];
    for (final divisionId in divisionIds) {
      final matches = await ref.read(
        managedMatchesWithDivisionProvider((
          tournamentId: widget.tournamentId,
          divisionId: divisionId,
        )).future,
      );
      waiting.addAll(
        matches.where(
          (match) => _isWaiting(match) && !isScheduleLocked(match),
        ),
      );
    }
    if (waiting.isEmpty) return (drafts: const <MatchModel>[], skipped: 0);
    final dayStart = _dayOnly(day);
    final plan = await ref
        .read(matchRepositoryProvider)
        .previewSchedulePlan(
          widget.tournamentId,
          day: dayStart,
          courtIds: [for (final court in courts) court.id],
          matchIds: [for (final match in waiting) match.id],
          windowStart: dayStart.add(Duration(minutes: startMinute)),
          windowEnd: dayStart.add(Duration(minutes: endHour * 60)),
          durationMinutes: durationMinutes,
        );
    final byId = {for (final match in waiting) match.id: match};
    final courtNames = {for (final court in courts) court.id: court.name};
    final drafts = <MatchModel>[
      for (final assignment in plan.assignments)
        if (byId[assignment.matchId] != null)
          scheduleDraftOf(
            byId[assignment.matchId]!,
            assignment: assignment,
            courtName: courtNames[assignment.courtId] ?? '',
            durationMinutes: plan.durationMinutes,
          ),
    ];
    return (drafts: drafts, skipped: plan.skipped.length);
  }

  /// Ghi các bản nháp xếp tự động theo thứ tự. Gặp lỗi thì dừng, bỏ bản nháp và
  /// tải lại lịch để thấy đúng phần đã ghi.
  Future<void> _applyDraft({required BuildContext context}) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final drafts = _draftMatches;
    if (drafts.isEmpty || _draftProgress != null) return;
    setState(() => _draftProgress = (done: 0, total: drafts.length));
    var done = 0;
    var moved = 0;
    var failed = false;
    for (final draft in drafts) {
      final slot = scheduleSlotOf(draft);
      if (slot == null) {
        failed = true;
        break;
      }
      final saved = await _writeSlot(
        draft.id,
        slot,
        durationMinutes: draft.durationMinutes,
      );
      if (!mounted) return;
      if (saved == null) {
        failed = true;
        break;
      }
      done++;
      if (_serverMoved(
        saved,
        courtId: slot.courtId,
        scheduledAt: slot.scheduledAt,
      )) {
        moved++;
      }
      setState(() => _draftProgress = (done: done, total: drafts.length));
    }
    if (!mounted) return;
    setState(() {
      _draftMatches = const [];
      _draftSkipped = 0;
      _draftProgress = null;
    });
    ref.invalidate(managedMatchesWithDivisionProvider);
    if (failed) {
      _showScheduleMessage(
        messenger,
        l10n.scheduleQuickBulkFailed(done, drafts.length),
      );
      return;
    }
    final summary = l10n.scheduleQuickAutoApplied(done, drafts.length);
    _showScheduleMessage(
      messenger,
      moved == 0
          ? summary
          : '$summary ${l10n.scheduleQuickServerMoved(moved)}',
    );
  }

  /// Ghi một ô lịch: [slot] null là gỡ trận khỏi lịch. Trả về lịch server đang
  /// lưu, hoặc null nếu ghi lỗi (không ném ra ngoài).
  Future<MatchScheduleSnapshot?> _writeSlot(
    String matchId,
    ScheduleSlot? slot, {
    int? durationMinutes,
  }) async {
    final repository = ref.read(matchRepositoryProvider);
    try {
      if (slot == null) {
        return await repository.updateSchedule(
          widget.tournamentId,
          matchId,
          clear: const {
            MatchScheduleField.courtId,
            MatchScheduleField.courtName,
            MatchScheduleField.scheduledAt,
          },
        );
      }
      return await repository.updateSchedule(
        widget.tournamentId,
        matchId,
        courtId: slot.courtId.isEmpty ? null : slot.courtId,
        courtName: slot.courtName,
        scheduledAt: slot.scheduledAt,
        durationMinutes: durationMinutes,
      );
    } catch (_) {
      return null;
    }
  }

  /// Máy chủ có thể dời trận sang giờ hoặc sân khác khi trùng lịch: so với yêu
  /// cầu để báo người dùng.
  static bool _serverMoved(
    MatchScheduleSnapshot placed, {
    required String courtId,
    required DateTime scheduledAt,
  }) {
    final at = placed.scheduledAt;
    if (at == null || !at.isAtSameMomentAs(scheduledAt)) return true;
    return courtId.isNotEmpty &&
        placed.courtId != null &&
        placed.courtId != courtId;
  }

  /// Chồng lấn sau khi áp dụng [planned] (id trận → khoảng mới; null là gỡ khỏi
  /// lịch). Trận không nằm trong [planned] giữ nguyên lịch hiện tại. Chỉ xét
  /// trận cùng sân và cùng ngày.
  static bool _overlapsAfter({
    required List<MatchModel> visible,
    required Map<String, ({String court, DateTime at, int minutes})?> planned,
    required int minutesPerSet,
  }) {
    final spans = <({String court, DateTime day, int start, int end})>[];
    void add(String court, DateTime at, int minutes) {
      final local = at.toLocal();
      final start = local.hour * 60 + local.minute;
      spans.add((
        court: court,
        day: _dayOnly(local),
        start: start,
        end: start + minutes,
      ));
    }

    for (final match in visible) {
      if (planned.containsKey(match.id)) {
        final next = planned[match.id];
        if (next != null) add(next.court, next.at, next.minutes);
        continue;
      }
      final at = match.scheduledTime;
      final court = _courtNameOf(match);
      if (at == null || court.isEmpty) continue;
      add(
        court,
        at,
        scheduledDurationMinutes(match, minutesPerSet: minutesPerSet),
      );
    }
    for (var i = 0; i < spans.length; i++) {
      for (var j = i + 1; j < spans.length; j++) {
        final a = spans[i];
        final b = spans[j];
        if (a.court != b.court || !_sameLocalDay(a.day, b.day)) continue;
        if (a.start < b.end && b.start < a.end) return true;
      }
    }
    return false;
  }

  static DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _dateText(DateTime day) =>
      '${day.day.toString().padLeft(2, '0')}/'
      '${day.month.toString().padLeft(2, '0')}/${day.year}';

  static String _hhmm(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:'
      '${(minute % 60).toString().padLeft(2, '0')}';

  /// Giờ mở/đóng sân trong cài đặt: số, hoặc chuỗi kiểu "07:00".
  static int _settingHour(Object? value, int fallback) {
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value.split(':').first.trim()) ?? fallback;
    }
    return fallback;
  }

  /// Trận chờ xếp lịch: chưa có giờ hoặc chưa có tên sân (cùng quy ước khay chờ).
  static bool _isWaiting(MatchModel match) =>
      match.scheduledTime == null || _courtNameOf(match).isEmpty;

  static MatchModel? _findMatch(List<MatchModel> matches, String id) {
    for (final match in matches) {
      if (match.id == id) return match;
    }
    return null;
  }

  /// Nhãn trận theo hai đội, dùng cho khung chọn và hộp xác nhận.
  static String _pairLabel(MatchModel match) {
    final first = match.team1Name.trim();
    final second = match.team2Name.trim();
    if (first.isEmpty && second.isEmpty) return match.id;
    return '${first.isEmpty ? '?' : first} – ${second.isEmpty ? '?' : second}';
  }

  Widget _buildMatchesSliver(
    BuildContext context,
    AsyncValue<List<MatchModel>> matchesAsync, {
    required bool readOnly,
    required String? divisionId,
    required List<ScheduleDivision> divisionOptions,
    required String selectedFilter,
    required String? focusedMatchId,
    required ValueChanged<String> onFilterChanged,
    required VoidCallback onRetry,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return matchesAsync.when(
      loading: () => const SliverToBoxAdapter(child: _OpsInlineLoading()),
      error: (error, _) => SliverToBoxAdapter(
        child: _OpsErrorBody(
          message: ErrorParser.parse(error, l10n.opsLoadFailed, l10n),
          onRetry: onRetry,
        ),
      ),
      data: (matches) {
        if (matches.isEmpty &&
            _matchesView != OrganizerOpsMatchesView.grid) {
          return SliverToBoxAdapter(
            child: _OpsReadOnlyNotice(
              icon: Icons.sports_score_outlined,
              title: AppLocalizations.of(context)!.opsMatches,
              message: AppLocalizations.of(context)!.opsNoMatches,
            ),
          );
        }

        final sections = _buildOpsMatchSections(matches, selectedFilter);
        if (_matchesView == OrganizerOpsMatchesView.grid) {
          final visible = [for (final section in sections) ...section.matches];
          final scheduleSettings =
              ref
                  .read(tournamentProvider(widget.tournamentId))
                  .value
                  ?.scheduleSettings ??
              const <String, dynamic>{};
          final minutesPerSet =
              (scheduleSettings['minutesPerSet'] as num?)?.toInt() ?? 15;
          // Ba thao tác dùng chung cho lưới trong tab và lưới toàn màn hình, để
          // hai chỗ không lệch hành vi.
          void selectDivision(String value) {
            setState(() {
              _selectedDivisionId = value;
              _opsMatchFilter = 'all';
            });
            widget.onDivisionChanged?.call(value);
          }

          void openMatch(String matchId) {
            MatchModel? target;
            for (final match in visible) {
              if (match.id == matchId) {
                target = match;
                break;
              }
            }
            if (target == null) return;
            if (isScheduleLocked(target)) {
              _showMatchActions(
                context,
                target,
                visible: visible,
                divisionId: divisionId,
              );
            } else {
              _showQuickScheduleSheet(
                context,
                target,
                visible: visible,
                divisionId: divisionId,
              );
            }
          }

          void dropMatch(
            String matchId,
            String courtId,
            String courtName,
            DateTime scheduledAt,
          ) => _scheduleMatchDrop(
            context: context,
            visible: visible,
            matchId: matchId,
            courtId: courtId,
            courtName: courtName,
            scheduledAt: scheduledAt,
            divisionId: divisionId,
            minutesPerSet: minutesPerSet,
          );

          void bulkSchedule(
            List<({String courtId, String courtName, DateTime at})> cells,
            List<MatchModel> waiting,
          ) => _bulkSchedule(
            context: context,
            visible: visible,
            cells: cells,
            waiting: waiting,
            divisionId: divisionId,
            minutesPerSet: minutesPerSet,
          );

          void emptyCellTap(String courtId, String courtName, DateTime at) =>
              _showEmptyCellPicker(
                context: context,
                visible: visible,
                divisionId: divisionId,
                minutesPerSet: minutesPerSet,
                courtId: courtId,
                courtName: courtName,
                at: at,
              );

          void swapMatches(String draggedId, String targetId) => _swapMatches(
            context: context,
            visible: visible,
            draggedId: draggedId,
            targetId: targetId,
            minutesPerSet: minutesPerSet,
          );

          void bulkDuration(List<MatchModel> matches, int minutes) =>
              _bulkDuration(
                context: context,
                visible: visible,
                matches: matches,
                minutes: minutes,
                minutesPerSet: minutesPerSet,
              );

          void bulkMoveCourt(List<MatchModel> matches, ScheduleCourt court) =>
              _bulkMoveCourt(
                context: context,
                visible: visible,
                matches: matches,
                court: court,
                minutesPerSet: minutesPerSet,
              );

          void openAutoSchedule() => _showAutoScheduleSheet(
            context: context,
            divisions: divisionOptions,
            initialDivisionId: divisionId,
            scheduleSettings: scheduleSettings,
            visible: visible,
          );

          void applyDraft() => _applyDraft(context: context);

          void cancelDraft() => setState(() {
            _draftMatches = const [];
            _draftSkipped = 0;
          });

          return SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOpsMatchFilterBar(
                  context,
                  l10n,
                  selectedFilter,
                  onFilterChanged,
                ),
                TournamentScheduleCourtGrid(
                  tournamentId: widget.tournamentId,
                  matches: visible,
                  scheduleSettings: scheduleSettings,
                  selectedMatchId: focusedMatchId,
                  onTapMatch: readOnly ? null : openMatch,
                  onScheduleDrop: readOnly ? null : dropMatch,
                  onTapEmptyCell: readOnly ? null : emptyCellTap,
                  onScheduleSwap: readOnly ? null : swapMatches,
                  onAutoSchedule: readOnly ? null : openAutoSchedule,
                  draftMatches: _draftMatches,
                  draftSkippedCount: _draftSkipped,
                  draftProgress: _draftProgress,
                  onApplyDraft: readOnly ? null : applyDraft,
                  onCancelDraft: readOnly ? null : cancelDraft,
                  divisions: divisionOptions,
                  selectedDivisionId: divisionId,
                  onDivisionSelected: selectDivision,
                  onOpenFullscreen: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ScheduleFullscreenScreen(
                        tournamentId: widget.tournamentId,
                        divisionId: divisionId,
                        scheduleSettings: scheduleSettings,
                        divisions: divisionOptions,
                        onDivisionSelected: selectDivision,
                        onScheduleDrop: readOnly ? null : dropMatch,
                        onBulkSchedule: readOnly ? null : bulkSchedule,
                        onTapEmptyCell: readOnly ? null : emptyCellTap,
                        onScheduleSwap: readOnly ? null : swapMatches,
                        onBulkDuration: readOnly ? null : bulkDuration,
                        onBulkMoveCourt: readOnly ? null : bulkMoveCourt,
                        onTapMatch: readOnly ? null : openMatch,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final hasMatches = sections.any(
          (section) => section.matches.isNotEmpty,
        );
        final rowCount = hasMatches
            ? sections.fold<int>(
                0,
                (count, section) => count + 1 + section.matches.length,
              )
            : 1;
        return SliverList.builder(
          itemCount: rowCount + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildOpsMatchFilterBar(
                context,
                l10n,
                selectedFilter,
                onFilterChanged,
              );
            }
            if (!hasMatches) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _OpsReadOnlyNotice(
                  icon: Icons.filter_alt_off_outlined,
                  title: l10n.opsMatches,
                  message: l10n.opsFilteredNoMatches,
                ),
              );
            }

            var rowIndex = index - 1;
            for (final section in sections) {
              if (rowIndex == 0) {
                return _OpsMatchSectionHeader(
                  title: _opsSectionTitle(l10n, section.key),
                  count: section.matches.length,
                );
              }
              rowIndex -= 1;
              if (rowIndex < section.matches.length) {
                final match = section.matches[rowIndex];
                return _OpsMatchCard(
                  match: match,
                  bucketKey: section.key,
                  isFocused: match.id == focusedMatchId,
                  onTap: readOnly
                      ? null
                      : () => _showMatchActions(
                          context,
                          match,
                          visible: matches,
                          divisionId: divisionId,
                        ),
                );
              }
              rowIndex -= section.matches.length;
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Future<void> _showKickParticipantSheet(
    BuildContext context,
    OrganizerOpsParticipant participant,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.opsKick,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  participant.teamName,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: reasonController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.opsKickReason,
                    prefixIcon: const Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value ?? '').trim().length < 5
                      ? l10n.opsKickReason
                      : null,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setSheetState(() => submitting = true);
                          try {
                            await ref
                                .read(tournamentRepositoryProvider)
                                .kickParticipant(
                                  tournamentId: widget.tournamentId,
                                  participantId: participant.id,
                                  reason: reasonController.text.trim(),
                                );
                            if (!sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            ref.invalidate(
                              organizerOpsReadModelProvider((
                                tournamentId: widget.tournamentId,
                                divisionId: _selectedDivisionId!,
                              )),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.opsSaved)),
                            );
                          } catch (error) {
                            if (!sheetContext.mounted) return;
                            setSheetState(() => submitting = false);
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ErrorParser.parse(
                                    error,
                                    l10n.opsLoadFailed,
                                    l10n,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                  icon: submitting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_remove_outlined),
                  label: Text(l10n.opsKickConfirm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    reasonController.dispose();
  }

  Future<void> _showMatchActions(
    BuildContext context,
    MatchModel match, {
    required List<MatchModel> visible,
    required String? divisionId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (match.status.toUpperCase() == 'SCHEDULED')
              ListTile(
                leading: const Icon(Icons.play_circle_outline_rounded),
                title: Text(l10n.matchStartMatch),
                onTap: () => Navigator.pop(sheetContext, 'start'),
              ),
            ListTile(
              leading: const Icon(Icons.account_tree_outlined),
              title: Text(l10n.opsOpenBracket),
              onTap: () => Navigator.pop(sheetContext, 'bracket'),
            ),
            ListTile(
              leading: const Icon(Icons.schedule_rounded),
              title: Text(l10n.matchScheduledTime),
              onTap: () => Navigator.pop(sheetContext, 'schedule'),
            ),
            ListTile(
              leading: const Icon(Icons.scoreboard_outlined),
              title: Text(l10n.opsOpenScoreboard),
              onTap: () => Navigator.pop(sheetContext, 'score'),
            ),
            ListTile(
              leading: const Icon(Icons.gavel_rounded),
              title: Text(l10n.opsSpecialOperation),
              onTap: () => Navigator.pop(sheetContext, 'special'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;
    if (action == 'bracket') {
      final query = _selectedDivisionId == null
          ? ''
          : '?divisionId=${Uri.encodeComponent(_selectedDivisionId!)}';
      if (!context.mounted) return;
      context.push(
        '/organizer/tournaments/${widget.tournamentId}/ops/bracket$query',
      );
      return;
    }

    if (action == 'start') {
      await _confirmStartMatch(context, match);
      return;
    }

    if (action == 'score') {
      if (!context.mounted) return;
      context.push(
        '/organizer/tournaments/${widget.tournamentId}/ops/match/${match.id}',
      );
      return;
    }
    if (action == 'schedule') {
        await _showQuickScheduleSheet(
          context,
          match,
          visible: visible,
          divisionId: divisionId,
        );
      return;
    }
    await _showSpecialOperationSheet(context, match);
  }

  Future<void> _confirmStartMatch(
    BuildContext context,
    MatchModel match,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    var submitting = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.matchStartMatch),
          content: Text(l10n.matchStartHint),
          actions: [
            TextButton(
              onPressed: submitting
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: Text(l10n.matchesCancel),
            ),
            FilledButton.icon(
              onPressed: submitting
                  ? null
                  : () async {
                      setState(() => submitting = true);
                      try {
                        await ref
                            .read(matchRepositoryProvider)
                            .updateLiveState(
                              widget.tournamentId,
                              match.id,
                              status: 'ONGOING',
                            );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext, true);
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        setState(() => submitting = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              ErrorParser.parse(
                                error,
                                l10n.opsLoadFailed,
                                l10n,
                              ),
                            ),
                          ),
                        );
                      }
                    },
              icon: submitting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.matchStartMatch),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.invalidate(
        managedMatchesWithDivisionProvider((
          tournamentId: widget.tournamentId,
          divisionId: _selectedDivisionId,
        )),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.opsSaved)));
    }
  }

  Future<void> _showSpecialOperationSheet(
    BuildContext context,
    MatchModel match,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedAction = 'WALKOVER';
    var selectedWinnerId = '';
    var submitting = false;
    final operations = <String, String>{
      'WALKOVER': l10n.opsWalkover,
      'NO_SHOW': l10n.opsNoShow,
      'RETIREMENT': l10n.opsRetirement,
      'DISQUALIFICATION': l10n.opsDisqualification,
      'OVERRIDE_RESULT': l10n.opsOverrideResult,
      'POSTPONE': l10n.opsPostpone,
      'ABANDON': l10n.opsAbandon,
    };
    final winnerItems = <String, String>{
      '': l10n.opsSelectWinner,
      if (match.team1Id.isNotEmpty) match.team1Id: match.team1Name,
      if (match.team2Id.isNotEmpty) match.team2Id: match.team2Name,
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.opsSpecialOperation,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAction,
                    decoration: InputDecoration(
                      labelText: l10n.opsSpecialOperation,
                      prefixIcon: const Icon(Icons.tune_rounded),
                    ),
                    items: operations.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedAction = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedWinnerId,
                    decoration: InputDecoration(
                      labelText: l10n.opsWinner,
                      prefixIcon: const Icon(Icons.emoji_events_outlined),
                    ),
                    items: winnerItems.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    validator: (value) =>
                        selectedAction == 'OVERRIDE_RESULT' &&
                            (value == null || value.isEmpty)
                        ? l10n.opsSelectWinner
                        : null,
                    onChanged: (value) =>
                        setSheetState(() => selectedWinnerId = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reasonController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.opsOperationReason,
                      hintText: l10n.opsOperationReasonHint,
                      alignLabelWithHint: true,
                      prefixIcon: const Icon(Icons.notes_rounded),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().length < 5) {
                        return l10n.opsOperationReason;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => submitting = true);
                            try {
                              await ref
                                  .read(matchRepositoryProvider)
                                  .matchOperation(
                                    match.id,
                                    action: selectedAction,
                                    reason: reasonController.text.trim(),
                                    winnerId: selectedWinnerId.isEmpty
                                        ? null
                                        : selectedWinnerId,
                                  );
                              if (!context.mounted) return;
                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.opsSaved)),
                              );
                              ref.invalidate(
                                managedMatchesWithDivisionProvider((
                                  tournamentId: widget.tournamentId,
                                  divisionId: _selectedDivisionId,
                                )),
                              );
                            } catch (error) {
                              if (!context.mounted) return;
                              setSheetState(() => submitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ErrorParser.parse(
                                      error,
                                      l10n.opsLoadFailed,
                                      l10n,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                    icon: submitting
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.gavel_rounded),
                    label: Text(l10n.opsOperationConfirm),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    reasonController.dispose();
  }

  /// Xếp nhanh một trận: sân, ngày, giờ bắt đầu (bước 15 phút), thời lượng và
  /// trọng tài. Chồng lấn cùng sân bị chặn trước khi ghi. Gỡ lịch xoá sân, tên
  /// sân và giờ. Trận đang diễn ra hoặc đã kết thúc không đổi lịch.
  Future<void> _showQuickScheduleSheet(
    BuildContext context,
    MatchModel match, {
    required List<MatchModel> visible,
    required String? divisionId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (isScheduleLocked(match)) {
      _showScheduleMessage(messenger, l10n.scheduleQuickLocked);
      return;
    }
    final settings =
        ref
            .read(tournamentProvider(widget.tournamentId))
            .value
            ?.scheduleSettings ??
        const <String, dynamic>{};
    final minutesPerSet = (settings['minutesPerSet'] as num?)?.toInt() ?? 15;
    final courts = await _loadScheduleCourts(l10n, messenger);
    if (courts == null || !context.mounted) return;

    final startChoices = quickScheduleMinutes(
      startHour: _settingHour(settings['operatingStart'], 7),
      endHour: _settingHour(settings['operatingEnd'], 22),
    );
    final current = match.scheduledTime?.toLocal();
    final initialRefereeId = match.refereeId;
    var courtId = courts.any((court) => court.id == match.courtId)
        ? match.courtId!
        : courts.first.id;
    var day = _dayOnly(current ?? DateTime.now());
    var startMinute = current == null
        ? (startChoices.isEmpty ? 7 * 60 : startChoices.first)
        : current.hour * 60 + current.minute;
    var duration = scheduledDurationMinutes(
      match,
      minutesPerSet: minutesPerSet,
    );
    var refereeId = initialRefereeId;
    final startOptions = <int>{...startChoices, startMinute}.toList()..sort();
    final durationOptions = <int>{...scheduleDurationOptions, duration}.toList()
      ..sort();
    final readModel = _selectedDivisionId == null
        ? null
        : ref
              .read(
                organizerOpsReadModelProvider((
                  tournamentId: widget.tournamentId,
                  divisionId: _selectedDivisionId!,
                )),
              )
              .asData
              ?.value;
    final referees = <OrganizerOpsReferee>[
      ...?readModel?.referees.where(
        (referee) => referee.status?.toUpperCase() == 'ACCEPTED',
      ),
    ];
    if (initialRefereeId != null &&
        initialRefereeId.isNotEmpty &&
        !referees.any((referee) => referee.id == initialRefereeId)) {
      referees.insert(
        0,
        OrganizerOpsReferee(
          id: initialRefereeId,
          userId: initialRefereeId,
          fullName: match.refereeName ?? l10n.matchMainReferee,
          status: 'ACCEPTED',
        ),
      );
    }
    var submitting = false;
    String? error;
    final hasSchedule = current != null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> submit({
            required Future<MatchScheduleSnapshot> Function() write,
            required ScheduleSlot? requested,
          }) async {
            setSheetState(() {
              submitting = true;
              error = null;
            });
            try {
              final saved = await write();
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              ref.invalidate(
                managedMatchesWithDivisionProvider((
                  tournamentId: widget.tournamentId,
                  divisionId: divisionId,
                )),
              );
              if (divisionId != null) {
                ref.invalidate(
                  organizerOpsReadModelProvider((
                    tournamentId: widget.tournamentId,
                    divisionId: divisionId,
                  )),
                );
              }
              final moved =
                  requested != null &&
                  _serverMoved(
                    saved,
                    courtId: requested.courtId,
                    scheduledAt: requested.scheduledAt,
                  );
              _showScheduleMessage(
                messenger,
                moved ? l10n.scheduleQuickServerMoved(1) : l10n.opsSaved,
              );
            } catch (failure) {
              if (!sheetContext.mounted) return;
              setSheetState(() {
                submitting = false;
                error = ErrorParser.parse(failure, l10n.opsLoadFailed, l10n);
              });
            }
          }

          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.scheduleQuickSheetTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: courtId,
                  decoration: InputDecoration(
                    labelText: l10n.scheduleQuickCourt,
                    prefixIcon: const Icon(Icons.place_outlined),
                  ),
                  items: [
                    for (final court in courts)
                      DropdownMenuItem<String>(
                        value: court.id,
                        child: Text(
                          court.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setSheetState(() => courtId = value);
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: day,
                    );
                    if (picked == null || !context.mounted) return;
                    setSheetState(() => day = _dayOnly(picked));
                  },
                  icon: const Icon(Icons.event_rounded),
                  label: Text('${l10n.scheduleQuickDate}: ${_dateText(day)}'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: startMinute,
                  decoration: InputDecoration(
                    labelText: l10n.scheduleQuickStart,
                    prefixIcon: const Icon(Icons.schedule_rounded),
                  ),
                  items: [
                    for (final minute in startOptions)
                      DropdownMenuItem<int>(
                        value: minute,
                        child: Text(_hhmm(minute)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => startMinute = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: duration,
                  decoration: InputDecoration(
                    labelText: l10n.scheduleQuickDuration,
                    prefixIcon: const Icon(Icons.timer_outlined),
                  ),
                  items: [
                    for (final minutes in durationOptions)
                      DropdownMenuItem<int>(
                        value: minutes,
                        child: Text(l10n.scheduleQuickMinutes(minutes)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setSheetState(() => duration = value);
                  },
                ),
                if (referees.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: refereeId,
                    decoration: InputDecoration(
                      labelText: l10n.matchMainReferee,
                      prefixIcon: const Icon(Icons.sports_outlined),
                    ),
                    items: [
                      for (final referee in referees)
                        DropdownMenuItem<String>(
                          value: referee.id,
                          child: Text(
                            referee.email == null || referee.email!.isEmpty
                                ? referee.fullName
                                : '${referee.fullName} · ${referee.email}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => refereeId = value),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: submitting
                      ? null
                      : () {
                          final scheduledAt = DateTime(
                            day.year,
                            day.month,
                            day.day,
                            startMinute ~/ 60,
                            startMinute % 60,
                          );
                          final chosen = courts.firstWhere(
                            (court) => court.id == courtId,
                          );
                          if (_overlapsAfter(
                            visible: visible,
                            planned: {
                              match.id: (
                                court: chosen.name,
                                at: scheduledAt,
                                minutes: duration,
                              ),
                            },
                            minutesPerSet: minutesPerSet,
                          )) {
                            setSheetState(
                              () => error = l10n.scheduleQuickClash,
                            );
                            return;
                          }
                          submit(
                            write: () => ref
                                .read(matchRepositoryProvider)
                                .updateSchedule(
                                  widget.tournamentId,
                                  match.id,
                                  courtId: chosen.id,
                                  courtName: chosen.name,
                                  scheduledAt: scheduledAt,
                                  refereeId: refereeId,
                                  durationMinutes: duration,
                                ),
                            requested: ScheduleSlot(
                              courtId: chosen.id,
                              courtName: chosen.name,
                              scheduledAt: scheduledAt,
                            ),
                          );
                        },
                  icon: submitting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(l10n.matchSaveChanges),
                ),
                if (hasSchedule) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: submitting
                        ? null
                        : () => submit(
                            write: () => ref
                                .read(matchRepositoryProvider)
                                .updateSchedule(
                                  widget.tournamentId,
                                  match.id,
                                  clear: const {
                                    MatchScheduleField.courtId,
                                    MatchScheduleField.courtName,
                                    MatchScheduleField.scheduledAt,
                                  },
                                ),
                            requested: null,
                          ),
                    icon: const Icon(Icons.event_busy_outlined),
                    label: Text(l10n.scheduleQuickClear),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String? _resolveDivisionId(List<_OpsDivision> divisions) {
    if (divisions.isEmpty) return null;
    if (_selectedDivisionId == null && widget.initialDivisionId != null) {
      _selectedDivisionId = widget.initialDivisionId;
    }
    if (_selectedDivisionId != null &&
        divisions.any((division) => division.id == _selectedDivisionId)) {
      return _selectedDivisionId;
    }
    return divisions.first.id;
  }

  bool _isReadOnlyTournament(String status) {
    return {
      'COMPLETED',
      'CANCELLED',
      'CANCELED',
      'ARCHIVED',
      'PENDING_DELETE',
    }.contains(status.trim().toUpperCase());
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}

class _OpsScaffold extends StatelessWidget {
  const _OpsScaffold({
    required this.title,
    required this.onBack,
    required this.body,
    this.subtitle,
    this.actions,
    this.isEmbedded = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget body;
  final List<Widget>? actions;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final actions = this.actions;
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: isEmbedded
          ? null
          : AppBar(
              backgroundColor: colors.bgDark,
              leading: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_rounded),
              ),
              titleSpacing: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 10, color: colors.textMuted),
                    ),
                ],
              ),
              actions: actions,
            ),
      body: isEmbedded && actions != null && actions.isNotEmpty
          ? Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions,
                    ),
                  ),
                ),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }
}

class _OpsContextHeader extends StatelessWidget {
  const _OpsContextHeader({
    required this.tournament,
    required this.division,
    required this.colors,
  });

  final Tournament tournament;
  final _OpsDivision division;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = tournament.status.toUpperCase();
    final statusColor = status == 'IN_PROGRESS' || status == 'ONGOING'
        ? colors.info
        : status == 'COMPLETED'
        ? colors.success
        : colors.warning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: context.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tournament.sport.isEmpty ? 'Sport' : tournament.sport,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _OpsStatusPill(label: status, color: statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              division.name,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.opsDivision}: ${division.matchType}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.opsContextHint,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpsDivisionSelector extends StatelessWidget {
  const _OpsDivisionSelector({
    required this.divisions,
    required this.selectedDivisionId,
    required this.onChanged,
  });

  final List<_OpsDivision> divisions;
  final String? selectedDivisionId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    if (divisions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: _OpsReadOnlyNotice(
          icon: Icons.category_outlined,
          title: l10n.opsDivision,
          message: l10n.opsEmptyDivision,
        ),
      );
    }

    return SizedBox(
      height: 76,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        scrollDirection: Axis.horizontal,
        itemCount: divisions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final division = divisions[index];
          final selected = division.id == selectedDivisionId;
          return Semantics(
            button: true,
            selected: selected,
            label: division.name,
            child: InkWell(
              onTap: () => onChanged(division.id),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                constraints: const BoxConstraints(minWidth: 112),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppTheme.primary : colors.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      division.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      division.matchType,
                      style: TextStyle(
                        color: selected ? Colors.white70 : colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OpsTabBar extends StatelessWidget {
  const _OpsTabBar({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (l10n.opsOverview, Icons.dashboard_outlined),
      (l10n.opsMatches, Icons.sports_score_outlined),
      (l10n.opsBracket, Icons.account_tree_outlined),
      (l10n.opsRoster, Icons.people_alt_outlined),
      (l10n.opsActivity, Icons.history_rounded),
      (l10n.opsCamera, Icons.videocam_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              ChoiceChip(
                selected: selectedIndex == index,
                onSelected: (_) => onChanged(index),
                avatar: Icon(items[index].$2, size: 16),
                label: Text(items[index].$1),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpsOverview extends StatelessWidget {
  const _OpsOverview({
    required this.tournament,
    required this.divisions,
    required this.matchesAsync,
    required this.readOnly,
  });

  final Tournament tournament;
  final List<_OpsDivision> divisions;
  final AsyncValue<List<MatchModel>> matchesAsync;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final matches = matchesAsync.asData?.value ?? const <MatchModel>[];
    final scheduled = matches
        .where((match) => match.scheduledTime != null)
        .length;
    final ongoing = matches.where((match) {
      final status = match.status.toUpperCase();
      return status == 'ONGOING' || status == 'IN_PROGRESS' || status == 'LIVE';
    }).length;
    final completed = matches.where((match) {
      final status = match.status.toUpperCase();
      return status == 'COMPLETED' || status == 'FINISHED';
    }).length;
    final needsAttention = matches.where((match) {
      final missingSchedule = match.scheduledTime == null;
      final missingSide = match.team1Name == 'TBD' || match.team2Name == 'TBD';
      return missingSchedule || missingSide;
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.opsOverview,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            readOnly ? l10n.opsReadOnlyHint : l10n.opsContextHint,
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _OpsMetric(
                icon: Icons.category_outlined,
                label: l10n.opsDivision,
                value: '${divisions.length}',
                color: AppTheme.primary,
              ),
              _OpsMetric(
                icon: Icons.schedule_rounded,
                label: l10n.opsScheduled,
                value: '$scheduled',
                color: colors.info,
              ),
              _OpsMetric(
                icon: Icons.play_circle_outline_rounded,
                label: l10n.opsOngoing,
                value: '$ongoing',
                color: colors.warning,
              ),
              _OpsMetric(
                icon: Icons.check_circle_outline_rounded,
                label: l10n.opsCompleted,
                value: '$completed',
                color: colors.success,
              ),
              _OpsMetric(
                icon: Icons.priority_high_rounded,
                label: l10n.opsAttention,
                value: '$needsAttention',
                color: needsAttention > 0 ? colors.error : colors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _OpsReadOnlyNotice(
            icon: readOnly
                ? Icons.lock_outline_rounded
                : Icons.info_outline_rounded,
            title: l10n.opsOrganizerOnly,
            message: readOnly ? l10n.opsReadOnlyHint : l10n.opsContextHint,
          ),
        ],
      ),
    );
  }
}

class _OpsMetric extends StatelessWidget {
  const _OpsMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 108,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpsMatchSectionData {
  const _OpsMatchSectionData({required this.key, required this.matches});

  final String key;
  final List<MatchModel> matches;
}

class _OpsMatchSectionHeader extends StatelessWidget {
  const _OpsMatchSectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpsMatchCard extends StatelessWidget {
  const _OpsMatchCard({
    required this.match,
    required this.bucketKey,
    this.isFocused = false,
    this.onTap,
  });

  final MatchModel match;
  final String bucketKey;
  final bool isFocused;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final status = match.status.toUpperCase();
    final isCompleted = bucketKey == 'completed';
    final statusLabel = switch (bucketKey) {
      'ongoing' => l10n.opsOngoing,
      'scheduled' => l10n.opsScheduled,
      'completed' => l10n.opsCompleted,
      'attention' => l10n.opsAttention,
      _ => status,
    };
    final statusColor = isCompleted
        ? colors.success
        : bucketKey == 'ongoing'
        ? colors.info
        : colors.warning;
    final groupName = match.groupName?.trim();
    final isRoundRobin = isGroupStageMatch(match);
    final contextLabel = isRoundRobin
        ? groupName?.isNotEmpty == true
              ? l10n.crossTableLegTitle(
                  MatchRoundLabel.formatStageOrGroupName(groupName, l10n: l10n),
                  match.leg ?? 1,
                )
              : '#${match.matchNumber}'
        : l10n.organizer_matchTitle(match.round, match.matchNumber);
    final scheduledLabel = match.scheduledTime == null
        ? l10n.opsUnscheduled
        : '${MaterialLocalizations.of(context).formatFullDate(match.scheduledTime!.toLocal())} '
              '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(match.scheduledTime!.toLocal()), alwaysUse24HourFormat: true)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused ? AppTheme.primary : colors.border,
              width: isFocused ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      contextLabel,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _OpsStatusPill(label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.team1Name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${match.score1} : ${match.score2}',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      match.team2Name,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _OpsMeta(icon: Icons.schedule_rounded, text: scheduledLabel),
                  if (match.court.isNotEmpty)
                    _OpsMeta(icon: Icons.place_outlined, text: match.court),
                  if (match.refereeName != null &&
                      match.refereeName!.isNotEmpty)
                    _OpsMeta(
                      icon: Icons.sports_rounded,
                      text: match.refereeName!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpsRosterFilterBar extends StatelessWidget {
  const _OpsRosterFilterBar({
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = <(String, String)>[
      ('ALL', l10n.opsFilterAll),
      ('PAID', l10n.opsFilterPaid),
      ('UNPAID', l10n.opsFilterUnpaid),
      ('KICKED', l10n.opsFilterKicked),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.opsSearchRoster,
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < filters.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  ChoiceChip(
                    selected: selectedFilter == filters[index].$1,
                    onSelected: (_) => onChanged(filters[index].$1),
                    label: Text(filters[index].$2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpsActivityCard extends StatelessWidget {
  const _OpsActivityCard({required this.entry});

  final OrganizerOpsAuditEntry entry;

  String _friendlyAction(AppLocalizations l10n) {
    final source = '${entry.action} ${entry.tableName}'.toUpperCase();
    if (source.contains('KICK') || source.contains('REMOV')) {
      return l10n.opsKick;
    }
    if (source.contains('SCHEDULE') || source.contains('COURT')) {
      return l10n.matchScheduledTime;
    }
    if (source.contains('BRACKET')) {
      return l10n.opsOpenBracket;
    }
    if (source.contains('REFEREE')) {
      return l10n.matchMainReferee;
    }
    if (source.contains('MATCH') ||
        source.contains('SCORE') ||
        source.contains('STATUS')) {
      return l10n.opsMatches;
    }
    return l10n.opsAudit;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final localTime = entry.createdAt.toLocal();
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(localTime);
    final timeLabel = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(localTime));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.history_rounded, color: colors.info, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _friendlyAction(l10n),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.opsContextHint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${entry.actorName ?? l10n.opsOrganizerOnly} • $dateLabel $timeLabel',
                    style: TextStyle(color: colors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpsParticipantCard extends StatelessWidget {
  const _OpsParticipantCard({required this.participant, this.onKick});

  final OrganizerOpsParticipant participant;
  final VoidCallback? onKick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final statusColor = participant.isKicked
        ? colors.error
        : participant.isDisciplined
        ? colors.warning
        : colors.success;
    final memberNames = participant.members
        .map((member) => member.fullName)
        .where((name) => name.trim().isNotEmpty)
        .join(' • ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    participant.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _OpsStatusPill(
                  label: participant.teamStatus,
                  color: statusColor,
                ),
              ],
            ),
            if (memberNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                memberNames,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _OpsMeta(
                  icon: participant.isPaid
                      ? Icons.verified_rounded
                      : Icons.pending_outlined,
                  text: participant.isPaid
                      ? l10n.payments_statusSuccess
                      : l10n.payments_statusPending,
                ),
                if (participant.seed != null)
                  _OpsMeta(
                    icon: Icons.numbers_rounded,
                    text: 'Seed ${participant.seed}',
                  ),
              ],
            ),
            if (onKick != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onKick,
                  icon: const Icon(Icons.person_remove_outlined, size: 18),
                  label: Text(l10n.opsKick),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpsBracketPreview extends StatelessWidget {
  const _OpsBracketPreview({
    required this.tournamentId,
    this.divisionId,
    required this.readOnly,
  });

  final String tournamentId;
  final String? divisionId;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OpsReadOnlyNotice(
            icon: Icons.account_tree_outlined,
            title: l10n.opsBracket,
            message: l10n.opsContextHint,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: readOnly
                ? null
                : () {
                    final query = divisionId == null
                        ? ''
                        : '?divisionId=${Uri.encodeComponent(divisionId!)}';
                    context.push(
                      '/organizer/tournaments/$tournamentId/ops/bracket$query',
                    );
                  },
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(l10n.opsOpenBracket),
          ),
        ],
      ),
    );
  }
}

class _OpsStatusPill extends StatelessWidget {
  const _OpsStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OpsMeta extends StatelessWidget {
  const _OpsMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.colors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: context.colors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

class _OpsReadOnlyNotice extends StatelessWidget {
  const _OpsReadOnlyNotice({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpsLoadingBody extends StatelessWidget {
  const _OpsLoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 72,
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ],
    );
  }
}

class _OpsInlineLoading extends StatelessWidget {
  const _OpsInlineLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _OpsErrorBody extends StatelessWidget {
  const _OpsErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: context.colors.error,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.opsRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpsDivision {
  const _OpsDivision({
    required this.id,
    required this.name,
    required this.matchType,
    this.entryFee,
    this.effectiveEntryFee,
  });

  final String id;
  final String name;
  final String matchType;
  final double? entryFee;
  final double? effectiveEntryFee;

  factory _OpsDivision.fromJson(Map<String, dynamic> json) {
    return _OpsDivision(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Division',
      matchType: json['matchType']?.toString() ?? 'SINGLES',
      entryFee: _toDouble(json['entryFee']),
      effectiveEntryFee: _toDouble(json['effectiveEntryFee']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
