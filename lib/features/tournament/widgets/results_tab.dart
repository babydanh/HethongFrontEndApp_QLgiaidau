import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';

/// "Kết quả" tab: the honour podium (champion, runner-up, third place) and a
/// share icon. The match board lives in the "Đang diễn ra" tab.
class ResultsTab extends ConsumerWidget {
  final String tournamentId;

  final String? selectedDivisionId;
  final String? selectedDivision;
  final String? matchType;

  /// Opens the share sheet; null hides the share icon.
  final VoidCallback? onShare;

  const ResultsTab({
    super.key,
    required this.tournamentId,
    this.selectedDivisionId,
    this.selectedDivision,
    this.matchType,
    this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(
      tournamentResultProvider((
        tournamentId: tournamentId,
        divisionId: selectedDivisionId,
      )),
    );

    final awards = resultAsync.when(
      data: (data) {
        final rawAwards = data['awards'];
        if (rawAwards is! List || rawAwards.isEmpty) {
          return _emptyState(context);
        }
        return _buildPodium(context, rawAwards);
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      ),
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
    final teamName =
        participant['teamName']?.toString() ??
        AppLocalizations.of(context)!.matchNotDetermined;
    final members = _visibleMembers(participant);
    final memberNames = members
        .map((member) => member['fullName']?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty)
        .join(' · ');
    final badgeColor = colors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.border.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: badgeColor,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (memberNames.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    memberNames,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  badgeTitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (members.isNotEmpty) _buildMemberAvatars(members, 17, badgeColor),
        ],
      ),
    );
  }
}
