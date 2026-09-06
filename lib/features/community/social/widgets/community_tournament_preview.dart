import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CommunityTournamentPreview extends ConsumerWidget {
  final CommunityPostModel post;

  const CommunityTournamentPreview({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final tournamentId = post.tournamentId;

    if (tournamentId == null || tournamentId.isEmpty) {
      return const SizedBox.shrink();
    }

    final tournamentAsync = ref.watch(tournamentProvider(tournamentId));
    final tournament = tournamentAsync.value;
    final matchesAsync = ref.watch(
      tournament?.isLite == true
          ? liteBracketMatchesProvider(tournamentId)
          : matchesProvider(tournamentId),
    );

    final matches = matchesAsync.value ?? const <MatchModel>[];

    // Filter valid matches
    final validMatches = matches.where((m) {
      final t1 = m.team1Name.trim().toUpperCase();
      final t2 = m.team2Name.trim().toUpperCase();
      final isT1Bye = t1 == 'BYE';
      final isT2Bye = t2 == 'BYE';
      final isT1Tbd =
          !isT1Bye && (t1.isEmpty || t1 == 'TBD') && m.team1Id.trim().isEmpty;
      final isT2Tbd =
          !isT2Bye && (t2.isEmpty || t2 == 'TBD') && m.team2Id.trim().isEmpty;
      return !(isT1Bye || isT2Bye || (isT1Tbd && isT2Tbd));
    }).toList();

    final status = (tournament?.status ?? '').toUpperCase();
    final isLive = status == 'ONGOING' || status == 'IN_PROGRESS';
    final isCompleted = status == 'COMPLETED' || status == 'FINISHED';
    final hasMatches = validMatches.isNotEmpty;

    final tournamentName =
        tournament?.name ??
        post.tournamentName ??
        l10n.communityTournamentPreviewDefaultName;
    final sportText = _sportLabel(tournament?.sport, l10n);

    // Pick top 2 matches to preview (prioritizing live or recent matches)
    final previewMatches = validMatches.take(2).toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.8),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Bar ──
          InkWell(
            onTap: () {
              if (tournamentAsync.hasError || tournament == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Bạn không có quyền xem chi tiết giải đấu này.',
                    ),
                  ),
                );
                return;
              }
              final inviteParam =
                  (post.tournamentInviteCode != null &&
                      post.tournamentInviteCode!.isNotEmpty)
                  ? '?invite=${Uri.encodeComponent(post.tournamentInviteCode!)}'
                  : '';
              context.push('/tournaments/$tournamentId$inviteParam');
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isLive
                                    ? const Color(0xFFFEF2F2)
                                    : isCompleted
                                    ? const Color(0xFFF0FDF4)
                                    : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isLive
                                    ? l10n.liveLiveBadge
                                    : isCompleted
                                    ? l10n.clubDetailCompleted
                                    : l10n.clubDetailClubTournamentBadge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: isLive
                                      ? const Color(0xFFDC2626)
                                      : isCompleted
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            if (sportText != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                sportText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tournamentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // ── Matches Preview (if bracket/matches exist) ──
          if (hasMatches) ...[
            Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: previewMatches.map((m) {
                  final s1 = m.sets.isNotEmpty ? m.sets.last.score1 : m.score1;
                  final s2 = m.sets.isNotEmpty ? m.sets.last.score2 : m.score2;
                  final hasPlayed =
                      m.isCompleted || m.isLive || s1 > 0 || s2 > 0;
                  final isT1Winner =
                      m.winnerId == m.team1Id || (hasPlayed && s1 > s2);
                  final isT2Winner =
                      m.winnerId == m.team2Id || (hasPlayed && s2 > s1);
                  final roundLabel = MatchRoundLabel.formatRound(
                    match: m,
                    short: true,
                    l10n: l10n,
                  );

                  return InkWell(
                    onTap: () => context.push(
                      NavigationHelper.getLiveMatchRoute(tournamentId, m.id),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bgSurface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: m.isLive
                              ? const Color(0xFFFECACA)
                              : colors.border.withValues(alpha: 0.5),
                          width: m.isLive ? 1.2 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Stage / Round Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: m.isLive
                                  ? const Color(0xFFFEF2F2)
                                  : colors.border.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              m.isLive ? l10n.liveLiveBadge : roundLabel,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: m.isLive
                                    ? const Color(0xFFDC2626)
                                    : colors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Team 1 vs Team 2
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.team1Name.isNotEmpty
                                      ? m.team1Name
                                      : l10n.communityTournamentPreviewWaiting,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isT1Winner
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m.team2Name.isNotEmpty
                                      ? m.team2Name
                                      : l10n.communityTournamentPreviewWaiting,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isT2Winner
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Scores
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                hasPlayed ? '$s1' : '-',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isT1Winner
                                      ? AppTheme.primary
                                      : colors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasPlayed ? '$s2' : '-',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isT2Winner
                                      ? AppTheme.primary
                                      : colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // ── Bottom Action Button ──
          Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
          InkWell(
            onTap: () {
              final inviteParam =
                  (post.tournamentInviteCode != null &&
                      post.tournamentInviteCode!.isNotEmpty)
                  ? '?invite=${Uri.encodeComponent(post.tournamentInviteCode!)}'
                  : '';
              context.push('/tournaments/$tournamentId$inviteParam');
            },
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasMatches
                        ? l10n.communityTournamentPreviewViewBracket
                        : l10n.communityTournamentPreviewViewDetails,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _sportLabel(String? sportKey, AppLocalizations l10n) {
    switch (sportKey?.toUpperCase()) {
      case 'BADMINTON':
        return l10n.createClubTournament_sportBadminton;
      case 'TENNIS':
        return l10n.createClubTournament_sportTennis;
      case 'PICKLEBALL':
        return l10n.createClubTournament_sportPickleball;
      case 'TABLE_TENNIS':
      case 'TABLETENNIS':
        return l10n.createClubTournament_sportTableTennis;
      case 'FOOTBALL':
        return l10n.createClubTournament_sportFootball;
      default:
        return sportKey;
    }
  }
}
