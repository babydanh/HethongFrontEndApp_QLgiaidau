import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class _TeamDisplayData {
  final bool isDoubles;
  final String? avatar1;
  final String abbr1;
  final String? avatar2;
  final String abbr2;
  final String displayName;

  const _TeamDisplayData({
    required this.isDoubles,
    this.avatar1,
    required this.abbr1,
    this.avatar2,
    required this.abbr2,
    required this.displayName,
  });
}

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

  String _getTournamentName(MatchModel match, AppLocalizations l10n) {
    return _getTournament(match.tournamentId)?.name ??
        match.tournamentName ??
        l10n.matchTournament;
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
    if (name == null || name.trim().isEmpty) return 'T';
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
    if (trimmed.isEmpty) return '';
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length > 2) {
      return words.sublist(words.length - 2).join(' ');
    }
    return trimmed;
  }

  _TeamDisplayData _parseTeamData({
    required String rawName,
    required String? teamLogoUrl,
    required List<MatchMemberInfo> memberInfos,
    required String fallbackName,
  }) {
    final effectiveName = rawName.isNotEmpty ? rawName : fallbackName;

    if (memberInfos.length >= 2) {
      final m1 = memberInfos[0];
      final m2 = memberInfos[1];
      final name1 = _formatDisplayName(m1.fullName);
      final name2 = _formatDisplayName(m2.fullName);
      return _TeamDisplayData(
        isDoubles: true,
        avatar1: m1.avatarUrl ?? teamLogoUrl,
        abbr1: _getTeamAbbr(m1.fullName),
        avatar2: m2.avatarUrl,
        abbr2: _getTeamAbbr(m2.fullName),
        displayName: '$name1 / $name2',
      );
    }

    if (effectiveName.contains(' / ') ||
        effectiveName.contains(' - ') ||
        effectiveName.contains(' + ')) {
      final delimiter = effectiveName.contains(' / ')
          ? ' / '
          : (effectiveName.contains(' - ') ? ' - ' : ' + ');
      final parts = effectiveName.split(delimiter);
      if (parts.length >= 2) {
        final p1 = parts[0].trim();
        final p2 = parts[1].trim();
        return _TeamDisplayData(
          isDoubles: true,
          avatar1: teamLogoUrl,
          abbr1: _getTeamAbbr(p1),
          avatar2: null,
          abbr2: _getTeamAbbr(p2),
          displayName: '${_formatDisplayName(p1)} / ${_formatDisplayName(p2)}',
        );
      }
    }

    return _TeamDisplayData(
      isDoubles: false,
      avatar1: teamLogoUrl,
      abbr1: _getTeamAbbr(effectiveName),
      abbr2: '',
      displayName: _formatDisplayName(effectiveName),
    );
  }

  Widget _buildSingleAvatarCircle({
    required BuildContext context,
    required double size,
    required String? logoUrl,
    required String abbr,
    double fontSize = 13,
  }) {
    final colors = context.colors;
    final resolvedUrl = _resolveImageUrl(logoUrl);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.bgSurface,
        border: Border.all(
          color: colors.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: resolvedUrl.isNotEmpty
          ? Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (_, _, _) => Text(
                abbr,
                style: TextStyle(
                  color: AppTheme.webPrimary,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : Text(
              abbr,
              style: TextStyle(
                color: AppTheme.webPrimary,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }

  /// Avatar đội: Nếu đánh đôi thì Đội 1 là `Oo` (To bên trái đè Nhỏ bên phải), Đội 2 là `oO` (Nhỏ bên trái đè To bên phải)
  Widget _buildTeamAvatarSection({
    required BuildContext context,
    required _TeamDisplayData teamData,
    required bool isTeam1,
  }) {
    if (!teamData.isDoubles) {
      // Đánh đơn (1 VĐV): Avatar to tròn 52x52
      return _buildSingleAvatarCircle(
        context: context,
        size: 52,
        logoUrl: teamData.avatar1,
        abbr: teamData.abbr1,
        fontSize: 15,
      );
    }

    // Đánh đôi: Xếp lồng dạng `Oo` (Đội 1) hoặc `oO` (Đội 2)
    if (isTeam1) {
      // Đội 1: Oo (Avatar 1 to bên trái 42x42, Avatar 2 nhỏ 32x32 đè góc dưới phải)
      return SizedBox(
        width: 62,
        height: 52,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Avatar chính (To)
            Positioned(
              left: 0,
              top: 0,
              child: _buildSingleAvatarCircle(
                context: context,
                size: 42,
                logoUrl: teamData.avatar1,
                abbr: teamData.abbr1,
                fontSize: 12,
              ),
            ),
            // Avatar phụ (Nhỏ) đè lên phía dưới bên phải
            Positioned(
              right: 0,
              bottom: 0,
              child: _buildSingleAvatarCircle(
                context: context,
                size: 32,
                logoUrl: teamData.avatar2,
                abbr: teamData.abbr2,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      );
    } else {
      // Đội 2: oO (Avatar 1 nhỏ 32x32 bên trái, Avatar 2 to 42x42 đè lên bên phải)
      return SizedBox(
        width: 62,
        height: 52,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            // Avatar phụ (Nhỏ) bên trái
            Positioned(
              left: 0,
              bottom: 0,
              child: _buildSingleAvatarCircle(
                context: context,
                size: 32,
                logoUrl: teamData.avatar1,
                abbr: teamData.abbr1,
                fontSize: 9.5,
              ),
            ),
            // Avatar chính (To) đè lên phía trên bên phải
            Positioned(
              right: 0,
              top: 0,
              child: _buildSingleAvatarCircle(
                context: context,
                size: 42,
                logoUrl: teamData.avatar2,
                abbr: teamData.abbr2,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

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
                    l10n.matchesStatusLive,
                    style: TextStyle(
                      color: colors.textPrimary,
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
                child: Text(
                  l10n.viewAll,
                  style: const TextStyle(
                    color: AppTheme.webPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // ─── Live Match Cards Carousel (Theme-aware with crisp card borders) ───
        SizedBox(
          height: 155,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final match = liveMatches[index];
              final tournament = _getTournament(match.tournamentId);
              final tournamentName = _getTournamentName(match, l10n);

              final team1Data = _parseTeamData(
                rawName: match.team1Name,
                teamLogoUrl: match.team1LogoUrl,
                memberInfos: match.team1MemberInfos,
                fallbackName: 'Đội 1',
              );
              final team2Data = _parseTeamData(
                rawName: match.team2Name,
                teamLogoUrl: match.team2LogoUrl,
                memberInfos: match.team2MemberInfos,
                fallbackName: 'Đội 2',
              );

              final score1 = match.score1;
              final score2 = match.score2;

              return _buildCard(
                context: context,
                title: tournamentName,
                team1Data: team1Data,
                team2Data: team2Data,
                scoreText: '$score1 - $score2',
                logoUrl: tournament?.logoUrl ?? tournament?.bannerUrl,
                onTap: () {
                  HapticFeedback.selectionClick();
                  final tId = match.tournamentId ?? '';
                  context.push(
                    '/live/${match.id}${tId.isNotEmpty ? '?tournamentId=$tId' : ''}',
                  );
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
    required _TeamDisplayData team1Data,
    required _TeamDisplayData team2Data,
    required String scoreText,
    String? logoUrl,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;

    return Container(
      width: 295,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                // Top: Tournament Name + Chấm Live đỏ ẩn hiện từ từ
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
                          color: colors.textPrimary,
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

                // Middle: Teams với Avatar xếp kiểu Oo vs oO cho đánh đôi & Tỷ số rõ ràng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Team 1 (Oo cho đánh đôi)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTeamAvatarSection(
                            context: context,
                            teamData: team1Data,
                            isTeam1: true,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            team1Data.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tỷ số trận đấu lớn & rõ ràng
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        scoreText,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: scoreText == 'LIVE' ? 20 : 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    // Team 2 (oO cho đánh đôi)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTeamAvatarSection(
                            context: context,
                            teamData: team2Data,
                            isTeam1: false,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            team2Data.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 11.5,
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
