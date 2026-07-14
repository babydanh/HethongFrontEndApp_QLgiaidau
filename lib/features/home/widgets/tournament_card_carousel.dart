import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';

class TournamentCardCarousel extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const TournamentCardCarousel({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  String _getFormatLabel(String matchType, String? genderRestriction) {
    final mt = matchType.toUpperCase();
    final gr = genderRestriction?.toUpperCase() ?? '';
    if (mt == 'SINGLES') {
      return gr == 'FEMALE' ? 'Đơn Nữ' : 'Đơn Nam';
    }
    if (mt == 'DOUBLES') {
      return gr == 'FEMALE' ? 'Đôi Nữ' : 'Đôi Nam';
    }
    if (mt == 'MIXED_DOUBLES' || mt == 'MIXED' || gr == 'MIXED') {
      return 'Đôi Nam Nữ';
    }
    return mt == 'DOUBLES' ? 'Đôi' : mt == 'SINGLES' ? 'Đơn' : 'Đôi Nam Nữ';
  }

  List<String> _getCategoryChips(Tournament t) {
    final List<String> chips = [];
    if (t.divisions.isNotEmpty) {
      for (var div in t.divisions) {
        if (div.name.trim() == t.name.trim()) continue;
        
        final label = _getFormatLabel(div.matchType, div.genderRestriction);
        final regCount = div.participantCount;
        final maxCount = div.maxParticipants != null ? "${div.maxParticipants}" : "-";
        
        chips.add("$label ($regCount/$maxCount)");
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
      final sportNameLower = (AppConstants.sportNames[t.sport] ?? '').toLowerCase();
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
        if (t.format == AppConstants.formatDoubles || t.maxPlayersPerTeam == 2) {
          chips.add("Đôi");
        } else {
          chips.add("Đơn");
        }
      }
    }
    return chips.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sportLabel = (AppConstants.sportNames[tournament.sport] ?? tournament.sport).toUpperCase();
    final normalizedStatus = StatusHelper.normalizeTournamentStatus(tournament.status);
    String statusText = "ĐANG ĐĂNG KÝ";
    Color statusBg = const Color(0xFF2563EB);
    if (StatusHelper.isTournamentInProgress(normalizedStatus)) {
      statusText = "ĐANG DIỄN RA";
      statusBg = const Color(0xFFEF4444);
    } else if (StatusHelper.isTournamentCompleted(normalizedStatus)) {
      statusText = "ĐÃ KẾT THÚC";
      statusBg = Colors.grey.shade600;
    } else if (StatusHelper.isTournamentRegistration(normalizedStatus)) {
      statusText = "ĐANG ĐĂNG KÝ";
      statusBg = const Color(0xFF2563EB);
    }

    final start = tournament.startDate ?? tournament.createdAt;
    final end = tournament.endDate ?? start.add(const Duration(days: 7));

    String formatDayMonth(DateTime dt) {
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}";
    }

    final startDateStr = formatDayMonth(start);
    final endDateStr = formatDayMonth(end);
    final categoryChips = _getCategoryChips(tournament);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 2.0,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900,
                        image: tournament.bannerUrl != null && tournament.bannerUrl!.isNotEmpty
                            ? DecorationImage(image: NetworkImage(tournament.bannerUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: tournament.bannerUrl == null || tournament.bannerUrl!.isEmpty
                          ? Center(
                              child: Image.asset(
                                "assets/images/vndc_sport.png",
                                width: 120,
                                fit: BoxFit.contain,
                                color: Colors.white.withValues(alpha: 0.85),
                                colorBlendMode: BlendMode.srcIn,
                              ),
                            )
                          : null,
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sportLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament.name.isNotEmpty ? tournament.name : "(Chưa có tên)",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (categoryChips.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: categoryChips.take(3).map((chipText) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.textPrimary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: colors.textPrimary.withValues(alpha: 0.15), width: 0.5),
                                  ),
                                  child: Text(
                                    chipText,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, color: colors.textMuted, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            "$startDateStr - $endDateStr",
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.group_rounded, color: colors.textMuted, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "${tournament.maxTeams} Đội",
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.account_tree_rounded, color: colors.textMuted, size: 13),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              AppConstants.bracketTypeNames[tournament.bracketType] ?? tournament.bracketType,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
