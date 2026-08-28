import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';

class SportoLiveMatchCarousel extends StatelessWidget {
  final List<MatchModel> liveMatches;
  final List<Tournament> tournaments;
  final VoidCallback? onSeeMore;

  const SportoLiveMatchCarousel({
    super.key,
    required this.liveMatches,
    required this.tournaments,
    this.onSeeMore,
  });

  Tournament? _getTournament(String? tournamentId) {
    if (tournamentId == null) return null;
    return tournaments.where((item) => item.id == tournamentId).firstOrNull;
  }

  String _getTournamentName(MatchModel match) {
    return _getTournament(match.tournamentId)?.name ??
        match.tournamentName ??
        'Giải đấu';
  }

  String _resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final firstUrl = url.split(',').first.trim();
    if (firstUrl.startsWith('http')) return firstUrl;

    final apiBase =
        dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
    return '${apiBase.replaceAll('/api/v1', '')}$firstUrl';
  }

  Widget _buildLogo(String? imageUrl) {
    Widget fallback() => Padding(
      padding: const EdgeInsets.all(4),
      child: SvgPicture.asset(AppConstants.logoIconSvg, fit: BoxFit.contain),
    );

    final resolvedUrl = _resolveImageUrl(imageUrl);
    if (resolvedUrl.isEmpty) return fallback();
    return Image.network(
      resolvedUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback(),
    );
  }

  String _getTeamAbbr(String? name) {
    if (name == null || name.trim().isEmpty) return 'ĐỘI';
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, words[0].length.clamp(0, 3)).toUpperCase();
    }
    return words
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(3)
        .join()
        .toUpperCase();
  }

  /// Nếu tên từ 3 từ trở lên thì chỉ hiển thị 2 từ cuối cùng
  String _formatDisplayName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Đội';
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length > 2) {
      return words.sublist(words.length - 2).join(' ');
    }
    return trimmed;
  }

  Widget _buildTeamAvatar({
    required BuildContext context,
    required String? logoUrl,
    required String teamName,
    required String teamAbbr,
  }) {
    final resolvedUrl = _resolveImageUrl(logoUrl);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF1F5F9),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: resolvedUrl.isNotEmpty
          ? Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              width: 52,
              height: 52,
              errorBuilder: (_, _, _) => Text(
                teamAbbr,
                style: const TextStyle(
                  color: AppTheme.webPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : Text(
              teamAbbr,
              style: const TextStyle(
                color: AppTheme.webPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (liveMatches.isEmpty) {
      return const SizedBox.shrink();
    }

    final itemCount = liveMatches.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header Row ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const _PulsingLiveDot(size: 8),
                  const SizedBox(width: 8),
                  Text(
                    'Đang diễn ra',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSeeMore != null ? onSeeMore!() : context.push('/live');
                },
                child: const Text(
                  'Xem thêm',
                  style: TextStyle(
                    color: AppTheme.webSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // ─── Live Match Cards Carousel (Borderless / White card with beautiful subtle border) ───
        SizedBox(
          height: 150,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final match = liveMatches[index];
              final tournament = _getTournament(match.tournamentId);
              final tournamentName = _getTournamentName(match);
              final rawTeam1Name = match.team1Name.isNotEmpty
                  ? match.team1Name
                  : 'Đội 1';
              final rawTeam2Name = match.team2Name.isNotEmpty
                  ? match.team2Name
                  : 'Đội 2';
              final displayTeam1Name = _formatDisplayName(rawTeam1Name);
              final displayTeam2Name = _formatDisplayName(rawTeam2Name);
              final score1 = match.score1;
              final score2 = match.score2;
              final team1Abbr = _getTeamAbbr(rawTeam1Name);
              final team2Abbr = _getTeamAbbr(rawTeam2Name);

              final team1Avatar = match.team1LogoUrl ??
                  (match.team1MemberInfos.isNotEmpty
                      ? match.team1MemberInfos.first.avatarUrl
                      : null);
              final team2Avatar = match.team2LogoUrl ??
                  (match.team2MemberInfos.isNotEmpty
                      ? match.team2MemberInfos.first.avatarUrl
                      : null);

              return _buildCard(
                context: context,
                title: tournamentName,
                team1Abbr: team1Abbr,
                team1Name: displayTeam1Name,
                team1LogoUrl: team1Avatar,
                team2Abbr: team2Abbr,
                team2Name: displayTeam2Name,
                team2LogoUrl: team2Avatar,
                scoreText: '$score1 - $score2',
                logoUrl: tournament?.logoUrl ?? tournament?.bannerUrl,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (match.tournamentId != null) {
                    context.push(
                      '/tournaments/${match.tournamentId}/matches/${match.id}',
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String team1Abbr,
    required String team1Name,
    String? team1LogoUrl,
    required String team2Abbr,
    required String team2Name,
    String? team2LogoUrl,
    required String scoreText,
    String? logoUrl,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: Tournament Name + Chấm Live đỏ ẩn hiện từ từ (Bỏ nút chia sẻ & bỏ chữ LIVE)
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildLogo(logoUrl),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Chấm Live đỏ ẩn hiện mượt mà
                    const _PulsingLiveDot(size: 8),
                  ],
                ),

                // Middle: Teams với Avatar tròn to đẹp & Tỷ số rõ ràng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Team 1 (hiển thị 2 từ cuối nếu tên từ 3 từ trở lên)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTeamAvatar(
                            context: context,
                            logoUrl: team1LogoUrl,
                            teamName: team1Name,
                            teamAbbr: team1Abbr,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            team1Name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tỷ số trận đấu lớn & rõ ràng
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        scoreText,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: scoreText == 'LIVE' ? 20 : 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    // Team 2 (hiển thị 2 từ cuối nếu tên từ 3 từ trở lên)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTeamAvatar(
                            context: context,
                            logoUrl: team2LogoUrl,
                            teamName: team2Name,
                            teamAbbr: team2Abbr,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            team2Name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chấm Live đỏ hiệu ứng thở (ẩn hiện từ từ mượt mà)
class _PulsingLiveDot extends StatefulWidget {
  final double size;
  const _PulsingLiveDot({this.size = 8.0});

  @override
  State<_PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<_PulsingLiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.5),
              blurRadius: 5,
              spreadRadius: 1.2,
            ),
          ],
        ),
      ),
    );
  }
}
