import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/dialogs/confirm_dialog.dart';
import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:app_quanly_giaidau/core/widgets/app_action_button.dart';
import 'package:app_quanly_giaidau/core/widgets/responsive_layout.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_banner.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/auto_draw_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/teams/screens/team_list_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/token_management_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_section_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_action_notifier.dart';
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
    extends ConsumerState<TournamentManagementHubScreen> {
  TournamentManagementSection _selectedSection =
      TournamentManagementSection.overview;
  bool _isFinalizing = false;
  bool _isExporting = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final tournament = widget.tournament;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: l10n.tournamentManagementBack,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(l10n.managementTitle),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: l10n.tournamentManagementSystemGroup,
            color: context.colors.bgCard,
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
              if (tournament.status.toUpperCase() ==
                  AppConstants.statusInProgress.toUpperCase())
                PopupMenuItem(
                  value: 'end',
                  enabled: !_isFinalizing,
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: context.colors.success,
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
                      Icon(
                        Icons.tune_rounded,
                        color: AppTheme.secondary,
                        size: 18,
                      ),
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
                    Icon(Icons.delete, color: context.colors.error, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.deleteTournament,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.colors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildManagementNavigation(
          context,
          tournament,
          isTablet: false,
        ),
        tablet: Row(
          children: [
            SizedBox(
              width: 360,
              child: _buildManagementNavigation(
                context,
                tournament,
                isTablet: true,
              ),
            ),
            VerticalDivider(width: 1, color: context.colors.border),
            Expanded(child: _buildDetailView(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementNavigation(
    BuildContext context,
    Tournament tournament, {
    required bool isTablet,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Material(
            color: context.colors.bgDark,
            child: TabBar(
              labelColor: context.colors.textPrimary,
              unselectedLabelColor: context.colors.textMuted,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: [
                Tab(text: l10n.tournamentManagementOverview),
                Tab(text: l10n.tournamentManagementSetupGroup),
                Tab(text: l10n.tournamentManagementOperationsGroup),
                Tab(text: l10n.tournamentManagementSystemGroup),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                if (isTablet)
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionAction(
                        context,
                        l10n,
                        true,
                        TournamentManagementSection.overview,
                      ),
                    ],
                  )
                else
                  _buildOverviewContent(context, tournament),
                _buildSectionGroupPage(
                  context,
                  isTablet: isTablet,
                  title: l10n.tournamentManagementSetupGroup,
                  icon: Icons.tune_rounded,
                  sections: const [
                    TournamentManagementSection.general,
                    TournamentManagementSection.branding,
                    TournamentManagementSection.venues,
                    TournamentManagementSection.registration,
                    TournamentManagementSection.divisions,
                  ],
                ),
                _buildOperationsGroupPage(context, isTablet: isTablet),
                _buildSectionGroupPage(
                  context,
                  isTablet: isTablet,
                  title: l10n.tournamentManagementSystemGroup,
                  icon: Icons.admin_panel_settings_outlined,
                  sections: const [
                    TournamentManagementSection.permissions,
                    TournamentManagementSection.tokens,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewContent(BuildContext context, Tournament tournament) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TournamentManagementBanner(
            tournament: tournament,
            colors: context.colors,
          ),
        ),
        Expanded(
          child: TournamentManagementSectionScreen(
            tournament: tournament,
            section: TournamentManagementSection.overview,
            opsWorkspaceRoute: widget.opsWorkspaceRoute,
            actionRouteBase: widget.actionRouteBase,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionGroupPage(
    BuildContext context, {
    required bool isTablet,
    required String title,
    required IconData icon,
    required List<TournamentManagementSection> sections,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionGroup(
          context,
          isTablet: isTablet,
          title: title,
          icon: icon,
          sections: sections,
          showHeader: false,
        ),
      ],
    );
  }

  Widget _buildOperationsGroupPage(
    BuildContext context, {
    required bool isTablet,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppActionButton(
          icon: Icons.sports_score_rounded,
          label: l10n.opsTitle,
          subtitle: l10n.tournamentManagementOpsRouteDescription,
          color: context.colors.warning,
          isSelected: false,
          onTap: () => context.push(widget.opsWorkspaceRoute),
        ),
        const SizedBox(height: 12),
        _buildSectionGroup(
          context,
          isTablet: isTablet,
          title: l10n.tournamentManagementOperationsGroup,
          icon: Icons.sports_score_rounded,
          sections: const [
            TournamentManagementSection.teams,
            TournamentManagementSection.draw,
            TournamentManagementSection.bracket,
            TournamentManagementSection.sponsors,
            TournamentManagementSection.finance,
            TournamentManagementSection.livestream,
          ],
          showHeader: false,
        ),
      ],
    );
  }

  Widget _buildDetailView(BuildContext context) {
    final tournament = widget.tournament;
    switch (_selectedSection) {
      case TournamentManagementSection.overview:
        return _buildOverviewContent(context, tournament);
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
      case TournamentManagementSection.bracket:
        return BracketViewScreen(tournamentId: tournament.id, isEmbedded: true);
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

  Widget _buildSectionGroup(
    BuildContext context, {
    required bool isTablet,
    required String title,
    required IconData icon,
    required List<TournamentManagementSection> sections,
    bool showHeader = true,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
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
    final route = switch (section) {
      TournamentManagementSection.tokens => '${widget.actionRouteBase}/tokens',
      TournamentManagementSection.teams => '${widget.actionRouteBase}/teams',
      TournamentManagementSection.draw => '${widget.actionRouteBase}/draw',
      TournamentManagementSection.bracket =>
        '${widget.actionRouteBase}/bracket',
      TournamentManagementSection.schedule ||
      TournamentManagementSection.liveOperations => widget.opsWorkspaceRoute,
      _ => null,
    };
    return AppActionButton(
      icon: details.icon,
      label: details.title,
      subtitle: details.subtitle,
      color: details.color,
      isSelected: isTablet && _selectedSection == section,
      onTap: () {
        if (isTablet) {
          setState(() => _selectedSection = section);
        } else if (route != null) {
          context.push(route);
        } else {
          Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                backgroundColor: context.colors.bgDark,
                appBar: AppBar(title: Text(details.title)),
                body: SafeArea(
                  child: TournamentManagementSectionScreen(
                    tournament: widget.tournament,
                    section: section,
                    opsWorkspaceRoute: widget.opsWorkspaceRoute,
                    actionRouteBase: widget.actionRouteBase,
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  _SectionDetails _sectionDetails(
    AppLocalizations l10n,
    TournamentManagementSection section,
  ) => switch (section) {
    TournamentManagementSection.overview => _SectionDetails(
      Icons.dashboard_outlined,
      l10n.tournamentManagementOverview,
      l10n.tournamentManagementOverviewDescription,
      AppTheme.primary,
    ),
    TournamentManagementSection.general => _SectionDetails(
      Icons.settings_outlined,
      l10n.tournamentManagementGeneral,
      l10n.tournamentManagementGeneralDescription,
      AppTheme.primary,
    ),
    TournamentManagementSection.branding => _SectionDetails(
      Icons.palette_outlined,
      l10n.tournamentManagementBranding,
      l10n.tournamentManagementBrandingDescription,
      AppTheme.secondary,
    ),
    TournamentManagementSection.venues => _SectionDetails(
      Icons.place_outlined,
      l10n.tournamentManagementVenues,
      l10n.tournamentManagementVenuesDescription,
      AppTheme.secondary,
    ),
    TournamentManagementSection.registration => _SectionDetails(
      Icons.how_to_reg_outlined,
      l10n.tournamentManagementRegistration,
      l10n.tournamentManagementRegistrationDescription,
      AppTheme.primary,
    ),
    TournamentManagementSection.divisions => _SectionDetails(
      Icons.category_outlined,
      l10n.tournamentManagementDivisions,
      l10n.tournamentManagementDivisionsDescription,
      AppTheme.secondary,
    ),
    TournamentManagementSection.schedule => _SectionDetails(
      Icons.calendar_month_rounded,
      l10n.tournamentManagementSchedule,
      l10n.tournamentManagementScheduleDescription,
      AppTheme.primary,
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
    TournamentManagementSection.bracket => _SectionDetails(
      Icons.account_tree_rounded,
      l10n.viewBracket,
      l10n.viewBracketSubtitle,
      AppTheme.secondary,
    ),
    TournamentManagementSection.liveOperations => _SectionDetails(
      Icons.sports_score_rounded,
      l10n.tournamentManagementLiveOperations,
      l10n.tournamentManagementLiveOperationsDescription,
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

  Future<void> _finalizeTournament() async {
    if (_isFinalizing) return;
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

class _SectionDetails {
  const _SectionDetails(this.icon, this.title, this.subtitle, this.color);
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
