import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/status_badge.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  String _getFormatLabel(String matchType, String? genderRestriction) {
    final mt = matchType.toUpperCase();
    final gr = genderRestriction?.toUpperCase() ?? '';
    if (mt == 'SINGLES') {
      if (gr == 'FEMALE') return 'Đơn Nữ';
      if (gr == 'MALE') return 'Đơn Nam';
      return 'Đơn';
    }
    if (mt == 'DOUBLES') {
      if (gr == 'FEMALE') return 'Đôi Nữ';
      if (gr == 'MALE') return 'Đôi Nam';
      if (gr == 'MIXED') return 'Đôi Nam Nữ';
      return 'Đôi';
    }
    if (mt == 'MIXED_DOUBLES' || mt == 'MIXED' || gr == 'MIXED') {
      return 'Đôi Nam Nữ';
    }
    return mt == 'DOUBLES' ? 'Đôi' : (mt == 'SINGLES' ? 'Đơn' : 'Đôi Nam Nữ');
  }

  List<String> _getCategoryChips(Tournament t) {
    final List<String> chips = [];
    if (t.divisions.isNotEmpty) {
      for (var div in t.divisions) {
        final formatLabel = _getFormatLabel(
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
        chips.add("Đơn Nữ");
      } else if (divGender == 'female' ||
          nameLower.contains("đôi nữ") ||
          descLower.contains("đôi nữ")) {
        chips.add("Đôi Nữ");
      }
      // Check Mixed
      else if (divGender == 'mixed' ||
          nameLower.contains("đôi nam nữ") ||
          descLower.contains("đôi nam nữ") ||
          nameLower.contains("nam nữ")) {
        chips.add("Đôi Nam Nữ");
      }
      // Check Male
      else if (nameLower.contains("đơn nam") || descLower.contains("đơn nam")) {
        chips.add("Đơn Nam");
      } else if (nameLower.contains("đôi nam") ||
          descLower.contains("đôi nam")) {
        chips.add("Đôi Nam");
      }
      // Generic Singles / Doubles
      else if (nameLower.contains("đôi") ||
          descLower.contains("đôi") ||
          t.format == "doubles" ||
          t.maxPlayersPerTeam == 2) {
        chips.add(
          divGender == 'female'
              ? "Đôi Nữ"
              : (divGender == 'mixed' ? "Đôi Nam Nữ" : "Đôi Nam"),
        );
      } else if (nameLower.contains("đơn") ||
          descLower.contains("đơn") ||
          t.format == "singles" ||
          t.maxPlayersPerTeam == 1) {
        chips.add(divGender == 'female' ? "Đơn Nữ" : "Đơn Nam");
      }
    }
    if (chips.isEmpty) {
      final isDoubles = t.format == "doubles" || t.maxPlayersPerTeam == 2;
      chips.add(isDoubles ? "Đôi Nam" : "Đơn Nam");
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
    final monthText = isSameMonth
        ? 'Thg $startMonth'
        : 'Thg $startMonth - Thg $endMonth';

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

  String _getSportEmojiAndLabel(String sport) {
    final label = (AppConstants.sportNames[sport] ?? sport).toUpperCase();
    String emoji = '🏆';
    if (sport.toLowerCase() == 'badminton') emoji = '🏸';
    if (sport.toLowerCase() == 'tennis') emoji = '🎾';
    if (sport.toLowerCase() == 'pickleball') emoji = '🏓';
    if (sport.toLowerCase() == 'table_tennis') emoji = '🏓';
    return "$emoji $label";
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolvedBannerUrl = _resolveImageUrl(widget.tournament.bannerUrl);
    final hasBanner = resolvedBannerUrl.isNotEmpty;
    final categoryChips = _getCategoryChips(widget.tournament);

    // Gom gọn khi giải đấu có nhiều hình thức/nội dung thi đấu
    final displayChips = categoryChips.length > 2
        ? [...categoryChips.take(1), '+${categoryChips.length - 1} nội dung']
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
                            errorBuilder: (_, __, ___) => Container(
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
                                child: SvgPicture.asset(
                                  "assets/images/sporto_v1_with_text.svg",
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
                              child: SvgPicture.asset(
                                "assets/images/sporto_v1_with_text.svg",
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
                                        'KHÔNG TÍNH ELO',
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
                                      child: const Text(
                                        "XẾP HẠNG ELO",
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
                                        ? "Miễn phí"
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
                                            ? "Loại trực tiếp"
                                            : "Vòng tròn",
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
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              padding: const EdgeInsets.all(8),
                              child: SvgPicture.asset(
                                "assets/images/sporto_v1_with_text.svg",
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              "assets/images/sporto_v1_with_text.svg",
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
