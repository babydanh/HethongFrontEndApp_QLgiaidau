import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/status_badge.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class TournamentCardWithBanner extends ConsumerStatefulWidget {
  final Tournament tournament;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;

  const TournamentCardWithBanner({
    super.key,
    required this.tournament,
    required this.onTap,
    this.margin,
  });

  @override
  ConsumerState<TournamentCardWithBanner> createState() =>
      _TournamentCardWithBannerState();
}

class _TournamentCardWithBannerState
    extends ConsumerState<TournamentCardWithBanner> {
  String _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    if (url.startsWith("http")) return url;
    String apiBase = "http://localhost:3000/api/v1";
    try {
      apiBase = dotenv.env["API_BASE_URL"] ?? "http://localhost:3000/api/v1";
      if (Platform.isAndroid && apiBase.contains("localhost")) {
        apiBase = apiBase.replaceAll("localhost", "10.0.2.2");
      }
    } catch (_) {}
    final host = apiBase.replaceAll("/api/v1", "");
    return "$host$url";
  }

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

  Widget _buildDateBlock(BuildContext context, dynamic colors) {
    final start = widget.tournament.startDate ?? widget.tournament.createdAt;
    final end = widget.tournament.endDate ?? start.add(const Duration(days: 7));
    final startDay = start.day.toString().padLeft(2, '0');
    final endDay = end.day.toString().padLeft(2, '0');
    final startMonth = start.month.toString().padLeft(2, '0');
    final endMonth = end.month.toString().padLeft(2, '0');
    final isSameMonth = startMonth == endMonth;
    final l10n = AppLocalizations.of(context)!;
    final monthText = isSameMonth
        ? l10n.tournamentCardMonthLabel(startMonth)
        : '${l10n.tournamentCardMonthLabel(startMonth)} - ${l10n.tournamentCardMonthLabel(endMonth)}';

    return Container(
      constraints: const BoxConstraints(minWidth: 70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$startDay - $endDay",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            monthText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _getSportEmojiAndLabel(BuildContext context, String sport) {
    final l10n = AppLocalizations.of(context)!;
    final sportKey = sport.toLowerCase();
    final label = switch (sportKey) {
      'badminton' => l10n.createClubTournament_sportBadminton,
      'tennis' => l10n.createClubTournament_sportTennis,
      'pickleball' => l10n.createClubTournament_sportPickleball,
      'table_tennis' => l10n.createClubTournament_sportTableTennis,
      'football' => l10n.createClubTournament_sportFootball,
      _ => l10n.homeSportFallback,
    };
    final emoji = switch (sportKey) {
      'badminton' => '🏸',
      'tennis' => '🎾',
      'pickleball' || 'table_tennis' => '🏓',
      _ => '🏆',
    };
    return '$emoji ${label.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolvedBannerUrl = _resolveImageUrl(widget.tournament.bannerUrl);
    final hasBanner = resolvedBannerUrl.isNotEmpty;
    final l10n = AppLocalizations.of(context)!;
    final categoryChips = _getCategoryChips(context, widget.tournament);

    // Gom gọn khi giải đấu có nhiều hình thức/nội dung thi đấu
    final displayChips = categoryChips.length > 2
        ? [
            ...categoryChips.take(1),
            l10n.tournamentCardContentCount(categoryChips.length - 1),
          ]
        : categoryChips;

    final resolvedLogoUrl = _resolveImageUrl(
      widget.tournament.logoUrl ?? widget.tournament.creatorAvatarUrl,
    );
    final hasLogo = resolvedLogoUrl.isNotEmpty;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin:
            widget.margin ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.7),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner Header (tăng height ráo & cao ráo lên 185px)
                  SizedBox(
                    height: 185,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasBanner)
                          Image.network(
                            resolvedBannerUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primary,
                                    AppTheme.primaryDark,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Image.asset(
                                  "assets/images/sporto_v1_with_text.png",
                                  width: 130,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primary,
                                  AppTheme.primaryDark,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                "assets/images/sporto_v1_with_text.png",
                                width: 130,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        // Status badge top-left
                        Positioned(
                          top: 10,
                          left: 10,
                          child: StatusBadge(
                            statusKey: widget.tournament.status,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Details Body (padding top 18 for floating logo)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Column: Date Block
                        _buildDateBlock(context, colors),

                        // Vertical divider
                        Container(
                          width: 1,
                          height: 54,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: colors.border.withValues(alpha: 0.6),
                        ),

                        // Right Column: Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: Sport + ELO Tag
                              Row(
                                children: [
                                  Text(
                                    _getSportEmojiAndLabel(
                                      context,
                                      widget.tournament.sport,
                                    ),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: colors.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (widget.tournament.isRanked != true) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.bgSurface,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: colors.border,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        l10n.tournamentCardEloUnranked,
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          color: colors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (widget.tournament.isRanked == true) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFBEB),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(0xFFFDE68A),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        l10n.tournamentCardEloRanked,
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              // Row 2: Title
                              Text(
                                widget.tournament.name,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.tournament.locationAddress != null &&
                                  widget.tournament.locationAddress!
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 12,
                                      color: colors.textMuted,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        widget.tournament.locationAddress!
                                            .trim(),
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: colors.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 5),
                              // Row 3: Fee & Format/Division Chips
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    widget.tournament.entryFee == null ||
                                            widget.tournament.entryFee == 0
                                        ? l10n.freePrice
                                        : "${NumberFormat.decimalPattern().format(widget.tournament.entryFee)} đ",
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                  Text(
                                    "•",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                  if (displayChips.isNotEmpty)
                                    ...displayChips.map(
                                      (chipText) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.bgSurface,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: colors.border.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          chipText,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.bgSurface,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: colors.border.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        widget.tournament.format ==
                                                "single_elimination"
                                            ? l10n.eliminationSingle
                                            : l10n.roundRobin,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Floating Logo Avatar (top: 163 cho height 185)
              Positioned(
                top: 163,
                left: 14,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.bgSurface,
                    border: Border.all(color: colors.bgCard, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasLogo
                        ? Image.network(
                            resolvedLogoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                "assets/images/sporto_v1_with_text.png",
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              "assets/images/sporto_v1_with_text.png",
                              fit: BoxFit.contain,
                            ),
                          ),
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
