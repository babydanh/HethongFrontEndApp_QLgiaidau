import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/live_match_card_v2.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/bracket_format_icons.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';

class LiveTab extends StatefulWidget {
  final List<MatchModel> liveMatches;
  final String? tournamentId;
  final List<TournamentDivision> divisions;
  final String? selectedDivisionId;
  final ValueChanged<TournamentDivision>? onSelectDivision;

  const LiveTab({
    super.key,
    required this.liveMatches,
    this.tournamentId,
    this.divisions = const [],
    this.selectedDivisionId,
    this.onSelectDivision,
  });

  @override
  State<LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends State<LiveTab> {
  String? _expandedDivisionId;

  @override
  void initState() {
    super.initState();
    _expandedDivisionId =
        widget.selectedDivisionId ??
        (widget.divisions.isNotEmpty ? widget.divisions.first.id : null);
  }

  @override
  void didUpdateWidget(covariant LiveTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDivisionId != oldWidget.selectedDivisionId &&
        widget.selectedDivisionId != null) {
      setState(() {
        _expandedDivisionId = widget.selectedDivisionId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    if (widget.liveMatches.isEmpty && widget.divisions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.bgSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.radio_outlined,
                size: 26,
                color: colors.textMuted.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.liveNoMatchesRunning,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.liveNoMatchesSubtitle,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Nếu có nhiều divisions (nội dung thi đấu), render danh sách division và danh sách trận đấu inline ngay dưới từng division
    if (widget.divisions.length > 1) {
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
        itemCount: widget.divisions.length,
        itemBuilder: (context, index) {
          final div = widget.divisions[index];
          final isExpanded = _expandedDivisionId == div.id;
          final maxP = div.maxParticipants ?? 0;
          final curP = div.participantCount;
          final isFull = maxP > 0 && curP >= maxP;

          // Lọc các trận live thuộc đúng division này
          final divLiveMatches = widget.liveMatches.where((m) {
            final mDiv =
                m.divisionId ??
                m.scoreDetails?['division_id']?.toString() ??
                m.tournamentConfig?['division_id']?.toString();
            return mDiv != null && mDiv.isNotEmpty && mDiv == div.id;
          }).toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExpanded
                    ? AppTheme.primary
                    : colors.border.withValues(alpha: 0.7),
                width: isExpanded ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header division đồng bộ với OverviewTab
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedDivisionId = isExpanded ? null : div.id;
                    });
                    widget.onSelectDivision?.call(div);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isExpanded
                                ? AppTheme.primary
                                : AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isExpanded
                                  ? AppTheme.primary
                                  : AppTheme.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Center(
                            child: BracketFormatIcons.getIcon(
                              div.bracketType,
                              size: 18,
                              color: isExpanded
                                  ? Colors.white
                                  : AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      div.name,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isExpanded
                                            ? FontWeight.w800
                                            : FontWeight.w700,
                                        color: isExpanded
                                            ? AppTheme.primary
                                            : colors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (divLiveMatches.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFEF4444,
                                        ).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(
                                            0xFFEF4444,
                                          ).withValues(alpha: 0.28),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${divLiveMatches.length}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFDC2626),
                                              height: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (div.matchType.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  div.matchType == 'DOUBLES'
                                      ? l10n.matchTypeDoubles
                                      : l10n.matchTypeSingles,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isFull) ...[
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.bgSurface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.border.withValues(alpha: 0.8),
                              ),
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_alt_outlined,
                              size: 13,
                              color: colors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              maxP > 0 ? '$curP/$maxP' : '$curP',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.fastOutSlowIn,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: isExpanded
                                ? AppTheme.primary
                                : colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Danh sách trận đấu MỞ RA VỚI ANIMATION MƯỢT MÀ (AnimatedCrossFade)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: colors.border.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 10),
                        if (divLiveMatches.isNotEmpty)
                          ...divLiveMatches.map((match) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: LiveMatchCardV2(
                                match: match,
                                isLive: true,
                                onTap: () {
                                  context.push(
                                    NavigationHelper.getLiveMatchRoute(
                                      widget.tournamentId ??
                                          match.tournamentId ??
                                          '',
                                      match.id,
                                    ),
                                  );
                                },
                              ),
                            );
                          })
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: colors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.liveDivisionEmpty,
                                  style: TextStyle(
                                    fontSize: 12,
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
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                  sizeCurve: Curves.fastOutSlowIn,
                  firstCurve: Curves.easeOut,
                  secondCurve: Curves.easeIn,
                ),
              ],
            ),
          );
        },
      );
    }

    // Khi chỉ có 1 division hoặc không có divisions
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
      itemCount: widget.liveMatches.length,
      itemBuilder: (context, index) {
        final match = widget.liveMatches[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: LiveMatchCardV2(
            match: match,
            isLive: true,
            onTap: () {
              context.push(
                NavigationHelper.getLiveMatchRoute(
                  widget.tournamentId ?? match.tournamentId ?? '',
                  match.id,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
