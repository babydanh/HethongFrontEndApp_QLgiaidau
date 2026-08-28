import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class SportoFeaturedBannerCarousel extends StatefulWidget {
  final List<Tournament> tournaments;
  final VoidCallback? onSeeAll;

  const SportoFeaturedBannerCarousel({
    super.key,
    required this.tournaments,
    this.onSeeAll,
  });

  @override
  State<SportoFeaturedBannerCarousel> createState() =>
      _SportoFeaturedBannerCarouselState();
}

class _SportoFeaturedBannerCarouselState
    extends State<SportoFeaturedBannerCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.tournaments.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % widget.tournaments.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  String _resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final firstUrl = url.split(',').first.trim();
    if (firstUrl.startsWith('http')) return firstUrl;

    final apiBase =
        dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
    return '${apiBase.replaceAll('/api/v1', '')}$firstUrl';
  }

  Widget _buildFallbackBanner(BuildContext context) {
    return Container(
      color: AppTheme.webPrimaryLight,
      alignment: Alignment.center,
      child: SvgPicture.asset(
        AppConstants.logoFullSvg,
        width: 180,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildBannerBackground(BuildContext context, Tournament tournament) {
    final bannerUrl = _resolveImageUrl(tournament.bannerUrl);
    if (bannerUrl.isEmpty) return _buildFallbackBanner(context);

    return Image.network(
      bannerUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildFallbackBanner(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = widget.tournaments;

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header Row ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.featuredTournaments,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: widget.onSeeAll,
                child: Text(
                  l10n.viewAll,
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

        // ─── Banner Carousel ───
        SizedBox(
          height: 248,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            onPageChanged: (idx) {
              setState(() => _currentPage = idx);
            },
            itemBuilder: (context, index) {
              final t = items[index];
              final sportLabel = AppConstants.sportNames[t.sport] ?? t.sport;
              final statusText = StatusHelper.getTournamentStatusLabel(
                t.status,
                l10n: l10n,
              );

              return GestureDetector(
                onTap: () => context.push('/tournaments/${t.id}'),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.webPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildBannerBackground(context, t),
                      if (!t.hideFeaturedCardText)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            color: AppTheme.webPrimary.withValues(alpha: 0.76),
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        sportLabel.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.webSecondary,
                                          fontSize: 9,
                                          height: 1.1,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        statusText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 9,
                                          height: 1.1,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${t.maxTeams} đội  •  ${t.divisions.length} bảng đấu',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    height: 1.1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ─── Pagination Dots ───
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (idx) {
              final isCurrent = idx == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCurrent ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppTheme.primary
                      : context.colors.border.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
