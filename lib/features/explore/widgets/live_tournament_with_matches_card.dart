import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';

class LiveTournamentWithMatchesCard extends ConsumerStatefulWidget {
  final Tournament tournament;
  final String? filterStatus; // 'live', 'completed', 'scheduled'

  const LiveTournamentWithMatchesCard({
    super.key,
    required this.tournament,
    this.filterStatus,
  });

  @override
  ConsumerState<LiveTournamentWithMatchesCard> createState() =>
      _LiveTournamentWithMatchesCardState();
}

class _LiveTournamentWithMatchesCardState
    extends ConsumerState<LiveTournamentWithMatchesCard> {
  final Map<String, int> _cheerCounts = {};
  final Set<String> _cheerInFlight = {};
  int _currentMatchIndex = 0;
  static const int _pageSize = 4;

  String _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;

    String apiBase = 'http://localhost:3000/api/v1';
    try {
      apiBase = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
      if (!kIsWeb && Platform.isAndroid && apiBase.contains('localhost')) {
        apiBase = apiBase.replaceAll('localhost', '10.0.2.2');
      }
    } catch (_) {}

    final host = apiBase.replaceAll('/api/v1', '');
    return '$host$url';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final matchesAsync = ref.watch(matchesProvider(widget.tournament.id));
    final resolvedLogoUrl = _resolveImageUrl(widget.tournament.logoUrl);

    return matchesAsync.when(
      data: (matches) {
        final validMatches = matches.where((m) {
          final t1 = m.team1Name.trim().toUpperCase();
          final t2 = m.team2Name.trim().toUpperCase();
          final isT1Tbd = t1.isEmpty || t1 == 'TBD' || t1 == 'BYE';
          final isT2Tbd = t2.isEmpty || t2 == 'TBD' || t2 == 'BYE';
          if (isT1Tbd && isT2Tbd) return false;

          final status = m.status.toUpperCase();
          final isDone =
              m.isCompleted ||
              status == 'COMPLETED' ||
              status == 'FINISHED' ||
              status == 'DONE' ||
              status == 'ENDED' ||
              m.completedAt != null ||
              m.isByeMatch ||
              m.isBye;
          final isOngoing =
              m.isLive ||
              status == 'ONGOING' ||
              status == 'LIVE' ||
              status == 'IN_PROGRESS';

          if (widget.filterStatus == 'live') return isOngoing;
          if (widget.filterStatus == 'completed') return isDone;
          if (widget.filterStatus == 'scheduled') return !isOngoing && !isDone;
          return true;
        }).toList();

        // Match sections must render only persisted matches matching the
        // requested status. Never fall back to another status or fake scores.
        if (validMatches.isEmpty) return const SizedBox.shrink();
        final displayMatches = validMatches;

        // Calculate total pages (each page shows up to 4 matches)
        final totalPages = (displayMatches.length / _pageSize).ceil();
        final safePageIndex = _currentMatchIndex.clamp(0, totalPages - 1);
        final startIndex = safePageIndex * _pageSize;
        final endIndex = (startIndex + _pageSize).clamp(
          0,
          displayMatches.length,
        );
        final currentPageMatches = displayMatches.sublist(startIndex, endIndex);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Outer Header: Tournament Logo + Name + ELO Tag ──
              GestureDetector(
                onTap: () => context.push('/intro/${widget.tournament.id}'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.border, width: 1),
                        ),
                        child: ClipOval(
                          child: resolvedLogoUrl.isNotEmpty
                              ? Image.network(
                                  resolvedLogoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.asset(
                                          "assets/images/sporto_v1_with_text.png",
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    "assets/images/sporto_v1_with_text.png",
                                    fit: BoxFit.contain,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.tournament.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.tournament.isRanked
                                  ? "Giải xếp hạng"
                                  : "Giải đấu giao lưu",
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Matches Content Area ──
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0.0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                  child: Container(
                    key: ValueKey<int>(safePageIndex),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      key: ValueKey<String>(
                        'matches_page_${safePageIndex}_${currentPageMatches.length}',
                      ),
                      children: currentPageMatches.map((match) {
                        return Padding(
                          key: ValueKey<String>(match.id),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildMatchCard(context, match),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // ── Pagination Controls & Dots Indicator (Mượt mà với AnimatedSwitcher) ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: totalPages > 1
                    ? Column(
                        key: const ValueKey('pagination_visible'),
                        children: [
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: safePageIndex > 0
                                      ? () =>
                                            setState(() => _currentMatchIndex--)
                                      : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: safePageIndex > 0 ? 1.0 : 0.4,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.chevron_left_rounded,
                                        size: 18,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(totalPages, (idx) {
                                    final isSelected = idx == safePageIndex;
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      width: isSelected ? 16 : 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primary
                                            : const Color(0xFFCBD5E1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: safePageIndex < totalPages - 1
                                      ? () =>
                                            setState(() => _currentMatchIndex++)
                                      : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: safePageIndex < totalPages - 1
                                        ? 1.0
                                        : 0.4,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(
                        key: ValueKey('pagination_hidden'),
                        height: 6,
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildMatchCard(BuildContext context, MatchModel match) {
    final colors = context.colors;
    final isT1Tbd =
        match.team1Name.trim().toUpperCase() == 'TBD' ||
        match.team1Name.trim().toUpperCase() == 'BYE';
    final isT2Tbd =
        match.team2Name.trim().toUpperCase() == 'TBD' ||
        match.team2Name.trim().toUpperCase() == 'BYE';
    final isByeMatch = match.isBye || isT1Tbd || isT2Tbd;

    final bracketText =
        match.stageName ??
        (match.bracketPosition.bracket == 'losers'
            ? 'NHÁNH THUA'
            : (widget.tournament.bracketType == 'round_robin'
                  ? 'VÒNG BẢNG'
                  : 'VÒNG KNOCKOUT'));
    final sportText =
        AppConstants.sportNames[match.sportKey ?? widget.tournament.sport] ??
        match.sportKey ??
        widget.tournament.sport;
    final courtText = match.court.isNotEmpty ? match.court : 'Chưa xếp sân';

    List<String> getInitials(String name) {
      final parts = name
          .split('-')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        return [_getSingleInitials(parts[0]), _getSingleInitials(parts[1])];
      }
      final words = name.trim().split(' ');
      if (words.length >= 2) {
        return ['${words[0][0]}${words[1][0]}'.toUpperCase(), ''];
      }
      return [name.isNotEmpty ? name[0].toUpperCase() : '?', ''];
    }

    final t1Initials = getInitials(match.team1Name);
    final t2Initials = getInitials(match.team2Name);
    final cheerCount = _cheerCounts[match.id] ?? 0;
    final isCheered = cheerCount > 0;

    return GestureDetector(
      onTap: () => context.push('/live/${match.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Row: Stage Tag & Sport ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports_handball_rounded,
                      size: 12,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sportText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (bracketText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      bracketText,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9333EA),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Teams & Score Section ──
            Column(
              children: [
                // Team 1 Row
                Row(
                  children: [
                    _DoubleAvatarWidget(
                      initial1: t1Initials.isNotEmpty ? t1Initials[0] : 'NM',
                      initial2: t1Initials.length > 1 ? t1Initials[1] : '',
                      color: const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.team1Name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isByeMatch && isT2Tbd && !isT1Tbd)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Vô thẳng',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(minWidth: 28),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (match.sets.isNotEmpty
                                  ? match.sets.last.score1 >
                                        match.sets.last.score2
                                  : match.score1 > match.score2)
                              ? AppTheme.primary.withValues(alpha: 0.12)
                              : colors.bgSurface,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color:
                                (match.sets.isNotEmpty
                                    ? match.sets.last.score1 >
                                          match.sets.last.score2
                                    : match.score1 > match.score2)
                                ? AppTheme.primary.withValues(alpha: 0.4)
                                : colors.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${match.sets.isNotEmpty ? match.sets.last.score1 : match.score1}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color:
                                (match.sets.isNotEmpty
                                    ? match.sets.last.score1 >
                                          match.sets.last.score2
                                    : match.score1 > match.score2)
                                ? AppTheme.primary
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                // Team 2 Row
                Row(
                  children: [
                    _DoubleAvatarWidget(
                      initial1: t2Initials.isNotEmpty ? t2Initials[0] : 'VQ',
                      initial2: t2Initials.length > 1 ? t2Initials[1] : '',
                      color: const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.team2Name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isByeMatch && isT1Tbd && !isT2Tbd)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Vô thẳng',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(minWidth: 28),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (match.sets.isNotEmpty
                                  ? match.sets.last.score2 >
                                        match.sets.last.score1
                                  : match.score2 > match.score1)
                              ? AppTheme.primary.withValues(alpha: 0.12)
                              : colors.bgSurface,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color:
                                (match.sets.isNotEmpty
                                    ? match.sets.last.score2 >
                                          match.sets.last.score1
                                    : match.score2 > match.score1)
                                ? AppTheme.primary.withValues(alpha: 0.4)
                                : colors.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${match.sets.isNotEmpty ? match.sets.last.score2 : match.score2}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color:
                                (match.sets.isNotEmpty
                                    ? match.sets.last.score2 >
                                          match.sets.last.score1
                                    : match.score2 > match.score1)
                                ? AppTheme.primary
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: colors.border.withValues(alpha: 0.4)),
            const SizedBox(height: 8),

            // ── Single Merged Footer Row: Location & Quick Action Icons ──
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    courtText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: colors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Cheer Button (Fresh Bright Capsule Button)
                InkWell(
                  onTap: () async {
                    if (_cheerInFlight.contains(match.id)) return;
                    _cheerInFlight.add(match.id);
                    final previousCount = _cheerCounts[match.id] ?? 0;
                    setState(() {
                      _cheerCounts[match.id] = previousCount + 1;
                    });
                    try {
                      await ref
                          .read(matchRepositoryProvider)
                          .cheerMatch(match.id);
                      final count = await ref
                          .read(matchRepositoryProvider)
                          .getCheerCount(match.id);
                      if (mounted) {
                        setState(() => _cheerCounts[match.id] = count);
                      }
                    } catch (_) {
                      if (mounted) {
                        setState(() => _cheerCounts[match.id] = previousCount);
                      }
                    } finally {
                      _cheerInFlight.remove(match.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isCheered
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCheered
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCheered
                              ? Icons.favorite
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: isCheered
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFE11D48),
                        ),
                        if (cheerCount > 0) ...[
                          const SizedBox(width: 5),
                          Text(
                            '$cheerCount',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isCheered
                                  ? const Color(0xFFDC2626)
                                  : colors.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Share Button (Fresh Bright Circle Button)
                InkWell(
                  onTap: () {
                    AppShareModal.show(
                      context: context,
                      title: '${match.team1Name} VS ${match.team2Name}',
                      subtitle:
                          'Giải đấu: ${widget.tournament.name} • ${match.court.isNotEmpty ? match.court : "Đang thi đấu"}',
                      webUrl: 'https://sporto.asia/live/${match.id}',
                      imageUrl: widget.tournament.logoUrl,
                      badgeText: match.isLive
                          ? 'Trận đấu đang Live 🔴'
                          : 'Trận đấu',
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.share_rounded,
                        size: 15,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSingleInitials(String s) {
    final parts = s.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}'
          .toUpperCase();
    }
    return s.isNotEmpty ? s[0].toUpperCase() : '?';
  }
}

class _DoubleAvatarWidget extends StatelessWidget {
  final String initial1;
  final String initial2;
  final Color color;

  const _DoubleAvatarWidget({
    required this.initial1,
    required this.initial2,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (initial2.isEmpty || initial2 == '?') {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colors.bgCard,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Center(
          child: Text(
            initial1,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 48,
      height: 28,
      child: Stack(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Center(
              child: Text(
                initial1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: Text(
                  initial2,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
