import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';

class LiveTournamentWithMatchesCard extends ConsumerStatefulWidget {
  final Tournament tournament;

  const LiveTournamentWithMatchesCard({
    super.key,
    required this.tournament,
  });

  @override
  ConsumerState<LiveTournamentWithMatchesCard> createState() =>
      _LiveTournamentWithMatchesCardState();
}

class _LiveTournamentWithMatchesCardState
    extends ConsumerState<LiveTournamentWithMatchesCard> {
  final Map<String, int> _cheerCounts = {};
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
    final matchesAsync = ref.watch(matchesProvider(widget.tournament.id));
    final teamsAsync = ref.watch(teamsProvider(widget.tournament.id));
    final resolvedLogoUrl = _resolveImageUrl(widget.tournament.logoUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    ),
                    child: ClipOval(
                      child: resolvedLogoUrl.isNotEmpty
                          ? Image.network(
                              resolvedLogoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SvgPicture.asset(
                                  "assets/images/vndcsport.svg",
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SvgPicture.asset(
                                "assets/images/vndcsport.svg",
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.tournament.isRanked ? "Xếp hạng ELO" : "Giải đấu giao lưu",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
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

          // ── Matches Content Area (Hiển thị tối đa 4 trận/trang) ──
          matchesAsync.when(
            data: (matches) {
              final validMatches = matches.where((m) {
                final t1 = m.team1Name.trim().toUpperCase();
                final t2 = m.team2Name.trim().toUpperCase();
                final isT1Tbd = t1.isEmpty || t1 == 'TBD' || t1 == 'BYE';
                final isT2Tbd = t2.isEmpty || t2 == 'TBD' || t2 == 'BYE';
                return !(isT1Tbd && isT2Tbd);
              }).toList();

              final displayMatches = validMatches.isNotEmpty
                  ? validMatches
                  : [
                      MatchModel(
                        id: 'match_${widget.tournament.id}',
                        round: 1,
                        matchNumber: 1,
                        team1Name: (teamsAsync.value?.isNotEmpty ?? false)
                            ? teamsAsync.value![0].name
                            : 'Nguyễn Minh Danh - Phạm Hải Dũng',
                        team2Name: ((teamsAsync.value?.length ?? 0) >= 2)
                            ? teamsAsync.value![1].name
                            : 'Vũ Quốc Phong - Đặng Khánh Linh',
                        score1: 0,
                        score2: 0,
                        status: widget.tournament.status,
                        bracketPosition: const BracketPosition(round: 1, position: 1),
                        updatedAt: DateTime.now(),
                        tournamentName: widget.tournament.name,
                        sportKey: widget.tournament.sport,
                        court: widget.tournament.locationAddress ?? 'Chưa xếp sân',
                      ),
                    ];

              // Calculate total pages (each page shows up to 4 matches)
              final totalPages = (displayMatches.length / _pageSize).ceil();
              final safePageIndex = _currentMatchIndex.clamp(0, totalPages - 1);
              final startIndex = safePageIndex * _pageSize;
              final endIndex = (startIndex + _pageSize).clamp(0, displayMatches.length);
              final currentPageMatches = displayMatches.sublist(startIndex, endIndex);

              return Column(
                children: [
                  // Render 4 matches of current page
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: currentPageMatches.map((match) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildMatchCard(context, match),
                        );
                      }).toList(),
                    ),
                  ),

                  // ── Pagination Controls & Dots Indicator (Chỉ hiển thị khi số trận > 4) ──
                  if (totalPages > 1) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: safePageIndex > 0
                                ? () => setState(() => _currentMatchIndex--)
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_left_rounded, size: 18, color: Color(0xFF475569)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(totalPages, (idx) {
                              final isSelected = idx == safePageIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: isSelected ? 16 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: safePageIndex < totalPages - 1
                                ? () => setState(() => _currentMatchIndex++)
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    const SizedBox(height: 6),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
              ),
            ),
            error: (e, st) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, MatchModel match) {
    final statusText = match.isLive
        ? 'ĐANG DIỄN RA • VÒNG ${match.round}'
        : match.isCompleted
            ? 'ĐÃ HOÀN THÀNH • VÒNG ${match.round}'
            : 'SẮP DIỄN RA • VÒNG ${match.round}';
    final bracketText = match.stageName ??
        (match.bracketPosition.bracket == 'losers'
            ? 'NHÁNH THUA'
            : (widget.tournament.bracketType == 'round_robin'
                ? 'VÒNG BẢNG'
                : 'VÒNG KNOCKOUT'));
    final sportText = AppConstants.sportNames[match.sportKey ?? widget.tournament.sport] ??
        match.sportKey ??
        widget.tournament.sport;
    final courtText = match.court.isNotEmpty ? match.court : 'Chưa xếp sân';

    List<String> getInitials(String name) {
      final parts = name.split('-').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF6FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052FF).withValues(alpha: 0.04),
            blurRadius: 12,
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

          const SizedBox(height: 14),

          // ── Team 1 Row ──
          GestureDetector(
            onTap: () => context.push('/intro/${widget.tournament.id}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _DoubleAvatarWidget(
                    initial1: t1Initials.isNotEmpty ? t1Initials[0] : 'NM',
                    initial2: t1Initials.length > 1 ? t1Initials[1] : '',
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
                  const SizedBox(width: 12),
                  Text(
                    '${match.score1}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Team 2 Row ──
          GestureDetector(
            onTap: () => context.push('/intro/${widget.tournament.id}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _DoubleAvatarWidget(
                    initial1: t2Initials.isNotEmpty ? t2Initials[0] : 'VQ',
                    initial2: t2Initials.length > 1 ? t2Initials[1] : '',
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
                  const SizedBox(width: 12),
                  Text(
                    '${match.score2}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
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

          // ── Action Buttons Row ──
          Row(
            children: [
              // Button 1: Cổ vũ (Gọi thật API backend POST /matches/:id/cheer)
              Expanded(
                child: InkWell(
                  onTap: () async {
                    setState(() {
                      _cheerCounts[match.id] = (_cheerCounts[match.id] ?? 0) + 1;
                    });
                    try {
                      final dio = ref.read(dioClientProvider).dio;
                      await dio.post('/matches/${match.id}/cheer');
                    } catch (_) {}
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
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

              // Button 2: Chi tiết (Mở trực tiếp trang Live Match Detail /live/:matchId)
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/live/${match.id}'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
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

              // Button 3: Nút Chia sẻ CHỈ CÓ ICON (Không có chữ "Chia sẻ")
              InkWell(
                onTap: () {
                  final text = '${match.team1Name} vs ${match.team2Name} - ${widget.tournament.name}';
                  SharePlus.instance.share(ShareParams(text: text));
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 42,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Center(
                    child: Icon(Icons.share_rounded, size: 16, color: Color(0xFF0284C7)),
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
    if (initial2.isEmpty || initial2 == '?') {
      return Container(
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
