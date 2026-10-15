import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/dialogs/confirm_dialog.dart';
import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:app_quanly_giaidau/core/widgets/responsive_layout.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/auto_draw_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/features/teams/screens/team_list_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/token_management_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_section_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/overview_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_athletes_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_header.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_tab_bar_delegate.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_action_notifier.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    TournamentManagementSection.divisions,
  ];
  static const _otherSections = [
    TournamentManagementSection.teams,
    TournamentManagementSection.draw,
    TournamentManagementSection.sponsors,
    TournamentManagementSection.finance,
    TournamentManagementSection.livestream,
    TournamentManagementSection.permissions,
    TournamentManagementSection.tokens,
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
  bool _isCollapsed = false;
  bool _isTabBarPinned = false;
  bool _isFinalizing = false;
  bool _isExporting = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _tabStripOverlapHandle.dispose();
    super.dispose();
  }

  void _onScroll() {
    final collapsed =
        _scrollController.hasClients && _scrollController.offset >= 110.0;
    final maxScroll = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final tabPinned = _scrollController.hasClients &&
        maxScroll > 0 &&
        _scrollController.offset >= (maxScroll - 2.0);
    if (collapsed != _isCollapsed || tabPinned != _isTabBarPinned) {
      setState(() {
        _isCollapsed = collapsed;
        _isTabBarPinned = tabPinned;
      });
    }
  }

  void _openSection(TournamentManagementSection section) {
    final isTablet = !ResponsiveLayout.isMobile(context);
    setState(() {
      _selectedSection = section;
      if (!isTablet) _openedSection = section;
    });
    if (isTablet) _tabController.animateTo(_HubTab.settings.index);
  }

  void _closeSection() => setState(() => _openedSection = null);

  String _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${AppConstants.appDomain}$url';
  }

  @override
  Widget build(BuildContext context) {
    final tournament = widget.tournament;
    final l10n = AppLocalizations.of(context)!;
    // Kết thúc giải là thao tác admin: backend từ chối organizer.
    final canFinalize = _canFinalizeTournament(
      tournament.status,
      isAdmin:
          ref.watch(userProfileProvider).asData?.value.hasRole('ADMIN') ??
          false,
    );
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
                    background: TournamentManagementBanner(
                      tournament: tournament,
                      resolveImageUrl: _resolveImageUrl,
                      onEdit: () =>
                          _openSection(TournamentManagementSection.information),
                    ),
                  ),
          ),
        ),
        // Đệm chiều cao toolbar: không có đệm này tên giải nằm dưới app bar.
        SliverToBoxAdapter(
          child: SizedBox(height: 44 + topPadding),
        ),
        SliverToBoxAdapter(
          child: TournamentManagementSummary(
            tournament: tournament,
            teamCount: teamCount,
            onEditInformation: () =>
                _openSection(TournamentManagementSection.information),
            onEditSchedule: () =>
                _openSection(TournamentManagementSection.schedule),
            onEditRegistration: () =>
                _openSection(TournamentManagementSection.registration),
            onEditFinance: () =>
                _openSection(TournamentManagementSection.finance),
            onOpenAthletes: () =>
                _tabController.animateTo(_HubTab.athletes.index),
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
                Tab(text: l10n.tournamentManagementTabAthletes),
                Tab(text: l10n.tournamentManagementTabBracket),
                Tab(text: l10n.tournamentManagementSchedule),
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
                    _openSection(TournamentManagementSection.information),
                onEditSchedule: () =>
                    _openSection(TournamentManagementSection.schedule),
                onEditRegistration: () =>
                    _openSection(TournamentManagementSection.registration),
                onEditFinance: () =>
                    _openSection(TournamentManagementSection.finance),
              ),
              CustomScrollView(
                slivers: [
                  ...overlapHandles.map(
                    (handle) => SliverOverlapInjector(handle: handle),
                  ),
                  SliverToBoxAdapter(
                    child: TournamentManagementAthletesTab(
                      tournament: tournament,
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
                    ),
                  ),
                ],
              ),
              OrganizerOpsScreen(
                tournamentId: tournament.id,
                isEmbedded: true,
                view: OrganizerOpsView.matches,
                initialMatchesView: OrganizerOpsMatchesView.grid,
                overlapHandles: overlapHandles,
              ),
              _buildSettingsTab(context, overlapHandles),
            ],
          );
        },
      ),
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
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList.list(
            children: [
              _buildSectionGroup(
                context,
                isTablet: isTablet,
                title: l10n.tournamentManagementSetupGroup,
                icon: Icons.tune_rounded,
                sections: _setupSections,
              ),
              const SizedBox(height: 12),
              _buildOtherSectionsGroup(context, isTablet: isTablet),
              const SizedBox(height: 12),
              TournamentLifecycleCard(tournament: widget.tournament),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtherSectionsGroup(
    BuildContext context, {
    required bool isTablet,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: colors.border),
        child: ExpansionTile(
          leading: const Icon(
            Icons.more_horiz_rounded,
            color: AppTheme.primary,
          ),
          title: Text(
            l10n.manageSettingsOtherSection,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          children: [
            for (var index = 0; index < _otherSections.length; index++) ...[
              _buildSectionAction(
                context,
                l10n,
                isTablet,
                _otherSections[index],
              ),
              if (index != _otherSections.length - 1)
                Divider(height: 1, indent: 50, color: colors.border),
            ],
          ],
        ),
      ),
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
      case TournamentManagementSection.draw:
        return AutoDrawScreen(
          tournamentId: tournament.id,
          isEmbedded: true,
          managementRouteBase: widget.actionRouteBase,
        );
      case TournamentManagementSection.tokens:
        return TokenManagementScreen(
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
        if (canFinalize)
          PopupMenuItem(
            value: 'end',
            enabled: !_isFinalizing,
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

  Widget _buildSectionGroup(
    BuildContext context, {
    required bool isTablet,
    required String title,
    required IconData icon,
    required List<TournamentManagementSection> sections,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 19),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < sections.length; index++) ...[
            _buildSectionAction(context, l10n, isTablet, sections[index]),
            if (index != sections.length - 1)
              Divider(height: 1, indent: 50, color: colors.border),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionAction(
    BuildContext context,
    AppLocalizations l10n,
    bool isTablet,
    TournamentManagementSection section,
  ) {
    final details = _sectionDetails(l10n, section);
    return Tooltip(
      message: details.subtitle,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          selected: isTablet && _selectedSection == section,
          selectedTileColor: context.colors.bgSurface,
          leading: Icon(details.icon, color: details.color),
          title: Text(
            details.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: () {
            if (isTablet) {
              setState(() => _selectedSection = section);
            } else {
              _openSection(section);
            }
          },
        ),
      ),
    );
  }

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
    TournamentManagementSection.draw => _SectionDetails(
      Icons.casino_rounded,
      l10n.manageDraw,
      l10n.manageDrawSubtitle,
      context.colors.warning,
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
    TournamentManagementSection.tokens => _SectionDetails(
      Icons.qr_code_rounded,
      l10n.manageTokens,
      l10n.manageTokensSubtitle,
      AppTheme.adminColor,
    ),
  };

  static bool _canFinalizeTournament(String status, {required bool isAdmin}) =>
      status.toUpperCase() == AppConstants.statusInProgress.toUpperCase() &&
      isAdmin;

  Future<void> _finalizeTournament() async {
    final isAdmin =
        ref.read(userProfileProvider).asData?.value.hasRole('ADMIN') ?? false;
    if (_isFinalizing ||
        !_canFinalizeTournament(widget.tournament.status, isAdmin: isAdmin)) {
      return;
    }
    setState(() => _isFinalizing = true);
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showConfirmDialog(
      context: context,
      title: l10n.confirmEndTitle,
      content: l10n.confirmEndContent,
      confirmText: l10n.confirmEndButton,
      cancelText: l10n.continueButton,
    );
    if (confirm != true || !mounted) {
      if (mounted) setState(() => _isFinalizing = false);
      return;
    }
    final success = await ref
        .read(tournamentActionProvider.notifier)
        .finalizeTournament(widget.tournament.id);
    if (success) ref.invalidate(tournamentProvider(widget.tournament.id));
    if (!mounted) return;
    setState(() => _isFinalizing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? l10n.tournamentEnded : l10n.endError)),
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

  Future<void> _deleteTournament() async {
    if (_isDeleting) return;
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showConfirmDialog(
      context: context,
      title: l10n.deleteTournamentTitle,
      content: l10n.deleteTournamentContent,
      confirmText: l10n.delete,
    );
    if (confirm != true || !mounted) return;
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

enum _HubTab { overview, athletes, bracket, schedule, settings }

class _SectionDetails {
  const _SectionDetails(this.icon, this.title, this.subtitle, this.color);
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
