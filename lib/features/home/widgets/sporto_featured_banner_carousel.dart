import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/home/widgets/featured_tournament_banner_card.dart';
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
    _pageController = PageController(viewportFraction: 1.0);
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
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
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

        // ─── Banner Carousel (16:9 ratio, Full-bleed, respects hideFeaturedCardText) ───
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth - 32.0; // padding 16 hai bên
            final cardHeight = cardWidth / (16 / 9);

            return SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                onPageChanged: (idx) {
                  setState(() => _currentPage = idx);
                },
                itemBuilder: (context, index) {
                  final t = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FeaturedTournamentBannerCard(
                      tournament: t,
                      onTap: () => context.push('/intro/${t.id}'),
                    ),
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // ─── Dot Indicators ───
        if (items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (index) {
              final isSelected = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isSelected ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.webPrimary
                      : context.colors.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(100),
                ),
              );
            }),
          ),
      ],
    );
  }
}
