import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:share_plus/share_plus.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LiveTournamentWithMatchesCard extends ConsumerStatefulWidget {
  final Tournament tournament;

  const LiveTournamentWithMatchesCard({
    super.key,
    required this.tournament,
  });

  @override
  ConsumerState<LiveTournamentWithMatchesCard> createState() => _LiveTournamentWithMatchesCardState();
}

class _LiveTournamentWithMatchesCardState extends ConsumerState<LiveTournamentWithMatchesCard> {
  // Trạng thái lưu trữ ID của trận đấu + ID đội đang được mở rộng thành viên
  String? _expandedKey;
  final Map<String, int> _cheerCounts = {};
  int _currentPage = 1;

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

  String _getStatusText(String status) {
    switch (status) {
      case 'in_progress':
        return 'Đang diễn ra';
      case 'completed':
        return 'Đã kết thúc';
      case 'upcoming':
      case 'registration':
        return 'Sắp diễn ra';
      default:
        return 'Giải đấu';
    }
  }

  String _getSportName(String sport) {
    switch (sport.toLowerCase()) {
      case 'badminton':
        return 'Cầu lông';
      case 'tennis':
        return 'Quần vợt';
      case 'pickleball':
        return 'Pickleball';
      case 'table_tennis':
        return 'Bóng bàn';
      default:
        return sport;
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesProvider(widget.tournament.id));
    final teamsAsync = ref.watch(teamsProvider(widget.tournament.id));
    
    final resolvedLogoUrl = _resolveImageUrl(widget.tournament.logoUrl);
    final dateStr = widget.tournament.startDate != null
        ? DateFormat('dd/MM/yyyy').format(widget.tournament.startDate!)
        : '';

    final teams = teamsAsync.value ?? [];

    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tournament Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular Logo
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
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
                              padding: const EdgeInsets.all(6),
                              child: SvgPicture.asset('assets/logos/dark_logo.svg'),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(6),
                            child: SvgPicture.asset('assets/logos/dark_logo.svg'),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tournament.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.tournament.isRanked ? "Xếp hạng ELO" : "Giải đấu giao lưu",
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
          
          // Matches List
          matchesAsync.when(
            data: (matches) {
              final validMatches = matches.where((m) {
                final t1 = m.team1Name.trim().toUpperCase();
                final t2 = m.team2Name.trim().toUpperCase();
                // Bỏ qua trận đấu nếu cả 2 bên đều hoàn toàn rỗng hoặc đều là TBD
                final isT1Tbd = t1.isEmpty || t1 == 'TBD' || t1 == 'BYE';
                final isT2Tbd = t2.isEmpty || t2 == 'TBD' || t2 == 'BYE';
                return !(isT1Tbd && isT2Tbd);
              }).toList();

              final liveMatches = validMatches.where((m) => m.isLive).toList();
              final completedMatches = validMatches.where((m) => m.isCompleted).toList();
              final scheduledMatches = validMatches.where((m) => m.isScheduled).toList();

              List<MatchModel> displayMatches = [];
              displayMatches.addAll(liveMatches);
              displayMatches.addAll(scheduledMatches);
              displayMatches.addAll(completedMatches);

              // Find champion
              String? championName;
              if (StatusHelper.isTournamentCompleted(widget.tournament.status)) {
                MatchModel? finalMatch;
                for (final m in completedMatches) {
                  if (finalMatch == null || 
                      m.round > finalMatch.round || 
                      (m.round == finalMatch.round && m.matchNumber > finalMatch.matchNumber)) {
                    finalMatch = m;
                  }
                }
                if (finalMatch != null) {
                  if (finalMatch.winnerId == finalMatch.team1Id) {
                    championName = finalMatch.team1Name;
                  } else if (finalMatch.winnerId == finalMatch.team2Id) {
                    championName = finalMatch.team2Name;
                  }
                }
              }

              if (displayMatches.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Chưa có trận đấu',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              final totalPages = (displayMatches.length / 4).ceil();
              final currentPage = _currentPage.clamp(1, totalPages > 0 ? totalPages : 1);
              final startIndex = (currentPage - 1) * 4;
              final paginatedMatches = displayMatches.skip(startIndex).take(4).toList();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: paginatedMatches.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final match = paginatedMatches[index];
                        return _buildMatchCard(context, match, teams);
                      },
                    ),
                    if (totalPages > 1) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: currentPage > 1
                                ? () => setState(() => _currentPage--)
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: currentPage > 1
                                    ? colors.bgSurface
                                    : colors.bgSurface.withOpacity(0.4),
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.border),
                              ),
                              child: Icon(
                                Icons.chevron_left_rounded,
                                size: 20,
                                color: currentPage > 1
                                    ? colors.textPrimary
                                    : colors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$currentPage / $totalPages',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: currentPage < totalPages
                                ? () => setState(() => _currentPage++)
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: currentPage < totalPages
                                    ? colors.bgSurface
                                    : colors.bgSurface.withOpacity(0.4),
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.border),
                              ),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: currentPage < totalPages
                                    ? colors.textPrimary
                                    : colors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    
                    // Champion banner
                    if (championName != null && championName.isNotEmpty && championName != 'TBD') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'NHÀ VÔ ĐỊCH: $championName',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, st) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Lỗi khi tải trận đấu: $e'),
            ),
          ),

          // Bottom Button
          Container(
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: InkWell(
              onTap: () => context.push('/intro/${widget.tournament.id}'),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Xem chi tiết giải đấu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16, color: colors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, MatchModel match, List<Team> teams) {
    final statusText = match.isLive
        ? 'ĐANG DIỄN RA • VÒNG ${match.round}'
        : match.isCompleted
            ? 'ĐÃ HOÀN THÀNH • VÒNG ${match.round}'
            : 'SẮP DIỄN RA • VÒNG ${match.round}';
    final bracketText = match.stageName ?? (match.bracketPosition.bracket == 'losers' ? 'NHÁNH THUA' : (widget.tournament.bracketType == 'round_robin' ? 'VÒNG BẢNG' : 'VÒNG KNOCKOUT'));
    final sportText = AppConstants.sportNames[match.sportKey ?? widget.tournament.sport] ?? match.sportKey ?? widget.tournament.sport;
    final courtText = match.court.isNotEmpty ? match.court : 'Chưa xếp sân';

    List<String> getInitials(String name) {
      final parts = name.split('-').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (parts.length >= 2) {
        return parts.map((p) => _getSingleInitials(p)).take(2).toList();
      }
      return [_getSingleInitials(name), _getSingleInitials(name)];
    }

    final t1Initials = getInitials(match.team1Name);
    final t2Initials = getInitials(match.team2Name);
    final isCheered = (_cheerCounts[match.id] ?? 0) > 0;
    final cheerCount = _cheerCounts[match.id] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF6FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052FF).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Badges Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Badge: SẮP DIỄN RA / ĐANG DIỄN RA
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: match.isLive
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      match.isLive ? Icons.sensors_rounded : Icons.access_time_rounded,
                      size: 13,
                      color: match.isLive ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: match.isLive ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Right Badge: VÒNG KNOCKOUT / VÒNG BẢNG
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 13,
                      color: Color(0xFF9333EA),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bracketText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9333EA),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Center Match Row (Avatars + Team Names vs Scores) ──
          Row(
            children: [
              // Left: Teams stacked vertically
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team 1
                    Row(
                      children: [
                        _DoubleAvatarWidget(
                          initial1: t1Initials.isNotEmpty ? t1Initials[0] : 'NM',
                          initial2: t1Initials.length > 1 ? t1Initials[1] : 'HD',
                          color: const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            match.team1Name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 20),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),

                    // Team 2
                    Row(
                      children: [
                        _DoubleAvatarWidget(
                          initial1: t2Initials.isNotEmpty ? t2Initials[0] : 'VQ',
                          initial2: t2Initials.length > 1 ? t2Initials[1] : 'KL',
                          color: const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            match.team2Name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: Score
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  '${match.score1} - ${match.score2}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // ── Sub-info Row: Sport & Court ──
          Row(
            children: [
              const Icon(Icons.sports_handball_rounded, size: 14, color: Color(0xFF475569)),
              const SizedBox(width: 4),
              Text(
                sportText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                courtText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Action Buttons Row (3 buttons) ──
          Row(
            children: [
              // Button 1: Cổ vũ
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _cheerCounts[match.id] = (_cheerCounts[match.id] ?? 0) + 1;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isCheered ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCheered ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCheered ? Icons.favorite : Icons.favorite_border,
                          size: 15,
                          color: isCheered ? const Color(0xFFDC2626) : const Color(0xFFE11D48),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cheerCount > 0 ? 'Cổ vũ ($cheerCount)' : 'Cổ vũ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isCheered ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Button 2: Chi tiết
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/intro/${widget.tournament.id}'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt_rounded, size: 15, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Text(
                          'Chi tiết',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Button 3: Chia sẻ
              Expanded(
                child: InkWell(
                  onTap: () {
                    final text = '${match.team1Name} vs ${match.team2Name} - ${widget.tournament.name}';
                    SharePlus.instance.share(ShareParams(text: text));
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.reply_rounded, size: 15, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Text(
                          'Chia sẻ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSingleInitials(String s) {
    final parts = s.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}'.toUpperCase();
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
    return SizedBox(
      width: 48,
      height: 28,
      child: Stack(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
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
                color: Colors.white,
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
