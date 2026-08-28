import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
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

  void _shareMatch(BuildContext context, MatchModel match) {
    final tournament = _getTournament(match.tournamentId);
    final tournamentId = match.tournamentId;
    if (tournamentId == null || tournamentId.isEmpty) return;

    AppShareModal.show(
      context: context,
      title: tournament?.name ?? match.tournamentName ?? 'Giải đấu',
      subtitle:
          '${match.team1Name} ${match.score1} - ${match.score2} ${match.team2Name}',
      webUrl: '${AppConstants.appDomain}/tournaments/$tournamentId',
      imageUrl: tournament?.bannerUrl ?? tournament?.logoUrl,
      badgeText: 'Đang diễn ra',
    );
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
      padding: const EdgeInsets.all(5),
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
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: AppTheme.webSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
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

        // ─── Live Match / Tournament Cards Carousel ───
        SizedBox(
          height: 195,
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
              final team1Name = match.team1Name.isNotEmpty
                  ? match.team1Name
                  : 'Đội 1';
              final team2Name = match.team2Name.isNotEmpty
                  ? match.team2Name
                  : 'Đội 2';
              final score1 = match.score1;
              final score2 = match.score2;
              final team1Abbr = _getTeamAbbr(team1Name);
              final team2Abbr = _getTeamAbbr(team2Name);

              return _buildCard(
                context: context,
                title: tournamentName,
                team1Abbr: team1Abbr,
                team1Name: team1Name,
                team2Abbr: team2Abbr,
                team2Name: team2Name,
                scoreText: '$score1 - $score2',
                logoUrl: tournament?.logoUrl ?? tournament?.bannerUrl,
                onShare:
                    match.tournamentId != null && match.tournamentId!.isNotEmpty
                    ? () => _shareMatch(context, match)
                    : null,
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
    required String team2Abbr,
    required String team2Name,
    required String scoreText,
    String? logoUrl,
    VoidCallback? onShare,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top: Tournament Name + Live Pill (Web Vibe)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: context.colors.bgSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.colors.border),
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
                  ],
                ),
              ),
              if (onShare != null)
                IconButton(
                  onPressed: onShare,
                  icon: Icon(
                    Icons.share_outlined,
                    color: context.colors.textSecondary,
                    size: 18,
                  ),
                  tooltip: 'Chia sẻ giải đấu',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.webSecondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      '•',
                      style: TextStyle(
                        color: AppTheme.webSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: AppTheme.webSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Middle: Teams & Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Team 1
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.webSecondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        team1Abbr,
                        style: const TextStyle(
                          color: AppTheme.webSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      team1Name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Score
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  scoreText,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: scoreText == 'LIVE' ? 20 : 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),

              // Team 2
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.webSecondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        team2Abbr,
                        style: const TextStyle(
                          color: AppTheme.webSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      team2Name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bottom: CTA Button with Web Navy
          Container(
            width: double.infinity,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.webPrimary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.webSecondary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: const Center(
                  child: Text(
                    'Chi tiết',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
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
