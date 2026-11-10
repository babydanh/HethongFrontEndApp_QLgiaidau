import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/core/widgets/responsive_layout.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/features/teams/screens/team_list_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_divisions_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_section_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/tournament_step_summary.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_strip.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lifecycle_end_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lifecycle_stepper.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/overview_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_board.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_reconfirm_card.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/step_detail_popup.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_athletes_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_header.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_edit_popup.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_report_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_tab_bar_delegate.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/step_summary_provider.dart';
import 'package:app_quanly_giaidau/providers/tournament_action_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/tournament_contact.dart';

class TournamentManagementHubScreen extends ConsumerStatefulWidget {
  const TournamentManagementHubScreen({
    super.key,
    required this.tournament,
    required this.actionRouteBase,
    required this.opsWorkspaceRoute,
    this.liteWorkspaceRoute,
  });

  final Tournament tournament;
  final String actionRouteBase;
  final String opsWorkspaceRoute;
  final String? liteWorkspaceRoute;

  @override
  ConsumerState<TournamentManagementHubScreen> createState() =>
      _TournamentManagementHubScreenState();
}

class _TournamentManagementHubScreenState
    extends ConsumerState<TournamentManagementHubScreen>
    with SingleTickerProviderStateMixin {
  static const _setupSections = [
    TournamentManagementSection.information,
    TournamentManagementSection.schedule,
    TournamentManagementSection.registration,
  ];
  static const _otherSections = [
    TournamentManagementSection.sponsors,
    TournamentManagementSection.finance,
    TournamentManagementSection.livestream,
    TournamentManagementSection.permissions,
  ];

  late final TabController _tabController = TabController(
    length: _HubTab.values.length,
    vsync: this,
  );
  late final ScrollController _scrollController = ScrollController()
    ..addListener(_onScroll);
  final SliverOverlapAbsorberHandle _tabStripOverlapHandle =
      SliverOverlapAbsorberHandle();

  TournamentManagementSection _selectedSection =
      TournamentManagementSection.information;
  TournamentManagementSection? _openedSection;

  /// Division picked in any of the bracket, schedule or athletes tabs; they
  /// all show it. Null until someone picks one (each tab then defaults itself).
  String? _divisionId;

  /// Chip the "Kết quả" board opens on, and a counter that rebuilds the board
  /// each time something asks for it (so the chip also applies when the tab is
  /// already open).
  ResultsBoardFilter _resultsFilter = ResultsBoardFilter.all;
  int _resultsRequest = 0;

  /// True from the tap on a progress step until its popup is closed, so a
  /// double tap opens one popup only.
  bool _stepPopupBusy = false;

  /// True while the open section page holds edits that are not saved yet.
  final ValueNotifier<bool> _unsavedChanges = ValueNotifier<bool>(false);
  bool _isCollapsed = false;
  bool _isTabBarPinned = false;
  bool _isExporting = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _unsavedChanges.dispose();
    _tabStripOverlapHandle.dispose();
    super.dispose();
  }

  void _onScroll() {
    final collapsed =
        _scrollController.hasClients && _scrollController.offset >= 110.0;
    final maxScroll = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final tabPinned =
        _scrollController.hasClients &&
        maxScroll > 0 &&
        _scrollController.offset >= (maxScroll - 2.0);
    if (collapsed != _isCollapsed || tabPinned != _isTabBarPinned) {
      setState(() {
        _isCollapsed = collapsed;
        _isTabBarPinned = tabPinned;
      });
    }
  }

  void _selectDivision(String id) {
    if (id == _divisionId) return;
    setState(() => _divisionId = id);
  }

  /// Opens the "Kết quả" tab, optionally on one chip and one division.
  void _goToResults({ResultsBoardFilter? filter, String? divisionId}) {
    setState(() {
      if (divisionId != null) _divisionId = divisionId;
      _resultsFilter = filter ?? ResultsBoardFilter.all;
      _resultsRequest++;
    });
    _tabController.animateTo(_HubTab.results.index);
  }

  /// Opens the popup of the tapped progress step (0..3) with fresh numbers.
  Future<void> _openStep(int index) async {
    if (_stepPopupBusy || index < 0 || index >= StepKey.values.length) return;
    _stepPopupBusy = true;
    var reload = false;
    try {
      final summary = await loadStepSummary(ref, widget.tournament);
      if (!mounted) return;
      await showStepDetailPopup(
        context,
        step: StepKey.values[index],
        summary: summary,
        onGo: _goToStepTarget,
        onRetry: () => reload = true,
      );
    } finally {
      _stepPopupBusy = false;
    }
    // "Tải lại": the popup is closed now, so read the numbers again and reopen.
    if (reload && mounted) {
      ref.invalidate(organizerParticipantsProvider(widget.tournament.id));
      ref.invalidate(
        managedMatchesWithDivisionProvider((
          tournamentId: widget.tournament.id,
          divisionId: null,
        )),
      );
      await _openStep(index);
    }
  }

  /// Handles "Đi tới" / "Mở" from a step popup: same tab names in both enums.
  void _goToStepTarget(StepTarget target) {
    if (!mounted) return;
    if (target.tab == StepHubTab.results) {
      _goToResults(filter: target.resultsFilter, divisionId: target.divisionId);
      return;
    }
    final divisionId = target.divisionId;
    if (divisionId != null) _selectDivision(divisionId);
    _tabController.animateTo(_HubTab.values.byName(target.tab.name).index);
  }

  void _openSection(TournamentManagementSection section) {
    // Divisions have their own tab instead of a settings page.
    if (section == TournamentManagementSection.divisions) {
      _tabController.animateTo(_HubTab.divisions.index);
      return;
    }
    final isTablet = !ResponsiveLayout.isMobile(context);
    setState(() {
      _selectedSection = section;
      if (!isTablet) _openedSection = section;
    });
    if (isTablet) _tabController.animateTo(_HubTab.settings.index);
  }

  /// Edits the tapped item in its own popup instead of opening a page.
  void _editPopup(TournamentManagementFocus focus) {
    showTournamentEditPopup(
      context,
      tournament: widget.tournament,
      focus: focus,
      opsWorkspaceRoute: widget.opsWorkspaceRoute,
      actionRouteBase: widget.actionRouteBase,
    );
  }

  /// Leaving a page with unsaved edits asks first; otherwise closes at once.
  Future<void> _closeSection() async {
    if (_unsavedChanges.value) {
      final l10n = AppLocalizations.of(context)!;
      final discard = await confirmTournamentManagementAction(
        context,
        title: l10n.tournamentManagementDiscardTitle,
        message: l10n.tournamentManagementDiscardMessage,
        confirmLabel: l10n.tournamentManagementDiscardConfirm,
        destructive: true,
      );
      if (!discard || !mounted) return;
      _unsavedChanges.value = false;
    }
    setState(() => _openedSection = null);
  }

  /// Persists founder visibility like the Web manage page. The server replaces
  /// the whole `contactInfo` JSON, so the existing keys are sent back with it.
  Future<void> _setFounderHidden(bool hidden) async {
    final id = widget.tournament.id;
    final messenger = ScaffoldMessenger.of(context);
    final errorText = AppLocalizations.of(
      context,
    )!.tournamentManagementSaveError;
    try {
      await ref.read(tournamentManagementRepositoryProvider).updateTournament(
        id,
        {
          'contactInfo': founderVisibilityPatch(
            widget.tournament.contactInfo,
            hidden: hidden,
          ),
        },
      );
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(errorText)));
      return;
    }
    // The hub may have been closed while the request was in flight.
    if (!mounted) return;
    ref.invalidate(tournamentProvider(id));
  }

  /// Banner eye: hides or shows the text on the tournament's featured card.
  Future<void> _setCardTextHidden(bool hide) async {
    final id = widget.tournament.id;
    final messenger = ScaffoldMessenger.of(context);
    final errorText = AppLocalizations.of(
      context,
    )!.tournamentManagementSaveError;
    try {
      await ref.read(tournamentManagementRepositoryProvider).updateTournament(
        id,
        {
          'tournamentConfig': {
            ...widget.tournament.tournamentConfig,
            'hideFeaturedCardText': hide,
          },
        },
      );
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(errorText)));
      return;
    }
    if (!mounted) return;
    ref.invalidate(tournamentProvider(id));
  }

  String _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${AppConstants.appDomain}$url';
  }

  @override
  Widget build(BuildContext context) {
    final tournament = widget.tournament;
    final l10n = AppLocalizations.of(context)!;
    // Kết thúc giải hiển thị theo trạng thái giải (đang thi đấu); phân quyền
    // do backend chốt — organizer/co-organizer cũng kết thúc được, lỗi 403
    // hiển thị nguyên văn trong sheet (OpenSpec quan-ly-giai-web-parity).
    final canFinalize =
        tournament.status.toUpperCase() ==
        AppConstants.statusInProgress.toUpperCase();
    final teamCount =
        ref.watch(introTeamsProvider(tournament.id)).value?.length ?? 0;
    final openedSection = _openedSection;

    return PopScope(
      canPop: openedSection == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSection();
      },
      child: Scaffold(
        backgroundColor: context.colors.bgDark,
        body: IndexedStack(
          index: openedSection == null ? 0 : 1,
          sizing: StackFit.expand,
          children: [
            _buildTabsView(context, l10n, canFinalize, teamCount),
            if (openedSection != null)
              _buildSectionPage(context, l10n, canFinalize, openedSection)
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionPage(
    BuildContext context,
    AppLocalizations l10n,
    bool canFinalize,
    TournamentManagementSection section,
  ) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: l10n.tournamentManagementBack,
          onPressed: _closeSection,
        ),
        title: Text(_sectionDetails(l10n, section).title),
        actions: [_buildOverflowMenu(context, l10n, canFinalize: canFinalize)],
      ),
      body: _buildDetailView(context),
    );
  }

  Widget _buildTabsView(
    BuildContext context,
    AppLocalizations l10n,
    bool canFinalize,
    int teamCount,
  ) {
    final tournament = widget.tournament;
    final colors = context.colors;
    final topPadding = MediaQuery.paddingOf(context).top;
    final isClubLite = tournament.isClubLite;
    final showsSolidBar = _isCollapsed || isClubLite;
    final iconColor = showsSolidBar ? colors.textPrimary : Colors.white;
    final List<Shadow>? iconShadows = showsSolidBar
        ? null
        : [
            Shadow(
              offset: const Offset(0, 1),
              blurRadius: 4.0,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ];

    return NestedScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      headerSliverBuilder: (headerContext, _) => [
        SliverOverlapAbsorber(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
            headerContext,
          ),
          sliver: SliverAppBar(
            pinned: true,
            primary: true,
            toolbarHeight: 44,
            expandedHeight: isClubLite ? 44 + topPadding : 180 + topPadding,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: showsSolidBar ? colors.bgDark : Colors.transparent,
            iconTheme: IconThemeData(color: iconColor, opacity: 1.0),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: iconColor,
                shadows: iconShadows,
              ),
              tooltip: l10n.tournamentManagementBack,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
            ),
            title: AnimatedOpacity(
              opacity: showsSolidBar ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              child: Text(l10n.managementTitle),
            ),
            actions: [
              _buildOverflowMenu(
                context,
                l10n,
                canFinalize: canFinalize,
                iconColor: iconColor,
                iconShadows: iconShadows,
              ),
            ],
            flexibleSpace: isClubLite
                ? null
                : FlexibleSpaceBar(
                    // Pinned, not parallax: the parallax shift slides the banner's
                    // lower edge (logo, edit button) out of the visible frame.
                    collapseMode: CollapseMode.pin,
                    background: TournamentManagementBanner(
                      tournament: tournament,
                      resolveImageUrl: _resolveImageUrl,
                      onEdit: () =>
                          _editPopup(TournamentManagementFocus.branding),
                      onToggleCardText: _setCardTextHidden,
                    ),
                  ),
          ),
        ),
        // Đệm chiều cao toolbar: không có đệm này tên giải nằm dưới app bar.
        SliverToBoxAdapter(child: SizedBox(height: 44 + topPadding)),
        SliverToBoxAdapter(
          child: TournamentManagementSummary(
            tournament: tournament,
            onEditInformation: () =>
                _editPopup(TournamentManagementFocus.name),
          ),
        ),
        // Step bar + the one next-step button, as at the top of the Web page.
        SliverToBoxAdapter(
          child: TournamentLifecycleCard(
            tournament: tournament,
            onStepTap: _openStep,
          ),
        ),
        SliverToBoxAdapter(
          child: ResultsReconfirmCard(
            tournamentId: tournament.id,
            status: tournament.status,
          ),
        ),
        SliverOverlapAbsorber(
          handle: _tabStripOverlapHandle,
          sliver: SliverPersistentHeader(
            pinned: true,
            delegate: TournamentTabBarDelegate(
              tabController: _tabController,
              colors: colors,
              tabHeaders: [
                Tab(text: l10n.tournamentManagementOverview),
                Tab(text: l10n.tournamentManagementTabDivisions),
                Tab(text: l10n.tournamentManagementTabAthletes),
                Tab(text: l10n.tournamentManagementTabBracket),
                Tab(text: l10n.tournamentManagementSchedule),
                Tab(text: l10n.tournamentManagementTabResults),
                Tab(text: l10n.tournamentManagementTabSettings),
              ],
            ),
          ),
        ),
      ],
      body: Builder(
        builder: (bodyContext) {
          final overlapHandles = [
            if (_isTabBarPinned)
              NestedScrollView.sliverOverlapAbsorberHandleFor(bodyContext),
            _tabStripOverlapHandle,
          ];
          return TabBarView(
            controller: _tabController,
            children: [
              OverviewTab(
                tournament: tournament,
                teamCount: teamCount,
                resolveImageUrl: _resolveImageUrl,
                hasSliverBanner: true,
                compact: true,
                overlapHandles: overlapHandles,
                onEditInformation: () =>
                    _openSection(TournamentManagementSection.information),
                onEditBranding: () =>
                    _editPopup(TournamentManagementFocus.branding),
                onEditContact: () =>
                    _editPopup(TournamentManagementFocus.contact),
                onEditSchedule: () =>
                    _editPopup(TournamentManagementFocus.venue),
                onEditRegistration: () =>
                    _openSection(TournamentManagementSection.registration),
                onEditTimelineDate: _editPopup,
                onEditFinance: () => _editPopup(TournamentManagementFocus.fee),
                onToggleFounderHidden: _setFounderHidden,
              ),
              CustomScrollView(
                slivers: [
                  ...overlapHandles.map(
                    (handle) => SliverOverlapInjector(handle: handle),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: PrimaryScrollController.none(
                      child: TournamentManagementDivisionsSection(
                        tournament: tournament,
                      ),
                    ),
                  ),
                ],
              ),
              CustomScrollView(
                slivers: [
                  ...overlapHandles.map(
                    (handle) => SliverOverlapInjector(handle: handle),
                  ),
                  SliverToBoxAdapter(
                    child: TournamentManagementAthletesTab(
                      tournament: tournament,
                      selectedDivisionId: _divisionId,
                      onDivisionChanged: _selectDivision,
                    ),
                  ),
                ],
              ),
              CustomScrollView(
                slivers: [
                  ...overlapHandles.map(
                    (handle) => SliverOverlapInjector(handle: handle),
                  ),
                  SliverToBoxAdapter(
                    child: BracketViewScreen(
                      tournamentId: tournament.id,
                      isEmbedded: true,
                      canEditBracket: true,
                      selectedDivisionId: _divisionId,
                      onDivisionChanged: _selectDivision,
                    ),
                  ),
                ],
              ),
              OrganizerOpsScreen(
                tournamentId: tournament.id,
                isEmbedded: true,
                view: OrganizerOpsView.matches,
                initialMatchesView: OrganizerOpsMatchesView.grid,
                selectedDivisionId: _divisionId,
                onDivisionChanged: (id) {
                  if (id != null) _selectDivision(id);
                },
                overlapHandles: overlapHandles,
              ),
              _buildResultsTab(tournament, overlapHandles),
              _buildSettingsTab(context, overlapHandles),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultsTab(
    Tournament tournament,
    List<SliverOverlapAbsorberHandle> overlapHandles,
  ) {
    final divisions = tournament.divisions;
    final hosted = _divisionId;
    final activeId = divisions.any((d) => d.id == hosted)
        ? hosted
        : (divisions.isEmpty ? null : divisions.first.id);
    return CustomScrollView(
      slivers: [
        ...overlapHandles.map(
          (handle) => SliverOverlapInjector(handle: handle),
        ),
        if (divisions.length > 1)
          SliverToBoxAdapter(
            child: DivisionStrip(
              keyPrefix: 'results-division',
              items: [
                for (final d in divisions)
                  DivisionStripItem(
                    id: d.id,
                    name: d.name,
                    count: d.participantCount,
                    capacity: (d.maxParticipants ?? 0) > 0
                        ? d.maxParticipants
                        : null,
                  ),
              ],
              selectedId: activeId,
              onChanged: (id) {
                if (id != null) _selectDivision(id);
              },
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 140),
          sliver: SliverToBoxAdapter(
            child: ResultsMatchBoard(
              key: ValueKey('results-board-$activeId-$_resultsRequest'),
              tournamentId: tournament.id,
              isLite: false,
              canManage: true,
              divisionId: activeId,
              initialFilter: _resultsFilter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(
    BuildContext context,
    List<SliverOverlapAbsorberHandle> overlapHandles,
  ) {
    final colors = context.colors;
    return ResponsiveLayout(
      mobile: _buildSettingsList(
        context,
        isTablet: false,
        overlapHandles: overlapHandles,
      ),
      tablet: CustomScrollView(
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          ...overlapHandles.map(
            (handle) => SliverOverlapInjector(handle: handle),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Row(
              children: [
                SizedBox(
                  width: 360,
                  child: _buildSettingsList(context, isTablet: true),
                ),
                VerticalDivider(width: 1, color: colors.border),
                Expanded(
                  child: PrimaryScrollController.none(
                    child: _buildDetailView(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(
    BuildContext context, {
    required bool isTablet,
    List<SliverOverlapAbsorberHandle> overlapHandles = const [],
  }) {
    final l10n = AppLocalizations.of(context)!;
    return CustomScrollView(
      primary: !isTablet,
      slivers: [
        ...overlapHandles.map(
          (handle) => SliverOverlapInjector(handle: handle),
        ),
        // Design 1: two flat groups, "THIẾT LẬP" and "HỆ THỐNG".
        SliverList.list(
          children: [
            LavishGroupHeader(l10n.tournamentManagementSetupGroup),
            for (final section in _setupSections)
              _buildSectionAction(context, l10n, isTablet, section),
            LavishGroupHeader(l10n.tournamentManagementSystemGroup),
            for (final section in _otherSections)
              _buildSectionAction(context, l10n, isTablet, section),
          ],
        ),
        // Full width: the lifecycle block carries its own 14dp gutters.
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 24),
          sliver: SliverToBoxAdapter(
            child: TournamentLifecycleCard(
              tournament: widget.tournament,
              showLifecycle: false,
              onShare: _shareTournament,
              onDelete: _deleteTournament,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(BuildContext context) {
    final tournament = widget.tournament;
    switch (_selectedSection) {
      case TournamentManagementSection.teams:
        return TeamListScreen(
          tournamentId: tournament.id,
          isEmbedded: true,
          managementRouteBase: widget.actionRouteBase,
        );
      default:
        return TournamentManagementSectionScreen(
          tournament: tournament,
          section: _selectedSection,
          opsWorkspaceRoute: widget.opsWorkspaceRoute,
          actionRouteBase: widget.actionRouteBase,
          unsavedChanges: _unsavedChanges,
        );
    }
  }

  Widget _buildOverflowMenu(
    BuildContext context,
    AppLocalizations l10n, {
    required bool canFinalize,
    Color? iconColor,
    List<Shadow>? iconShadows,
  }) {
    final colors = context.colors;
    final tournament = widget.tournament;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: iconColor, shadows: iconShadows),
      tooltip: l10n.tournamentManagementSystemGroup,
      color: colors.bgCard,
      onSelected: (value) {
        switch (value) {
          case 'export':
            _exportTournamentData();
            break;
          case 'export-participants':
            _exportParticipantsRoster();
            break;
          case 'report':
            TournamentReportSheet.show(context, onExport: _exportReport);
            break;
          case 'end':
            _finalizeTournament();
            break;
          case 'lite':
            final route = widget.liteWorkspaceRoute;
            if (route != null) context.push(route);
            break;
          case 'delete':
            _deleteTournament();
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'export',
          enabled: !_isExporting,
          child: Row(
            children: [
              Icon(
                _isExporting
                    ? Icons.hourglass_top_rounded
                    : Icons.download_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
              Flexible(
                child: Text(
                  _isExporting ? l10n.exportingExcel : l10n.exportData,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'export-participants',
          enabled: !_isExporting,
          child: Row(
            children: [
              Icon(
                _isExporting
                    ? Icons.hourglass_top_rounded
                    : Icons.groups_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isExporting
                      ? l10n.exportingExcel
                      : l10n.exportParticipantsRoster,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'report',
          enabled: !_isExporting,
          child: Row(
            children: [
              Icon(Icons.summarize_outlined, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.tournamentReportMenu,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (canFinalize)
          PopupMenuItem(
            value: 'end',
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: colors.success,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.endTournament,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        if (widget.liteWorkspaceRoute != null && tournament.isSuperLite)
          PopupMenuItem(
            value: 'lite',
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: AppTheme.secondary, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.lite_managementTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          enabled: !_isDeleting,
          child: Row(
            children: [
              Icon(Icons.delete, color: colors.error, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.deleteTournament,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.error),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionAction(
    BuildContext context,
    AppLocalizations l10n,
    bool isTablet,
    TournamentManagementSection section,
  ) {
    final details = _sectionDetails(l10n, section);
    return LavishRow(
      leading: LavishIconBox(
        tone: _sectionTone(section),
        child: Icon(details.icon),
      ),
      title: details.title,
      subtitle: details.subtitle,
      background: isTablet && _selectedSection == section
          ? LavishColors.of(context).soft(LavishTone.accent)
          : null,
      trailing: [
        Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: LavishColors.of(context).faint,
        ),
      ],
      onTap: () {
        if (isTablet) {
          setState(() => _selectedSection = section);
        } else {
          _openSection(section);
        }
      },
    );
  }

  /// Icon-box colour per section (design 1: blue setup, yellow permissions,
  /// green money/sponsors, red livestream).
  LavishTone _sectionTone(TournamentManagementSection section) =>
      switch (section) {
        TournamentManagementSection.permissions => LavishTone.warn,
        TournamentManagementSection.sponsors ||
        TournamentManagementSection.finance => LavishTone.ok,
        TournamentManagementSection.livestream => LavishTone.bad,
        _ => LavishTone.accent,
      };

  _SectionDetails _sectionDetails(
    AppLocalizations l10n,
    TournamentManagementSection section,
  ) => switch (section) {
    TournamentManagementSection.information => _SectionDetails(
      Icons.article_outlined,
      l10n.manageSettingsInfoSection,
      l10n.manageSettingsInfoSectionDescription,
      AppTheme.primary,
    ),
    TournamentManagementSection.schedule => _SectionDetails(
      Icons.event_outlined,
      l10n.manageSettingsVenueSection,
      l10n.manageSettingsVenueSectionDescription,
      AppTheme.secondary,
    ),
    TournamentManagementSection.registration => _SectionDetails(
      Icons.how_to_reg_outlined,
      l10n.tournamentManagementRegistration,
      l10n.manageSettingsRegistrationSectionDescription,
      AppTheme.primary,
    ),
    TournamentManagementSection.divisions => _SectionDetails(
      Icons.category_outlined,
      l10n.manageSettingsCompetitionSection,
      l10n.tournamentManagementDivisionsDescription,
      AppTheme.secondary,
    ),
    TournamentManagementSection.teams => _SectionDetails(
      Icons.people_rounded,
      l10n.manageTeams,
      l10n.manageTeamsSubtitle,
      AppTheme.primary,
    ),
    TournamentManagementSection.sponsors => _SectionDetails(
      Icons.handshake_outlined,
      l10n.tournamentManagementSponsors,
      l10n.tournamentManagementSponsorsDescription,
      AppTheme.secondary,
    ),
    TournamentManagementSection.finance => _SectionDetails(
      Icons.payments_outlined,
      l10n.tournamentManagementFinance,
      l10n.tournamentManagementFinanceDescription,
      AppTheme.primary,
    ),
    TournamentManagementSection.livestream => _SectionDetails(
      Icons.videocam_outlined,
      l10n.tournamentManagementLivestream,
      l10n.tournamentManagementLivestreamDescription,
      AppTheme.secondary,
    ),
    TournamentManagementSection.permissions => _SectionDetails(
      Icons.admin_panel_settings_outlined,
      l10n.tournamentManagementPermissions,
      l10n.tournamentManagementPermissionsDescription,
      AppTheme.primary,
    ),
  };

  /// Kết thúc giải qua sheet checklist (như Web): "trận đã xong X/Y", liệt kê
  /// trận LIVE và hạng mục chặn; còn trận LIVE thì khoá nút kết thúc. Sheet
  /// tự gọi `complete-tournament`, chống double-tap và hiển thị lỗi server
  /// nguyên văn; kết thúc xong báo thành công qua snackbar.
  Future<void> _finalizeTournament() async {
    final ended = await LifecycleEndSheet.show(
      context,
      tournament: widget.tournament,
    );
    if (!mounted || ended != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.tournamentEnded)),
    );
  }

  Future<void> _exportTournamentData() async {
    if (_isExporting) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isExporting = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.exportingExcel)));
    try {
      final matches = await ref.read(
        matchesProvider(widget.tournament.id).future,
      );
      await ExcelExportService.exportTournamentData(
        widget.tournament.name,
        matches,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportSuccess),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tournamentManagementExportError),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Xuất danh sách VĐV (task 3.9): sheet roster với tên, liên hệ, hạng mục,
  /// trạng thái, seed, thanh toán — dữ liệu hồ sơ BTC
  /// (`getOrganizerParticipants`, cùng nguồn tab VĐV).
  Future<void> _exportParticipantsRoster() async {
    if (_isExporting) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isExporting = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.exportingExcel)));
    try {
      final participants = await ref
          .read(tournamentRepositoryProvider)
          .getOrganizerParticipants(widget.tournament.id);
      await ExcelExportService.exportParticipantsRoster(
        tournamentName: widget.tournament.name,
        participants: participants,
        divisionNameById: {
          for (final division in widget.tournament.divisions)
            division.id: division.name,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportSuccess),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tournamentManagementExportError),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Whole-tournament Excel report (one file, one sheet per ticked section).
  /// Throws on failure so the report sheet can keep its ticks for a retry.
  Future<void> _exportReport(Set<TournamentReportSection> sections) async {
    if (_isExporting) return;
    final tournamentId = widget.tournament.id;
    setState(() => _isExporting = true);
    try {
      final withParticipants = sections.contains(
        TournamentReportSection.participants,
      );
      final withMatches = sections.contains(TournamentReportSection.matches);
      await ExcelExportService.exportTournamentReport(
        sheets: sections,
        tournamentName: widget.tournament.name,
        participants: withParticipants
            ? await ref
                  .read(tournamentRepositoryProvider)
                  .getOrganizerParticipants(tournamentId)
            : const [],
        divisionNameById: {
          for (final division in widget.tournament.divisions)
            division.id: division.name,
        },
        matches: withMatches
            ? await ref.read(matchesProvider(tournamentId).future)
            : const [],
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Same link and card as the tournament intro screen's share button.
  void _shareTournament() {
    final l10n = AppLocalizations.of(context)!;
    final tournament = widget.tournament;
    final inviteCode = tournament.inviteCode;
    final shareUrl =
        tournament.isClubLite && inviteCode != null && inviteCode.isNotEmpty
        ? 'https://sporto.asia/lite/tournaments/join/${Uri.encodeComponent(inviteCode)}'
        : 'https://sporto.asia/tournaments/${tournament.id}';
    AppShareModal.show(
      context: context,
      title: tournament.name,
      subtitle:
          '${tournament.locationAddress ?? l10n.vietnam} • ${tournament.category ?? tournament.sport}',
      webUrl: shareUrl,
      imageUrl: tournament.logoUrl ?? tournament.bannerUrl,
      badgeText: tournament.isClubLite
          ? l10n.liteTournament
          : l10n.advancedTournament,
    );
  }

  Future<void> _deleteTournament() async {
    if (_isDeleting) return;
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDeleteTournamentDialog(
      context,
      tournamentName: widget.tournament.name,
    );
    if (!confirm || !mounted) return;
    setState(() => _isDeleting = true);
    final success = await ref
        .read(tournamentActionProvider.notifier)
        .deleteTournament(widget.tournament.id);
    if (!mounted) return;
    setState(() => _isDeleting = false);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tournamentDeleted)));
      context.go('/dashboard');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deleteError)));
    }
  }
}

enum _HubTab {
  overview,
  divisions,
  athletes,
  bracket,
  schedule,
  results,
  settings,
}

class _SectionDetails {
  const _SectionDetails(this.icon, this.title, this.subtitle, this.color);
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
