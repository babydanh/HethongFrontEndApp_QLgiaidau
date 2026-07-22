import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
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
  ConsumerState<TournamentCardWithBanner> createState() => _TournamentCardWithBannerState();
}

class _TournamentCardWithBannerState extends ConsumerState<TournamentCardWithBanner> {
  bool _isFollowLoading = false;

  Future<void> _toggleFollow(BuildContext context) async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      if (context.mounted) {
        context.go('/login');
      }
      return;
    }

    if (_isFollowLoading) return;

    final repo = ref.read(tournamentRepositoryProvider);
    final followedAsync = ref.read(followedTournamentsProvider);
    final currentlyFollowing = followedAsync.maybeWhen(
      data: (items) => items.any((t) => t.id == widget.tournament.id),
      orElse: () => false,
    );

    setState(() => _isFollowLoading = true);
    try {
      if (currentlyFollowing) {
        await repo.unfollowTournament(widget.tournament.id);
      } else {
        await repo.followTournament(widget.tournament.id);
      }
      ref.invalidate(followedTournamentsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentlyFollowing ? 'Đã bỏ theo dõi giải đấu' : 'Đã theo dõi giải đấu',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật theo dõi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isFollowLoading = false);
      }
    }
  }

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
      
      // Safely check gender from divisions if available
      final divGender = t.divisions.isNotEmpty ? (t.divisions.first.genderRestriction ?? '').toLowerCase() : '';

      // Check Female
      if (divGender == 'female' || nameLower.contains("đơn nữ") || descLower.contains("đơn nữ")) {
        chips.add("Đơn Nữ");
      } else if (divGender == 'female' || nameLower.contains("đôi nữ") || descLower.contains("đôi nữ")) {
        chips.add("Đôi Nữ");
      }
      // Check Mixed
      else if (divGender == 'mixed' || nameLower.contains("đôi nam nữ") || descLower.contains("đôi nam nữ") || nameLower.contains("nam nữ")) {
        chips.add("Đôi Nam Nữ");
      }
      // Check Male
      else if (nameLower.contains("đơn nam") || descLower.contains("đơn nam")) {
        chips.add("Đơn Nam");
      } else if (nameLower.contains("đôi nam") || descLower.contains("đôi nam")) {
        chips.add("Đôi Nam");
      }
      // Generic Singles / Doubles
      else if (nameLower.contains("đôi") || descLower.contains("đôi") || t.format == "doubles" || t.maxPlayersPerTeam == 2) {
        chips.add(divGender == 'female' ? "Đôi Nữ" : (divGender == 'mixed' ? "Đôi Nam Nữ" : "Đôi Nam"));
      } else if (nameLower.contains("đơn") || descLower.contains("đơn") || t.format == "singles" || t.maxPlayersPerTeam == 1) {
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
    final resolvedBannerUrl = _resolveImageUrl(widget.tournament.bannerUrl);
    final hasBanner = resolvedBannerUrl.isNotEmpty;
    final categoryChips = _getCategoryChips(widget.tournament);
    final followedAsync = ref.watch(followedTournamentsProvider);
    final isFollowing = followedAsync.maybeWhen(
      data: (items) => items.any((t) => t.id == widget.tournament.id),
      orElse: () => false,
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border.withValues(alpha: 0.7), width: 1),
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
                topLeft: Radius.circular(7.5),
                topRight: Radius.circular(7.5),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 170,
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
                            child: SvgPicture.asset(
                              "assets/images/vndcsport.svg",
                              width: 140,
                              fit: BoxFit.contain,
                            ),
                          )
                        : null,
                  ),
                  // Status badge top-left
                  Positioned(
                    top: 10,
                    left: 10,
                    child: StatusBadge(statusKey: widget.tournament.status),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Date Block
                  _buildDateBlock(context, colors),
                  
                  // Vertical divider
                  Container(
                    width: 1,
                    height: 48,
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
                              _getSportEmojiAndLabel(widget.tournament.sport),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: colors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (widget.tournament.isRanked == true) ...[
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
                        const SizedBox(height: 3),
                        // Row 2: Title
                        Text(
                          widget.tournament.name,
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Row 3: Fee & Format/Division Chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              widget.tournament.entryFee == null || widget.tournament.entryFee == 0
                                  ? "0 đ"
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
                            if (categoryChips.isNotEmpty)
                              ...categoryChips.map((chipText) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  chipText,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ))
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.tournament.format == "single_elimination"
                                      ? "Loại trực tiếp"
                                      : "Vòng tròn",
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
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
