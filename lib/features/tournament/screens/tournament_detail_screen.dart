import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_action_notifier.dart';
import 'package:app_quanly_giaidau/core/dialogs/confirm_dialog.dart';
import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';

import 'package:app_quanly_giaidau/core/widgets/responsive_layout.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';
import 'package:app_quanly_giaidau/features/teams/screens/team_list_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/token_management_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/auto_draw_screen.dart';
import 'package:app_quanly_giaidau/core/widgets/info_chip.dart';
import 'package:app_quanly_giaidau/core/widgets/app_action_button.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_icon_widget.dart';

enum SelectedFeature { none, tokens, teams, draw, bracket }

class TournamentDetailScreen extends ConsumerStatefulWidget {
  static const _log = AppLogger('TournamentDetailScreen');
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});
  @override
  ConsumerState<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState
    extends ConsumerState<TournamentDetailScreen> {
  SelectedFeature _selectedFeature = SelectedFeature.none;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    TournamentDetailScreen._log.debug(
      'Building with tournamentId = ${widget.tournamentId}',
    );
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return tournamentAsync.when(
      data: (tournament) {
        if (tournament == null) {
          return Scaffold(body: Center(child: Text(l10n.tournamentNotFound)));
        }

        return Scaffold(
          backgroundColor: context.colors.bgDark,
          appBar: AppBar(
            backgroundColor: context.colors.bgDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go('/admin'),
            ),
            title: Text(
              tournament.name.isNotEmpty ? tournament.name : l10n.unnamed,
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                color: context.colors.bgCard,
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirm = await showConfirmDialog(
                      context: context,
                      title: l10n.deleteTournamentTitle,
                      content: l10n.deleteTournamentContent,
                      confirmText: l10n.delete,
                    );
                    if (confirm == true && context.mounted) {
                      final success = await ref
                          .read(tournamentActionProvider.notifier)
                          .deleteTournament(widget.tournamentId);
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.tournamentDeleted)),
                          );
                          context.go('/admin');
                        } else {
                          final error = ref
                              .read(tournamentActionProvider)
                              .error;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${l10n.deleteError}: $error'),
                            ),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          color: context.colors.error,
                          size: 18,
                        ),
                        SizedBox(width: 8),
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
            mobile: _buildMasterView(context, tournament),
            tablet: Row(
              children: [
                SizedBox(
                  width: 320,
                  child: _buildMasterView(context, tournament, isTablet: true),
                ),
                VerticalDivider(width: 1, color: context.colors.border),
                Expanded(child: _buildDetailView(context)),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: context.colors.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.colors.bgDark,
        body: Center(child: Text('${l10n.errorPrefix}: $e')),
      ),
    );
  }

  Widget _buildDetailView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_selectedFeature) {
      case SelectedFeature.tokens:
        return TokenManagementScreen(
          tournamentId: widget.tournamentId,
          isEmbedded: true,
        );
      case SelectedFeature.teams:
        return TeamListScreen(
          tournamentId: widget.tournamentId,
          isEmbedded: true,
        );
      case SelectedFeature.draw:
        return AutoDrawScreen(
          tournamentId: widget.tournamentId,
          isEmbedded: true,
        );
      case SelectedFeature.bracket:
        return BracketViewScreen(
          tournamentId: widget.tournamentId,
          isEmbedded: true,
        );
      case SelectedFeature.none:
        return Center(
          child: Text(
            l10n.selectFeature,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 16),
          ),
        );
    }
  }

  Widget _buildMasterView(
    BuildContext context,
    dynamic tournament, {
    bool isTablet = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final sportIcon = AppConstants.sportIcons[tournament.sport] ?? '🏆';
    final sportName = l10n.sportDisplayName(tournament.sport);
    final formatName = l10n.formatDisplayName(tournament.format);
    final categoryName = tournament.category != null
        ? l10n.categoryDisplayName(tournament.category)
        : null;
    final bracketName = l10n.bracketDisplayName(tournament.bracketType);
    final statusName = StatusHelper.getTournamentStatusLabel(
      tournament.status,
      l10n: l10n,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Info Card ───
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: context.cardGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            children: [
              SportIconWidget(iconData: sportIcon, size: 48),
              const SizedBox(height: 12),
              Text(
                tournament.name.isNotEmpty ? tournament.name : l10n.unnamed,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  InfoChip(label: sportName, color: AppTheme.primary),
                  InfoChip(label: formatName, color: AppTheme.secondary),
                  if (categoryName != null)
                    InfoChip(label: categoryName, color: AppTheme.adminColor),
                  InfoChip(label: bracketName, color: context.colors.warning),
                  InfoChip(label: statusName, color: context.colors.success),
                  InfoChip(
                    label: '${tournament.maxTeams} ${l10n.teamsUnit}',
                    color: AppTheme.primary,
                  ),
                  if (tournament.maxPlayersPerTeam != null)
                    InfoChip(
                      label:
                          '${tournament.maxPlayersPerTeam} ${l10n.playersPerTeam}',
                      color: AppTheme.secondary,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tokens were moved to Token Management Screen

        // ─── Quick Actions ───
        Text(
          l10n.managementTitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.colors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        AppActionButton(
          icon: Icons.qr_code_rounded,
          label: l10n.manageTokens,
          subtitle: l10n.manageTokensSubtitle,
          color: AppTheme.adminColor,
          isSelected: _selectedFeature == SelectedFeature.tokens,
          onTap: () {
            if (isTablet) {
              setState(() => _selectedFeature = SelectedFeature.tokens);
            } else {
              context.go('/admin/tournament/${widget.tournamentId}/tokens');
            }
          },
        ),
        const SizedBox(height: 8),
        AppActionButton(
          icon: Icons.people_rounded,
          label: l10n.manageTeams,
          subtitle: l10n.manageTeamsSubtitle,
          color: AppTheme.primary,
          isSelected: _selectedFeature == SelectedFeature.teams,
          onTap: () {
            if (isTablet) {
              setState(() => _selectedFeature = SelectedFeature.teams);
            } else {
              context.go('/admin/tournament/${widget.tournamentId}/teams');
            }
          },
        ),
        const SizedBox(height: 8),
        AppActionButton(
          icon: Icons.casino_rounded,
          label: l10n.manageDraw,
          subtitle: l10n.manageDrawSubtitle,
          color: context.colors.warning,
          isSelected: _selectedFeature == SelectedFeature.draw,
          onTap: () {
            if (isTablet) {
              setState(() => _selectedFeature = SelectedFeature.draw);
            } else {
              context.go('/admin/tournament/${widget.tournamentId}/draw');
            }
          },
        ),
        const SizedBox(height: 8),
        AppActionButton(
          icon: Icons.account_tree_rounded,
          label: l10n.viewBracket,
          subtitle: l10n.viewBracketSubtitle,
          color: AppTheme.secondary,
          isSelected: _selectedFeature == SelectedFeature.bracket,
          onTap: () {
            if (isTablet) {
              setState(() => _selectedFeature = SelectedFeature.bracket);
            } else {
              context.go('/admin/tournament/${widget.tournamentId}/bracket');
            }
          },
        ),
        if (tournament.status == AppConstants.statusInProgress) ...[
          const SizedBox(height: 8),
          AppActionButton(
            icon: Icons.check_circle_outline_rounded,
            label: l10n.endTournament,
            subtitle: l10n.endTournamentSubtitle,
            color: context.colors.success,
            isSelected: false,
            onTap: () async {
              final confirm = await showConfirmDialog(
                context: context,
                title: l10n.confirmEndTitle,
                content: l10n.confirmEndContent,
                confirmText: l10n.confirmEndButton,
                cancelText: l10n.continueButton,
              );
              if (confirm == true && context.mounted) {
                final success = await ref
                    .read(tournamentActionProvider.notifier)
                    .finalizeTournament(widget.tournamentId);
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.tournamentEnded)),
                    );
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.endError)));
                  }
                }
              }
            },
          ),
        ],
        const SizedBox(height: 8),
        AppActionButton(
          icon: Icons.download_rounded,
          label: l10n.exportData,
          subtitle: l10n.exportDataSubtitle,
          color: AppTheme.primary,
          isSelected: false,
          onTap: () async {
            try {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.exportingExcel)));
              final matches = await ref.read(
                matchesProvider(widget.tournamentId).future,
              );
              await ExcelExportService.exportTournamentData(
                tournament.name,
                matches,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.exportSuccess),
                    backgroundColor: context.colors.success,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l10n.errorPrefix}: $e'),
                    backgroundColor: context.colors.error,
                  ),
                );
              }
            }
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
