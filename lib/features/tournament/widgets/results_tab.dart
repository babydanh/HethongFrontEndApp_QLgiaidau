import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_bone_loading.dart';

/// The honour podium (champion, runner-up, third place) of one division.
/// Alone it is a scrolling page with a share icon; [embedded] makes it only the
/// podium, shown when the division has official results, and a tap on it
/// shares (the merged "Kết quả" tab puts the match board under it).
class ResultsTab extends ConsumerWidget {
  final String tournamentId;

  final String? selectedDivisionId;
  final String? selectedDivision;
  final String? matchType;

  /// Opens the share sheet; null hides the share icon.
  final VoidCallback? onShare;

  /// Podium only: no scroll view, no share icon, no empty or loading card.
  final bool embedded;

  const ResultsTab({
    super.key,
    required this.tournamentId,
    this.selectedDivisionId,
    this.selectedDivision,
    this.matchType,
    this.onShare,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(
      tournamentResultProvider((
        tournamentId: tournamentId,
        divisionId: selectedDivisionId,
      )),
    );

    if (embedded) return _embeddedPodium(context, resultAsync.value);

    final awards = resultAsync.when(
      data: (data) {
        final rawAwards = data['awards'];
        if (rawAwards is! List || rawAwards.isEmpty) {
          return _emptyState(context);
        }
        return _buildPodium(context, rawAwards);
      },
      loading: () => const BonePodiumLoading(),
      error: (e, _) => _emptyState(context),
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [if (onShare != null) _shareButton(context), awards],
      ),
    );
  }

  Widget _embeddedPodium(BuildContext context, Map<String, dynamic>? data) {
    final rawAwards = data?['awards'];
    if (rawAwards is! List || rawAwards.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      key: const ValueKey('results-podium-share'),
      behavior: HitTestBehavior.opaque,
      onTap: onShare,
      child: _buildPodium(context, rawAwards),
    );
  }

  Widget _shareButton(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: IconButton(
        key: const ValueKey('results-share'),
        tooltip: AppLocalizations.of(context)!.share,
        onPressed: onShare,
        icon: Icon(Icons.ios_share_rounded, size: 20, color: colors.textMuted),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              size: 40,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.resultsTab_emptyTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.resultsTab_emptySubtitle,
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<dynamic> rawAwards) {
    final l10n = AppLocalizations.of(context)!;
    final awards = rawAwards
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    Map<String, dynamic>? gold;
    Map<String, dynamic>? silver;
    final List<Map<String, dynamic>> bronzes = [];
    final List<Map<String, dynamic>> others = [];

    for (final award in awards) {
      final rank = (award['rank'] as num?)?.toInt() ?? 0;
      if (rank == 1) {
        gold = award;
      } else if (rank == 2) {
        silver = award;
      } else if (rank == 3 || rank == 4) {
        bronzes.add(award);
      } else {
        others.add(award);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (gold != null) ...[
          _buildAwardCard(context, gold, 1, l10n.resultsTab_champion),
          const SizedBox(height: 6),
        ],
        if (silver != null) ...[
          _buildAwardCard(context, silver, 2, l10n.resultsTab_runnerUp),
          const SizedBox(height: 6),
        ],
        for (int i = 0; i < bronzes.length; i++) ...[
          _buildAwardCard(
            context,
            bronzes[i],
            3,
            bronzes.length > 1
                ? l10n.resultsTab_jointThird
                : l10n.resultsTab_thirdPlace,
          ),
          const SizedBox(height: 6),
        ],
        for (final other in others) ...[
          _buildAwardCard(
            context,
            other,
            (other['rank'] as num?)?.toInt() ?? 0,
            l10n.resultsTab_rank((other['rank'] as num?)?.toInt() ?? 0),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  List<Map<String, dynamic>> _visibleMembers(Map<String, dynamic> participant) {
    final rawMembers = participant['members'];
    final members = rawMembers is List
        ? rawMembers
              .whereType<Map>()
              .map((member) => Map<String, dynamic>.from(member))
              .toList()
        : <Map<String, dynamic>>[];
    final memberLimit = switch (matchType?.toUpperCase()) {
      'SINGLES' => 1,
      'DOUBLES' || 'MIXED_DOUBLES' => 2,
      _ => members.length,
    };

    return members.take(memberLimit).toList();
  }

  Widget _buildMemberAvatars(
    List<Map<String, dynamic>> members,
    double radius,
    Color ringColor,
  ) {
    if (members.isEmpty) return const SizedBox.shrink();
    if (members.length == 1) {
      return _buildSingleAvatar(members.first, radius, ringColor);
    }

    return SizedBox(
      width: radius * 2 + 10,
      height: radius * 2,
      child: Stack(
        children: [
          Positioned(
            left: 10,
            child: _buildSingleAvatar(members[1], radius - 2, ringColor),
          ),
          Positioned(
            left: 0,
            child: _buildSingleAvatar(members[0], radius, ringColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleAvatar(
    Map<String, dynamic> member,
    double radius,
    Color ringColor,
  ) {
    final avatarUrl = member['avatarUrl']?.toString();
    final name = member['fullName']?.toString() ?? 'V';

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 1),
        color: Colors.white,
      ),
      child: ClipOval(
        child: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _avatarFallback(name, ringColor),
              )
            : _avatarFallback(name, ringColor),
      ),
    );
  }

  Widget _avatarFallback(String name, Color color) {
    return Container(
      color: color.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAwardCard(
    BuildContext context,
    Map<String, dynamic> award,
    int rank,
    String badgeTitle,
  ) {
    final colors = context.colors;
    final participant = award['participant'] is Map
        ? Map<String, dynamic>.from(award['participant'] as Map)
        : const <String, dynamic>{};
    // A doubles pair has no team name: show its players (shared label contract).
    final teamName = participant['teamName']?.toString();
    final players = toParticipantPlayers(participant);
    final isTeam = resolveParticipantDisplay(
      teamName: teamName,
      players: players,
    ).isTeam;
    final members = _visibleMembers(participant);
    final memberNames = members
        .map((member) => member['fullName']?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty)
        .join(' · ');
    final rankColor = _rankColor(context, rank);

    // Rank label on top (coloured by medal), the pair or team under it; a
    // strip on the left carries the same colour.
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.65)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: rankColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                rank == 1
                                    ? Icons.emoji_events_rounded
                                    : Icons.military_tech_rounded,
                                size: 15,
                                color: rankColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                badgeTitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: rankColor,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ParticipantLabel(
                            teamName: teamName,
                            players: players,
                            coloredAvatars: true,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (isTeam && memberNames.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              memberNames,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isTeam && members.isNotEmpty)
                      _buildMemberAvatars(members, 17, colors.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Medal colour of a podium rank; the lighter tones keep contrast on the dark
/// surface. Ranks past third use the muted text colour.
Color _rankColor(BuildContext context, int rank) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (rank) {
    1 => dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
    2 => dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
    3 => dark ? const Color(0xFFFB923C) : const Color(0xFF9A3412),
    _ => context.colors.textMuted,
  };
}
