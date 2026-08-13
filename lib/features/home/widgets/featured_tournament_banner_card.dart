import 'dart:io' show Platform;

import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class FeaturedTournamentBannerCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const FeaturedTournamentBannerCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  String _resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final firstUrl = url.split(',').first.trim();
    if (firstUrl.startsWith('http')) return firstUrl;

    var apiBase = 'http://localhost:3000/api/v1';
    try {
      apiBase = dotenv.env['API_BASE_URL'] ?? apiBase;
      if (Platform.isAndroid && apiBase.contains('localhost')) {
        apiBase = apiBase.replaceAll('localhost', '10.0.2.2');
      }
    } catch (_) {}
    return '${apiBase.replaceAll('/api/v1', '')}$firstUrl';
  }

  String _dateRange() {
    final start = tournament.startDate;
    final end = tournament.endDate;
    if (start == null || end == null) return 'Chưa cập nhật lịch';
    final formatter = DateFormat('dd/MM/yyyy');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  String _sportLabel() {
    return AppConstants.sportNames[tournament.sport] ?? tournament.sport;
  }

  String _statusLabel() {
    switch (tournament.status.toLowerCase()) {
      case 'live':
      case 'in_progress':
        return 'Đang thi đấu';
      case 'completed':
      case 'finished':
        return 'Đã kết thúc';
      case 'registration':
      case 'published':
      case 'active':
        return 'Đang đăng ký';
      default:
        return 'Sắp diễn ra';
    }
  }

  Color _statusColor() {
    switch (tournament.status.toLowerCase()) {
      case 'live':
      case 'in_progress':
        return const Color(0xFF16A34A);
      case 'completed':
      case 'finished':
        return const Color(0xFF64748B);
      case 'registration':
      case 'published':
      case 'active':
        return AppTheme.primary;
      default:
        return const Color(0xFFF97316);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bannerUrl = _resolveImageUrl(tournament.bannerUrl);
    final hasBanner = bannerUrl.isNotEmpty;
    final hideText = tournament.hideFeaturedCardText;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasBanner)
                Image.network(
                  bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _FallbackBanner(colors: colors),
                )
              else
                _FallbackBanner(colors: colors),
              if (!hideText) ...[
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  top: 8,
                  child: Row(
                    children: [
                      _CompactTopSportBadge(
                        label: _sportLabel(),
                        icon: Icons.sports_tennis_rounded,
                      ),
                      const Spacer(),
                      _CompactTopStatusBadge(
                        label: _statusLabel(),
                        color: _statusColor(),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tournament.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      if ((tournament.locationAddress ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _MetaChip(
                          icon: Icons.location_on_rounded,
                          label: tournament.locationAddress!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackBanner extends StatelessWidget {
  final AppColorsExtension colors;

  const _FallbackBanner({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            AppTheme.primary.withValues(alpha: 0.22),
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: Image.asset(
            'assets/images/sporto_v1_with_text.png',
            width: 160,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _CompactTopSportBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CompactTopSportBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactTopStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _CompactTopStatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.88)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
