import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sport_pill.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/status_badge.dart';

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

  String _getRoundName(int round) {
    if (round == 1) return 'Vòng 1';
    if (round == 2) return 'Vòng Tứ Kết';
    if (round == 3) return 'Trận Bán Kết';
    if (round >= 4) return 'Trận Chung Kết';
    return 'Vòng $round';
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

  // Tạo số điểm ELO giả lập dựa vào tên đội
  int _getMockTeamElo(String name) {
    int sum = 0;
    for (int i = 0; i < name.length; i++) {
      sum += name.codeUnitAt(i);
    }
    return 1100 + (sum % 400); // Trả về ELO khoảng 1100 - 1500
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

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
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
                          color: Colors.grey.shade500,
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

              final liveMatches = validMatches.where((m) => m.status == 'live').toList();
              final completedMatches = validMatches.where((m) => m.status == 'completed').toList();
              final scheduledMatches = validMatches.where((m) => m.status == 'scheduled').toList();

              List<MatchModel> displayMatches = [];
              displayMatches.addAll(liveMatches);
              displayMatches.addAll(completedMatches);
              displayMatches.addAll(scheduledMatches);
              displayMatches = displayMatches.take(2).toList();

              // Find champion
              String? championName;
              if (widget.tournament.status == 'completed' || widget.tournament.status == 'finished') {
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
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Chưa có trận đấu',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
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
                      itemCount: displayMatches.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final match = displayMatches[index];
                        return _buildMatchCard(context, match, teams);
                      },
                    ),
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
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: InkWell(
              onTap: () => context.go('/intro/${widget.tournament.id}'),
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
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade700),
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

    String shortenedTourName = widget.tournament.name.length > 15
        ? '${widget.tournament.name.substring(0, 12)}...'
        : widget.tournament.name;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header of Match
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  (match.status == 'live'
                          ? 'Đang diễn ra'
                          : match.status == 'completed'
                              ? 'Đã kết thúc'
                              : 'Sắp diễn ra')
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: match.status == 'live' ? Colors.red : Colors.grey.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_getRoundName(match.round)}${match.court.isNotEmpty ? ' · ${match.court}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
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
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(match.startedAt!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          // Footer Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                if (isLive) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.front_hand_outlined, size: 14, color: Colors.black54),
                      label: const Text(
                        'High Five',
                        style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/intro/${widget.tournament.id}'),
                      icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        'Live',
                        style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/intro/${widget.tournament.id}'),
                      icon: Icon(Icons.analytics_outlined, size: 14, color: Colors.blue.shade700),
                      label: Text(
                        'Chi tiết trận đấu',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue.shade100),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: Colors.blue.shade50.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade200),
                    padding: const EdgeInsets.all(10),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.share_outlined, size: 14, color: Colors.black54),
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
    final nameColor = isLoser ? Colors.grey.shade400 : Colors.black87;
    final fontWeight = isWinner ? FontWeight.w800 : FontWeight.w600;
    
    final displayNames = name.split(RegExp(r'[-–\n]'));
    final teamKey = '${matchId}_${name}';
    final isExpanded = _expandedKey == teamKey;

    final team = teams.firstWhere(
      (t) => t.name.trim().toLowerCase() == name.trim().toLowerCase(),
      orElse: () => Team(id: '', name: name, createdAt: DateTime.now()),
    );

    final avgElo = _getMockTeamElo(name);

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
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            displayNames[0].trim().isNotEmpty ? displayNames[0].trim()[0].toUpperCase() : 'T',
                            style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (displayNames.length > 1 && displayNames[1].trim().isNotEmpty)
                        Positioned(
                          left: 14,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              displayNames[1].trim()[0].toUpperCase(),
                              style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
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
                                color: Colors.grey.shade800,
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
                          color: isLoser ? Colors.grey.shade400 : Colors.black87,
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
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_outline_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Thành viên đội (${team.members.length}):',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
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
                      color: Colors.grey.shade500,
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
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            '$memberElo ELO',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
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
