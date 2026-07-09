import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sport_pill.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/status_badge.dart';
import 'package:app_quanly_giaidau/core/widgets/countdown_timer.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';

class TournamentCardWithBanner extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;

  const TournamentCardWithBanner({
    super.key,
    required this.tournament,
    required this.onTap,
    this.margin,
  });

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

  List<String> _getCategoryChips(Tournament t) {
    final List<String> chips = [];
    if (t.divisions.isNotEmpty) {
      for (var divName in t.divisions) {
        if (divName.trim() == t.name.trim()) continue;
        final divLower = divName.toLowerCase();
        if (divLower.contains("đơn nam")) {
          chips.add("Đơn Nam");
        } else if (divLower.contains("đơn nữ")) {
          chips.add("Đơn Nữ");
        } else if (divLower.contains("đôi nam nữ") || divLower.contains("nam nữ")) {
          chips.add("Đôi Nam Nữ");
        } else if (divLower.contains("đôi nam")) {
          chips.add("Đôi Nam");
        } else if (divLower.contains("đôi nữ")) {
          chips.add("Đôi Nữ");
        } else if (divLower.contains("đồng đội")) {
          chips.add("Đồng đội");
        } else {
          // If the division name itself is generic, normalize it
          if (divLower == "thi đấu đơn" || divLower == "đơn") {
            chips.add("Đơn");
          } else if (divLower == "thi đấu đôi" || divLower == "đôi") {
            chips.add("Đôi");
          } else {
            chips.add(divName);
          }
        }
      }
    }
    if (chips.isEmpty) {
      final nameLower = t.name.toLowerCase();
      final descLower = t.description.toLowerCase();
      if (nameLower.contains("đơn nam") || descLower.contains("đơn nam")) {
        chips.add("Đơn Nam");
      }
      if (nameLower.contains("đơn nữ") || descLower.contains("đơn nữ")) {
        chips.add("Đơn Nữ");
      }
      if (nameLower.contains("đôi nam nữ") || descLower.contains("đôi nam nữ") || nameLower.contains("nam nữ") || descLower.contains("nam nữ")) {
        chips.add("Đôi Nam Nữ");
      }
      if ((nameLower.contains("đôi nam") || descLower.contains("đôi nam")) && !nameLower.contains("đôi nam nữ") && !descLower.contains("đôi nam nữ")) {
        chips.add("Đôi Nam");
      }
      if (nameLower.contains("đôi nữ") || descLower.contains("đôi nữ")) {
        chips.add("Đôi Nữ");
      }
      if (nameLower.contains("đồng đội") || descLower.contains("đồng đội")) {
        chips.add("Đồng đội");
      }
      if (nameLower.contains("đôi") || descLower.contains("đôi")) {
        if (!chips.any((c) => c.contains("Đôi"))) {
          chips.add("Đôi");
        }
      }
      if (nameLower.contains("đơn") || descLower.contains("đơn")) {
        if (!chips.any((c) => c.contains("Đơn"))) {
          chips.add("Đơn");
        }
      }
    }
    if (chips.isEmpty) {
      final sportNameLower = t.sport.toLowerCase() == 'badminton' ? 'cầu lông' : (t.sport.toLowerCase() == 'table_tennis' ? 'bóng bàn' : t.sport.toLowerCase());
      if (t.category != null && t.category!.isNotEmpty && 
          t.category!.toLowerCase() != t.sport.toLowerCase() &&
          t.category!.toLowerCase() != sportNameLower) {
        final catLower = t.category!.toLowerCase();
        if (catLower == "singles" || catLower == "đơn") {
          chips.add("Đơn");
        } else if (catLower == "doubles" || catLower == "đôi") {
          chips.add("Đôi");
        } else {
          chips.add(t.category!);
        }
      } else {
        if (t.format == "doubles" || t.maxPlayersPerTeam == 2) {
          chips.add("Đôi");
        } else {
          chips.add("Đơn");
        }
      }
    }
    return chips.toSet().toList();
  }

  Widget _buildDateBlock(BuildContext context, dynamic colors) {
    final start = tournament.startDate ?? tournament.createdAt;
    final end = tournament.endDate ?? start.add(const Duration(days: 7));
    final startDay = start.day.toString().padLeft(2, '0');
    final endDay = end.day.toString().padLeft(2, '0');
    final startMonth = start.month.toString().padLeft(2, '0');
    final endMonth = end.month.toString().padLeft(2, '0');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "$startDay - $endDay",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              startMonth,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              endMonth,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ],
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
    final resolvedBannerUrl = _resolveImageUrl(tournament.bannerUrl);
    final hasBanner = resolvedBannerUrl.isNotEmpty;
    final categoryChips = _getCategoryChips(tournament);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withOpacity(0.7), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      image: hasBanner
                          ? DecorationImage(
                              image: NetworkImage(resolvedBannerUrl),
                              fit: BoxFit.cover,
                             )
                          : null,
                      gradient: hasBanner
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade900,
                                Colors.indigo.shade900,
                              ],
                            ),
                    ),
                    child: !hasBanner
                        ? Center(
                            child: Image.asset(
                              "assets/images/vndc_sport.png",
                              width: 140,
                              fit: BoxFit.contain,
                              color: Colors.white.withValues(alpha: 0.8),
                              colorBlendMode: BlendMode.srcIn,
                            ),
                          )
                        : null,
                  ),
                  // Bookmark button top-right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.bookmark_border_rounded,
                          size: 18,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                  // Status badge top-left
                  Positioned(
                    top: 12,
                    left: 12,
                    child: StatusBadge(statusKey: tournament.status),
                  ),
                  // Location badge bottom-left
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Colors.rose),
                          const SizedBox(width: 4),
                          Text(
                            tournament.locationAddress != null && tournament.locationAddress!.isNotEmpty
                                ? (tournament.locationAddress!.split(',').last.trim().toUpperCase())
                                : 'CHƯA CẬP NHẬT',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Date Block
                  _buildDateBlock(context, colors),
                  
                  // Vertical divider
                  Container(
                    width: 1,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: colors.border.withOpacity(0.6),
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
                              _getSportEmojiAndLabel(tournament.sport),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: colors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (tournament.isRanked == true) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFFDE68A), width: 0.5),
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
                        const SizedBox(height: 5),
                        // Row 2: Title
                        Text(
                          tournament.name,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Row 3: Fee & Format/Division
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              tournament.entryFee == null || tournament.entryFee == 0
                                  ? "0 đ"
                                  : "${NumberFormat.decimalPattern().format(tournament.entryFee)} đ",
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981), // Emerald green
                              ),
                            ),
                            Text(
                              "•",
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textMuted,
                              ),
                            ),
                            Text(
                              "HÌNH THỨC:",
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: colors.textMuted,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9), // Slate 100
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                categoryChips.isNotEmpty
                                    ? categoryChips.first
                                    : (tournament.format == "single_elimination"
                                        ? "Loại trực tiếp"
                                        : "Vòng tròn"),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569), // Slate 600
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
      ),
    );
  }
}
