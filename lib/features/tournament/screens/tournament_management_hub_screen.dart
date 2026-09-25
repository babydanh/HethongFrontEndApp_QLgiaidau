import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/dialogs/confirm_dialog.dart';
import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:app_quanly_giaidau/core/widgets/app_action_button.dart';
import 'package:app_quanly_giaidau/core/widgets/responsive_layout.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/auto_draw_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/teams/screens/team_list_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/token_management_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_section_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_banner.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_action_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
            color: context.colors.bgCard,
            onSelected: (value) {
              if (value == 'delete') _deleteTournament();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                enabled: !_isDeleting,
                child: Row(
                  children: [
                    Icon(Icons.delete, color: context.colors.error, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l10n.deleteTournament,
                      style: TextStyle(color: context.colors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMasterView(context, tournament, isTablet: false),
        tablet: Row(
          children: [
            SizedBox(
              width: 360,
              child: _buildMasterView(context, tournament, isTablet: true),
            ),
            VerticalDivider(width: 1, color: context.colors.border),
            Expanded(child: _buildDetailView(context)),
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

  Widget _buildMasterView(
    BuildContext context,
    Tournament tournament, {
    required bool isTablet,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TournamentManagementBanner(
          tournament: tournament,
          colors: context.colors,
        ),
        const SizedBox(height: 12),
        _OverviewSummary(tournament: tournament),
        const SizedBox(height: 20),
        _buildSectionGroup(
          context,
          isTablet: isTablet,
          title: l10n.tournamentManagementSetupGroup,
          icon: Icons.tune_rounded,
          sections: const [
            TournamentManagementSection.overview,
            TournamentManagementSection.general,
            TournamentManagementSection.branding,
            TournamentManagementSection.venues,
            TournamentManagementSection.registration,
            TournamentManagementSection.divisions,
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionGroup(
          context,
          isTablet: isTablet,
          title: l10n.tournamentManagementOperationsGroup,
          icon: Icons.sports_score_rounded,
          sections: const [
            TournamentManagementSection.schedule,
            TournamentManagementSection.teams,
            TournamentManagementSection.draw,
            TournamentManagementSection.bracket,
            TournamentManagementSection.liveOperations,
            TournamentManagementSection.sponsors,
            TournamentManagementSection.finance,
            TournamentManagementSection.livestream,
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionGroup(
          context,
          isTablet: isTablet,
          title: l10n.tournamentManagementSystemGroup,
          icon: Icons.admin_panel_settings_outlined,
          sections: const [
            TournamentManagementSection.permissions,
            TournamentManagementSection.tokens,
          ],
        ),
        if (tournament.status == AppConstants.statusInProgress) ...[
          const SizedBox(height: 16),
          IgnorePointer(
            ignoring: _isFinalizing,
            child: Opacity(
              opacity: _isFinalizing ? 0.55 : 1,
              child: AppActionButton(
                icon: Icons.check_circle_outline_rounded,
                label: l10n.endTournament,
                subtitle: l10n.endTournamentSubtitle,
                color: context.colors.success,
                isSelected: false,
                onTap: _finalizeTournament,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: _isExporting,
          child: Opacity(
            opacity: _isExporting ? 0.55 : 1,
            child: AppActionButton(
              icon: _isExporting
                  ? Icons.hourglass_top_rounded
                  : Icons.download_rounded,
              label: _isExporting ? l10n.exportingExcel : l10n.exportData,
              subtitle: l10n.exportDataSubtitle,
              color: AppTheme.primary,
              isSelected: false,
              onTap: _exportTournamentData,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AppActionButton(
          icon: Icons.sports_score_rounded,
          label: l10n.opsTitle,
          subtitle: l10n.tournamentManagementOpsRouteDescription,
          color: context.colors.warning,
          isSelected: false,
          onTap: () => context.push(widget.opsWorkspaceRoute),
        ),
        if (widget.liteWorkspaceRoute != null && tournament.isSuperLite) ...[
          const SizedBox(height: 8),
          AppActionButton(
            icon: Icons.tune_rounded,
            label: l10n.lite_managementTitle,
            color: AppTheme.secondary,
            isSelected: false,
            onTap: () => context.push(widget.liteWorkspaceRoute!),
          ),
        ],
        const SizedBox(height: 40),
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
    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
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

class _OverviewSummary extends StatelessWidget {
  const _OverviewSummary({required this.tournament});
  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final money = NumberFormat.currency(
      locale: locale,
      name: 'VND',
      symbol: '₫',
      decimalDigits: 0,
    );
    final materialLocalizations = MaterialLocalizations.of(context);
    final date = tournament.startDate == null
        ? l10n.tournamentManagementNotSet
        : materialLocalizations.formatMediumDate(
            tournament.startDate!.toLocal(),
          );
    final entryFee = tournament.entryFee == null
        ? l10n.tournamentManagementNotSet
        : money.format(tournament.entryFee);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tournamentManagementOverview,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryMetric(
                icon: Icons.event_outlined,
                label: l10n.tournamentManagementStartDate,
                value: date,
              ),
              _SummaryMetric(
                icon: Icons.place_outlined,
                label: l10n.tournamentManagementVenue,
                value: tournament.venueName?.trim().isNotEmpty == true
                    ? tournament.venueName!
                    : l10n.tournamentManagementNotSet,
              ),
              _SummaryMetric(
                icon: Icons.payments_outlined,
                label: l10n.tournamentManagementEntryFee,
                value: entryFee,
              ),
              _SummaryMetric(
                icon: Icons.category_outlined,
                label: l10n.tournamentManagementDivisions,
                value: '${tournament.divisions.length}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(maxWidth: 250, minWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDetails {
  const _SectionDetails(this.icon, this.title, this.subtitle, this.color);
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
