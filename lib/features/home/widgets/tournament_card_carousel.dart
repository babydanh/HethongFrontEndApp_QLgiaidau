import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class TournamentCardCarousel extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const TournamentCardCarousel({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  String _getFormatLabel(
    BuildContext context,
    String matchType,
    String? genderRestriction,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final mt = matchType.toUpperCase();
    final gr = genderRestriction?.toUpperCase() ?? '';
    if (mt == 'SINGLES') {
      if (gr == 'FEMALE') return l10n.singlesFemale;
      if (gr == 'MALE') return l10n.singlesMale;
      return l10n.tournamentCardSingles;
    }
    if (mt == 'DOUBLES') {
      if (gr == 'FEMALE') return l10n.doublesFemale;
      if (gr == 'MALE') return l10n.doublesMale;
      if (gr == 'MIXED') return l10n.doublesMixed;
      return l10n.tournamentCardDoubles;
    }
    if (mt == 'MIXED_DOUBLES' || mt == 'MIXED' || gr == 'MIXED') {
      return l10n.doublesMixed;
    }
    return mt == 'DOUBLES'
        ? l10n.tournamentCardDoubles
        : (mt == 'SINGLES' ? l10n.tournamentCardSingles : l10n.doublesMixed);
  }

  List<String> _getCategoryChips(BuildContext context, Tournament t) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> chips = [];
    if (t.divisions.isNotEmpty) {
      for (var div in t.divisions) {
        final formatLabel = _getFormatLabel(
          context,
          div.matchType,
          div.genderRestriction,
        );
        final label =
            (div.name.trim() != t.name.trim() &&
                div.name.trim().isNotEmpty &&
                div.name.trim() != 'Nội dung chính')
            ? div.name
            : formatLabel;
        final regCount = div.participantCount;
        final maxCount = div.maxParticipants != null
            ? "${div.maxParticipants}"
            : "-";

        chips.add("$label ($regCount/$maxCount)");
      }
    }
    if (chips.isEmpty) {
      final nameLower = t.name.toLowerCase();
      final descLower = t.description.toLowerCase();

      // Safely check gender from divisions if available
      final divGender = t.divisions.isNotEmpty
          ? (t.divisions.first.genderRestriction ?? '').toLowerCase()
          : '';

      // Check Female
      if (divGender == 'female' ||
          nameLower.contains("đơn nữ") ||
          descLower.contains("đơn nữ")) {
        chips.add(l10n.singlesFemale);
      } else if (divGender == 'female' ||
          nameLower.contains("đôi nữ") ||
          descLower.contains("đôi nữ")) {
        chips.add(l10n.doublesFemale);
      }
      // Check Mixed
      else if (divGender == 'mixed' ||
          nameLower.contains("đôi nam nữ") ||
          descLower.contains("đôi nam nữ") ||
          nameLower.contains("nam nữ")) {
        chips.add(l10n.doublesMixed);
      }
      // Check Male
      else if (nameLower.contains("đơn nam") || descLower.contains("đơn nam")) {
        chips.add(l10n.singlesMale);
      } else if (nameLower.contains("đôi nam") ||
          descLower.contains("đôi nam")) {
        chips.add(l10n.doublesMale);
      }
      // Generic Singles / Doubles
      else if (nameLower.contains("đôi") ||
          descLower.contains("đôi") ||
          t.format == "doubles" ||
          t.maxPlayersPerTeam == 2) {
        chips.add(
          divGender == 'female'
              ? l10n.doublesFemale
              : (divGender == 'mixed' ? l10n.doublesMixed : l10n.doublesMale),
        );
      } else if (nameLower.contains("đơn") ||
          descLower.contains("đơn") ||
          t.format == "singles" ||
          t.maxPlayersPerTeam == 1) {
        chips.add(
          divGender == 'female' ? l10n.singlesFemale : l10n.singlesMale,
        );
      }
    }
    if (chips.isEmpty) {
      final isDoubles = t.format == "doubles" || t.maxPlayersPerTeam == 2;
      chips.add(isDoubles ? l10n.doublesMale : l10n.singlesMale);
    }
    return chips.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final sportLabel = switch (tournament.sport.toLowerCase()) {
      'badminton' => l10n.createClubTournament_sportBadminton,
      'tennis' => l10n.createClubTournament_sportTennis,
      'pickleball' => l10n.createClubTournament_sportPickleball,
      'table_tennis' => l10n.createClubTournament_sportTableTennis,
      'football' => l10n.createClubTournament_sportFootball,
      _ => l10n.homeSportFallback,
    }.toUpperCase();
    final normalizedStatus = StatusHelper.normalizeTournamentStatus(
      tournament.status,
    );
    String statusText = l10n.profileRegistrationOpen.toUpperCase();
    Color statusBg = const Color(0xFF2563EB);
    if (StatusHelper.isTournamentInProgress(normalizedStatus)) {
      statusText = l10n.homeInProgressStatus.toUpperCase();
      statusBg = const Color(0xFF22C55E);
    } else if (StatusHelper.isTournamentCompleted(normalizedStatus)) {
      statusText = l10n.homeCompletedStatus.toUpperCase();
      statusBg = Colors.grey.shade600;
    } else if (StatusHelper.isTournamentRegistrationClosed(normalizedStatus) ||
        tournament.status.toUpperCase() == 'REGISTRATION_CLOSED' ||
        tournament.status.toUpperCase() == 'CLOSED') {
      statusText = l10n.registrationClosedTag;
      statusBg = const Color(0xFFEF4444);
    } else if (StatusHelper.isTournamentRegistration(normalizedStatus)) {
      statusText = l10n.profileRegistrationOpen.toUpperCase();
      statusBg = const Color(0xFF2563EB);
    }

    final start = tournament.startDate ?? tournament.createdAt;
    final end = tournament.endDate ?? start.add(const Duration(days: 7));

    String formatDayMonth(DateTime dt) {
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}";
    }

    final startDateStr = formatDayMonth(start);
    final endDateStr = formatDayMonth(end);
    final categoryChips = _getCategoryChips(context, tournament);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1.6,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900,
                        image:
                            tournament.bannerUrl != null &&
                                tournament.bannerUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(tournament.bannerUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          tournament.bannerUrl == null ||
                              tournament.bannerUrl!.isEmpty
                          ? Center(
                              child: Image.asset(
                                "assets/images/sporto_v1_with_text.png",
                                width: 120,
                                fit: BoxFit.contain,
                              ),
                            )
                          : null,
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sportLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament.name.isNotEmpty
                                ? tournament.name
                                : l10n.unnamed,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (categoryChips.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: categoryChips.take(3).map((chipText) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.textPrimary.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: colors.textPrimary.withValues(
                                        alpha: 0.15,
                                      ),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    chipText,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: colors.textMuted,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$startDateStr - $endDateStr",
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.group_rounded,
                            color: colors.textMuted,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${tournament.maxTeams} ${l10n.teamsUnit}",
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.account_tree_rounded,
                            color: colors.textMuted,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              switch (tournament.bracketType.toLowerCase()) {
                                'single_elimination' => l10n.eliminationSingle,
                                'double_elimination' => l10n.eliminationDouble,
                                'round_robin' => l10n.roundRobin,
                                'group_stage' => l10n.groupStage,
                                _ => tournament.bracketType,
                              },
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
