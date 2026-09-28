import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/elo_helpers.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_team_repository.dart';
import 'package:flutter/material.dart';

/// Card ELO nổi bật dùng lại cho Home/Dashboard/Profile.
///
/// Giữ style hiện tại của app (dark premium card), chỉ bổ sung thông tin web có:
/// rank nổi bật, progress tier, peak ELO, loại đánh và trạng thái khiên.
class EloProgressCard extends StatefulWidget {
  final String userName;
  final String? userEmail;
  final String? avatarUrl;
  final List<PlayerRanking> rankings;
  final FootballTeamSummary? footballTeam;
  final VoidCallback? onTapProfile;

  const EloProgressCard({
    super.key,
    required this.userName,
    this.userEmail,
    this.avatarUrl,
    required this.rankings,
    this.footballTeam,
    this.onTapProfile,
  });

  @override
  State<EloProgressCard> createState() => _EloProgressCardState();
}

class _EloProgressCardState extends State<EloProgressCard> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final colorScheme = Theme.of(context).colorScheme;
    final categoryOptions = <String, String>{
      for (final rank in widget.rankings)
        if (rank.categoryId != null && rank.categoryName != null)
          rank.categoryId!: rank.categoryName!,
    };
    final activeRanks = _selectedCategoryId == null
        ? widget.rankings
        : widget.rankings
              .where((rank) => rank.categoryId == _selectedCategoryId)
              .toList();
    final activeRank = EloHelpers.getBestRankForCategory(activeRanks);
    final hasRank = activeRank != null && activeRank.matchesPlayed > 0;
    final eloPoints = activeRank?.eloPoints ?? 1000;
    final matchesPlayed = activeRank?.matchesPlayed ?? 0;
    final matchesWon = activeRank?.matchesWon ?? 0;
    final winRate = EloHelpers.getRankWinRate(activeRank);
    final peakElo = activeRank?.peakElo ?? eloPoints;
    final progress = EloHelpers.getEloProgressInfo(eloPoints, l10n);
    final currentThreshold = EloHelpers.thresholds[progress.currentIndex];
    final nextThreshold = progress.nextIndex == null
        ? null
        : EloHelpers.thresholds[progress.nextIndex!];
    final shield = EloHelpers.getShieldStatus(activeRank, l10n);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL * 2),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: widget.userName, avatarUrl: widget.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName.isNotEmpty
                          ? widget.userName
                          : l10n.ranking_userFallback,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.userEmail?.isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.userEmail!,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.onTapProfile != null)
                IconButton(
                  onPressed: widget.onTapProfile,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                  ),
                  tooltip: l10n.ranking_profileTooltip,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: colors.borderLight),
          if (categoryOptions.length > 1) ...[
            const SizedBox(height: 14),
            Text(
              l10n.ranking_categoryLabel,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in categoryOptions.entries)
                  Tooltip(
                    message: entry.value,
                    child: ChoiceChip(
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 136),
                        child: Text(
                          entry.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      avatar: _selectedCategoryId == entry.key
                          ? Icon(
                              Icons.check_rounded,
                              color: colorScheme.primary,
                              size: 16,
                            )
                          : null,
                      selected: _selectedCategoryId == entry.key,
                      showCheckmark: false,
                      onSelected: (_) =>
                          setState(() => _selectedCategoryId = entry.key),
                      backgroundColor: colors.bgSurface,
                      selectedColor: colors.info.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: _selectedCategoryId == entry.key
                            ? colors.info
                            : colors.border,
                      ),
                      labelStyle: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: _selectedCategoryId == entry.key
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                    ),
                  ),
              ],
            ),
          ],
          if (widget.footballTeam != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
              child: Row(
                children: [
                  if (widget.footballTeam!.logoUrl?.isNotEmpty == true)
                    ClipOval(
                      child: Image.network(
                        widget.footballTeam!.logoUrl!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.groups_rounded,
                          color: colors.info,
                          size: 18,
                        ),
                      ),
                    )
                  else
                    Icon(Icons.groups_rounded, color: colors.info, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.ranking_topFootballTeam(widget.footballTeam!.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.ranking_eloValue(widget.footballTeam!.eloPoints),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ranking_progressTitle,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeRank == null
                          ? l10n.ranking_overviewLabel
                          : EloHelpers.getRankDisplayName(activeRank, l10n),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  l10n.ranking_eloValue(eloPoints),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasRank
                    ? EloHelpers.getTierName(progress.currentIndex, l10n)
                    : '${currentThreshold.minElo}',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasRank ? progress.label : EloHelpers.getOnboardingCopy(l10n),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: hasRank ? progress.percent / 100 : 0,
              minHeight: 8,
              backgroundColor: colors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(colors.info),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentThreshold.minElo}',
                style: TextStyle(color: colors.textMuted, fontSize: 10),
              ),
              Text(
                nextThreshold == null
                    ? l10n.ranking_maxElo
                    : '${nextThreshold.minElo}',
                style: TextStyle(color: colors.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ShieldRow(status: shield),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: colors.borderLight),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: l10n.ranking_matchesLabel,
                  value: '$matchesPlayed',
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 28, color: colors.border),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: l10n.ranking_winsLabel,
                  value: '$matchesWon',
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 28, color: colors.border),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: l10n.ranking_winRateLabel,
                  value: '$winRate%',
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 28, color: colors.border),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: l10n.ranking_peakLabel,
                  value: '$peakElo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const _Avatar({required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 28,
      backgroundColor: context.colors.info.withValues(alpha: 0.12),
      backgroundImage: avatarUrl?.isNotEmpty == true
          ? NetworkImage(avatarUrl!)
          : null,
      child: avatarUrl?.isNotEmpty == true
          ? null
          : Text(
              initial,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _ShieldRow extends StatelessWidget {
  final ShieldStatus status;

  const _ShieldRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = switch (status.state) {
      ShieldState.active => (
        icon: Icons.verified_user_rounded,
        color: context.colors.success,
        bg: context.colors.success.withValues(alpha: 0.13),
      ),
      ShieldState.broken => (
        icon: Icons.shield_outlined,
        color: context.colors.warning,
        bg: context.colors.warning.withValues(alpha: 0.13),
      ),
      ShieldState.onboarding => (
        icon: Icons.shield_outlined,
        // This card is rendered on the light surface used by “Của tôi”.
        // White onboarding text was effectively invisible there.
        color: context.colors.textSecondary,
        bg: context.colors.bgSurface,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.color, size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              status.copy,
              style: TextStyle(
                color: config.color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
