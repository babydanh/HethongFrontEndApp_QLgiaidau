import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';

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
  int _visibleMatchesLimit = 4;

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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border, width: 1.5),
                  ),
                  child: ClipOval(
                    child: resolvedLogoUrl.isNotEmpty
                        ? Image.network(
                            resolvedLogoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                          )
                        : const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
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
                        '${_getStatusText(widget.tournament.status)} ${dateStr.isNotEmpty ? '· $dateStr' : ''}',
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
                final t1 = m.team1Name.trim();
                final t2 = m.team2Name.trim();
                return t1.isNotEmpty && t1 != 'TBD' && t2.isNotEmpty && t2 != 'TBD';
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

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayMatches.length > _visibleMatchesLimit ? _visibleMatchesLimit : displayMatches.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final match = displayMatches[index];
                        return _buildMatchCard(context, match, teams);
                      },
                    ),
                    if (displayMatches.length > _visibleMatchesLimit) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _visibleMatchesLimit += 6;
                            });
                          },
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary, size: 20),
                          label: Text(
                            'Xem thêm (${displayMatches.length - _visibleMatchesLimit} trận)',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
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
    final isCompleted = match.status == 'completed';
    final isLive = match.status == 'live';

    final isT1Winner = isCompleted && match.winnerId == match.team1Id;
    final isT2Winner = isCompleted && match.winnerId == match.team2Id;

    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header of Match
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: match.isLive
                        ? const Color(0xFFEF4444)
                        : match.isCompleted
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${match.isLive ? 'Trực tiếp' : match.isCompleted ? 'Đã kết thúc' : 'Sắp diễn ra'} • Vòng ${match.round}'
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: match.isLive
                        ? const Color(0xFFEF4444)
                        : match.isCompleted
                            ? const Color(0xFF10B981)
                            : colors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.textPrimary.withValues(alpha: 0.1), width: 0.5),
                  ),
                  child: Text(
                    (widget.tournament.bracketType == 'round_robin' ? 'VÒNG BẢNG' : 'VÒNG KNOCKOUT'),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: colors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body of Match (Vertical list of Teams with scores)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                // Team 1 Row
                _buildTeamRow(
                  context: context,
                  matchId: match.id,
                  name: match.team1Name,
                  score: match.score1,
                  sets: match.sets,
                  isTeam1: true,
                  isWinner: isT1Winner,
                  isLoser: isCompleted && !isT1Winner,
                  isLive: isLive,
                  teams: teams,
                ),
                const SizedBox(height: 12),
                // Team 2 Row
                _buildTeamRow(
                  context: context,
                  matchId: match.id,
                  name: match.team2Name,
                  score: match.score2,
                  sets: match.sets,
                  isTeam1: false,
                  isWinner: isT2Winner,
                  isLoser: isCompleted && !isT2Winner,
                  isLive: isLive,
                  teams: teams,
                ),
              ],
            ),
          ),

          // Sport & Court detail row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.sports_tennis_rounded, size: 14, color: colors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Môn: ',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                Text(
                  _getSportName(widget.tournament.sport),
                  style: TextStyle(fontSize: 12, color: colors.textPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on_rounded, size: 14, color: colors.textMuted),
                const SizedBox(width: 4),
                Text(
                  match.court.isNotEmpty ? match.court : 'Chưa xếp sân',
                  style: TextStyle(fontSize: 12, color: colors.textMuted, fontStyle: match.court.isNotEmpty ? null : FontStyle.italic),
                ),
              ],
            ),
          ),
          
          // Live status detail bar
          if (isLive) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                  const Spacer(),
                  if (match.startedAt != null) ...[
                    Icon(Icons.access_time_rounded, size: 14, color: colors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(match.startedAt!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          Divider(height: 1, thickness: 1, color: colors.border),

          // Footer Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _cheerCounts[match.id] = (_cheerCounts[match.id] ?? 0) + 1;
                      });
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cổ vũ thành công! ❤️👏'),
                          duration: Duration(milliseconds: 500),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite, size: 14, color: Color(0xFFE11D48)),
                    label: Text(
                      'Cổ vũ (${_cheerCounts[match.id] ?? 0})',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFE11D48), fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE11D48)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: const Color(0xFFE11D48).withValues(alpha: 0.05),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/live/${match.id}'),
                    icon: Icon(
                      isLive ? Icons.play_arrow_rounded : Icons.analytics_outlined,
                      size: 16,
                      color: isLive ? Colors.white : colors.textPrimary,
                    ),
                    label: Text(
                      isLive ? 'Live' : 'Chi tiết trận đấu',
                      style: TextStyle(
                        fontSize: 12,
                        color: isLive ? Colors.white : colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLive ? Colors.red : colors.bgCard,
                      foregroundColor: isLive ? Colors.white : colors.textPrimary,
                      side: isLive ? null : BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.all(10),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: colors.bgCard,
                  ),
                  child: Icon(Icons.share_outlined, size: 14, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow({
    required BuildContext context,
    required String matchId,
    required String name,
    required int score,
    required List<SetScore> sets,
    required bool isTeam1,
    required bool isWinner,
    required bool isLoser,
    required bool isLive,
    required List<Team> teams,
  }) {
    final colors = context.colors;
    final nameColor = isLoser ? colors.textMuted : colors.textPrimary;
    final fontWeight = isWinner ? FontWeight.w800 : FontWeight.w600;
    
    final displayNames = name.split(RegExp(r'[-–\n]'));
    final teamKey = '${matchId}_$name';
    final isExpanded = _expandedKey == teamKey;

    final team = teams.firstWhere(
      (t) => t.name.trim().toLowerCase() == name.trim().toLowerCase(),
      orElse: () => Team(id: '', name: name, createdAt: DateTime.now()),
    );

    final avgElo = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hàng hiển thị chính (Có thể click để mở rộng)
        InkWell(
          onTap: () {
            setState(() {
              if (_expandedKey == teamKey) {
                _expandedKey = null;
              } else {
                _expandedKey = teamKey;
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                // Overlapping Circle Avatars
                SizedBox(
                  width: 38,
                  height: 24,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.green.withValues(alpha: 0.15),
                          child: Text(
                            displayNames[0].trim().isNotEmpty ? displayNames[0].trim()[0].toUpperCase() : 'T',
                            style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (displayNames.length > 1 && displayNames[1].trim().isNotEmpty)
                        Positioned(
                          left: 14,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.blue.withValues(alpha: 0.15),
                            child: Text(
                              displayNames[1].trim()[0].toUpperCase(),
                              style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Team/Player Name
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: fontWeight,
                      color: nameColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Scores display area
                if (isLive) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...sets.map((set) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              isTeam1 ? set.score1.toString() : set.score2.toString(),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                          )),
                      Text(
                        score.toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isWinner) ...[
                        const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        score.toString(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isLoser ? colors.textMuted : colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Phần xổ xuống hiển thị danh sách thành viên (Accordion)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(left: 54, top: 4, bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_outline_rounded, size: 14, color: colors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Thành viên đội (${team.members.length}):',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (team.members.isEmpty)
                  Text(
                    'Chưa cập nhật danh sách thành viên.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: colors.textMuted,
                    ),
                  )
                else
                  ...team.members.map((member) {
                    final memberElo = avgElo - 20 + (member.hashCode % 41);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 12, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              member,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '$memberElo ELO',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
