import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final String selectedSport;
  final String searchQuery;
  final String? provinceCode;
  final bool standalone;
  final bool isFilterExpanded;
  const LeaderboardScreen({
    super.key,
    this.selectedSport = 'all',
    this.searchQuery = '',
    this.provinceCode,
    this.standalone = false,
    this.isFilterExpanded = false,
  });

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _selectedCategory = 'all';
  String? _selectedGender = 'MALE';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedSport;
  }

  @override
  void didUpdateWidget(covariant LeaderboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSport != widget.selectedSport) {
      setState(() {
        _selectedCategory = widget.selectedSport;
      });
    }
  }

  RankingQuery get _rankingQuery => (
    categoryId: _selectedCategory,
    matchType: '',
    genderRestriction: _selectedGender,
    provinceCode: widget.provinceCode,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final authState = ref.watch(authProvider);
    final isAuth = authState.isAuthenticated;
    final profileAsync = ref.watch(userProfileProvider);
    final currentUserId = profileAsync.asData?.value.id;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      body: SafeArea(
        child: categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return _emptyState(
                context,
                icon: Icons.sports_rounded,
                title: l10n.leaderboardNoSports,
                subtitle: l10n.leaderboardNoSportsSubtitle,
                onRetry: () => ref.refresh(categoriesProvider),
              );
            }

            // Xử lý xác định categoryId thực tế
            String effectiveCategoryId = _selectedCategory;
            if (effectiveCategoryId == 'all' || effectiveCategoryId.isEmpty) {
              effectiveCategoryId = categories.first.id;
            } else {
              final found = categories.firstWhere(
                (c) =>
                    c.id == effectiveCategoryId ||
                    c.slug.toLowerCase() == effectiveCategoryId.toLowerCase(),
                orElse: () => categories.first,
              );
              effectiveCategoryId = found.id;
            }

            final effectiveCategory = categories.firstWhere(
              (category) => category.id == effectiveCategoryId,
              orElse: () => categories.first,
            );
            final isFootball =
                effectiveCategory.slug.toLowerCase() == 'football' ||
                effectiveCategory.name.toLowerCase().contains('bóng đá') ||
                effectiveCategory.name.toLowerCase().contains('football');
            final query = (
              categoryId: effectiveCategoryId,
              matchType: '',
              genderRestriction: _selectedGender,
              provinceCode: widget.provinceCode,
            );

            final rankingsAsync = ref.watch(rankingsProvider(query));
            final footballRankingsAsync = ref.watch(
              footballTeamRankingsProvider(effectiveCategoryId),
            );

            final content = SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: widget.standalone
                        ? 20
                        : (145 + (widget.isFilterExpanded ? 46 : 0)),
                  ),
                  if (!isFootball) _buildGenderFilter(colors),
                  const SizedBox(height: 12),
                  isFootball
                      ? footballRankingsAsync.when(
                          data: (teams) =>
                              _buildFootballTeamList(teams, colors),
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => _emptyState(
                            context,
                            icon: Icons.cloud_off_rounded,
                            title: l10n.rankingLoadErrorTitle,
                            subtitle: ErrorParser.parse(
                              e,
                              l10n.rankingLoadErrorSubtitle,
                            ),
                            onRetry: () => ref.refresh(
                              footballTeamRankingsProvider(effectiveCategoryId),
                            ),
                          ),
                        )
                      : rankingsAsync.when(
                          data: (rankings) => _buildRankingsList(
                            rankings,
                            colors,
                            isAuth,
                            currentUserId,
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => _emptyState(
                            context,
                            icon: Icons.cloud_off_rounded,
                            title: l10n.rankingLoadErrorTitle,
                            subtitle: ErrorParser.parse(
                              e,
                              l10n.rankingLoadErrorSubtitle,
                            ),
                            onRetry: () =>
                                ref.refresh(rankingsProvider(_rankingQuery)),
                          ),
                        ),
                ],
              ),
            );
            return content;
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _emptyState(
            context,
            icon: Icons.warning_amber_rounded,
            title: l10n.homeDataLoadError,
            subtitle: ErrorParser.parse(e, l10n.rankingLoadErrorSubtitle),
            onRetry: () => ref.refresh(categoriesProvider),
          ),
        ),
      ),
    );
  }

  // ─── Gender filter ────────────────────────────────────────────────────
  Widget _buildGenderFilter(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      ('MALE', l10n.clubRankingMale, Icons.male_rounded),
      ('FEMALE', l10n.clubRankingFemale, Icons.female_rounded),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final option = options[index];
          final selected = _selectedGender == option.$1;
          final textColor = selected ? AppTheme.primary : colors.textMuted;
          final iconColor = selected ? AppTheme.primary : colors.textMuted;
          final borderColor = selected ? AppTheme.primary : colors.border;

          return GestureDetector(
            onTap: () => setState(() => _selectedGender = option.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? AppTheme.secondaryLight : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(option.$3, size: 18, color: iconColor),
                  const SizedBox(width: 6),
                  Text(
                    option.$2,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Rankings list ─────────────────────────────────────────────────────
  Widget _buildRankingsList(
    List<PlayerRanking> rankings,
    AppColorsExtension colors,
    bool isAuth,
    String? currentUserId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final query = widget.searchQuery.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    // Lọc theo từ khoá tìm kiếm từ thanh search Home.
    final filtered = query.isEmpty
        ? rankings
        : rankings.where((r) {
            final haystack = [
              r.fullName,
              r.categoryName ?? '',
              r.tierName,
            ].join(' ').toLowerCase();
            return haystack.contains(query);
          }).toList();

    if (filtered.isEmpty) {
      if (query.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search_rounded,
                  size: 48,
                  color: colors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.leaderboardSearchEmpty(query),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.leaderboardSearchEmptyHint,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: colors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.clubRankingEmpty,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.clubRankingEmptyHint,
                style: TextStyle(fontSize: 12, color: colors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTableHeader(colors, l10n),
        ...filtered.map(
          (r) => _buildEloRow(r, colors, isAuth, currentUserId),
        ),
        if (isAuth && currentUserId != null &&
            !filtered.any((r) => r.userId == currentUserId))
          _buildMyRankBanner(filtered, colors, currentUserId),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildTableHeader(AppColorsExtension colors, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? colors.bgElevated : const Color(0xFFF1F5F9);
    final labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: colors.textMuted,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(l10n.leaderboardTableRank, style: labelStyle),
          ),
          Expanded(
            child: Text(
              l10n.leaderboardTablePlayer.toUpperCase(),
              style: labelStyle,
            ),
          ),
          Text(
            l10n.leaderboardTablePoints.toUpperCase(),
            style: labelStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildEloRow(
    PlayerRanking ranking,
    AppColorsExtension colors,
    bool isAuth,
    String? currentUserId,
  ) {
    final isMe = isAuth && ranking.userId == currentUserId;
    final subtitle = ranking.tierName.isNotEmpty ? ranking.tierName : null;

    return GestureDetector(
      onTap: () => context.push('/user/${ranking.userId}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? colors.info.withValues(alpha: 0.08) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: colors.border.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '${ranking.rank}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  _buildAvatar(ranking, colors),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ranking.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: isMe ? colors.info : colors.textPrimary,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${ranking.eloPoints}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(PlayerRanking ranking, AppColorsExtension colors) {
    const size = 38.0;
    final hasImage = ranking.avatarUrl != null && ranking.avatarUrl!.isNotEmpty;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: hasImage
            ? Image.network(
                ranking.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    _avatarFallback(ranking.fullName, colors),
              )
            : _avatarFallback(ranking.fullName, colors),
      ),
    );
  }

  Widget _avatarFallback(String name, AppColorsExtension colors) {
    return Container(
      color: colors.border.withValues(alpha: 0.35),
      alignment: Alignment.center,
      child: Text(
        _initial(name),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}'
          .toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  Widget _buildMyRankBanner(
    List<PlayerRanking> rankings,
    AppColorsExtension colors,
    String currentUserId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: colors.textMuted,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.leaderboardNoTop100,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFootballTeamList(
    List<FootballTeamRanking> teams,
    AppColorsExtension colors,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (teams.isEmpty) {
      return _emptyState(
        context,
        icon: Icons.sports_soccer_rounded,
        title: l10n.leaderboardNoRank4To10,
        subtitle: l10n.leaderboardNoRank11To100,
        onRetry: () {},
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            l10n.teamHeader,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ...teams.asMap().entries.map((entry) {
          final index = entry.key;
          final team = entry.value;
          final winRate = team.matchesPlayed > 0
              ? ((team.matchesWon / team.matchesPlayed) * 100).round()
              : 0;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (team.logoUrl != null && team.logoUrl!.isNotEmpty)
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(team.logoUrl!),
                  )
                else
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.bgCard,
                    child: Text(
                      team.teamName.isEmpty
                          ? '?'
                          : team.teamName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.teamName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${team.matchesWon}/${team.matchesPlayed} · $winRate%',
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${team.eloPoints} ELO',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (team.tierName != null && team.tierName!.isNotEmpty)
                      Text(
                        team.tierName!,
                        style: TextStyle(color: colors.textMuted, fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 100),
      ],
    );
  }

  // ─── Empty / error state ───────────────────────────────────────────────
  Widget _emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onRetry,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: Text(l10n.infoRetry)),
          ],
        ),
      ),
    );
  }
}