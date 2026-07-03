import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sport_pill.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/status_badge.dart';
import 'package:app_quanly_giaidau/core/widgets/countdown_timer.dart';

class TournamentCardWithBanner extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const TournamentCardWithBanner({
    super.key,
    required this.tournament,
    required this.onTap,
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
          chips.add(divName);
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
    }
    if (chips.isEmpty) {
      if (t.category != null && t.category!.isNotEmpty && t.category!.toLowerCase() != t.sport.toLowerCase()) {
        final catLower = t.category!.toLowerCase();
        if (catLower == "singles" || catLower == "đơn") {
          chips.add("Thi đấu đơn");
        } else if (catLower == "doubles" || catLower == "đôi") {
          chips.add("Thi đấu đôi");
        } else {
          chips.add(t.category!);
        }
      } else {
        if (t.maxPlayersPerTeam == 2) {
          chips.add("Thi đấu đôi");
        } else if (t.maxPlayersPerTeam == 1) {
          chips.add("Thi đấu đơn");
        }
      }
    }
    return chips.toSet().toList();
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border, width: 1.5),
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
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 140,
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
                  Positioned(
                    top: 12,
                    right: 12,
                    child: StatusBadge(statusKey: tournament.status),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SportPill(sportKey: tournament.sport),
                      ...categoryChips.map((chipText) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade100, width: 0.5),
                          ),
                          child: Text(
                            chipText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        );
                      }),
                      if (tournament.format.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.shade100, width: 0.5),
                          ),
                          child: Text(
                            tournament.format == "single_elimination"
                                ? "Loại trực tiếp"
                                : "Vòng tròn",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.group, size: 16, color: colors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        "${tournament.maxTeams} đội",
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (tournament.startDate != null && tournament.endDate != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today, size: 14, color: colors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          "${DateFormat("dd/MM/yyyy").format(tournament.startDate!)} - ${DateFormat("dd/MM/yyyy").format(tournament.endDate!)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (tournament.status == 'upcoming' && tournament.registrationStartDate != null) ...[
                        const SizedBox(width: 8),
                        CountdownTimer(targetDate: tournament.registrationStartDate!, compact: true),
                      ],
                    ],
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
