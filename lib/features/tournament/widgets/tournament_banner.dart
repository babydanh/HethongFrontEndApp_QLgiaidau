import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sport_pill.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/status_badge.dart';

class TournamentCollapsibleHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Tournament tournament;
  final AppColorsExtension colors;

  TournamentCollapsibleHeaderDelegate({
    required this.tournament,
    required this.colors,
  });

  @override
  double get maxExtent => 410;

  @override
  double get minExtent => 100;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return TournamentCollapsibleHeader(
      tournament: tournament,
      progress: progress,
      overlapsContent: overlapsContent,
    );
  }

  @override
  bool shouldRebuild(TournamentCollapsibleHeaderDelegate oldDelegate) {
    return oldDelegate.tournament != tournament || oldDelegate.colors != colors;
  }
}

class TournamentCollapsibleHeader extends StatefulWidget {
  final Tournament tournament;
  final double progress;
  final bool overlapsContent;

  const TournamentCollapsibleHeader({
    super.key,
    required this.tournament,
    required this.progress,
    required this.overlapsContent,
  });

  @override
  State<TournamentCollapsibleHeader> createState() =>
      _TournamentCollapsibleHeaderState();
}

class _TournamentCollapsibleHeaderState
    extends State<TournamentCollapsibleHeader> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final images = _collectImages(widget.tournament);
    // Nấc 2: lướt nhẹ 1 phát dứt khoát chuyển sang Nấc thu gọn
    final isCollapsed = widget.progress > 0.15;

    return Material(
      color: colors.bgDark,
      elevation: isCollapsed ? 3 : 0,
      child: SafeArea(
        top: false,
        bottom: false,
        child: ClipRect(
          child: isCollapsed
              ? _buildCollapsedHeader(colors)
              : _buildExpandedHeader(colors, images),
        ),
      ),
    );
  }

  /// Nấc 1 (Ban đầu): Banner trên cùng, thông tin nằm dưới hoàn toàn (không che banner)
  Widget _buildExpandedHeader(AppColorsExtension colors, List<String> images) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner trên cùng đầy đủ
          SizedBox(
            height: 190,
            child: _BannerCarousel(
              images: images,
              pageController: _pageController,
              currentPage: _currentPage,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
            ),
          ),
          // Thông tin giải đấu nằm NGOÀI banner, tràn lan trên nền trang
          Container(
            color: colors.bgDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderBadges(tournament: widget.tournament),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo nhỏ ban đầu (48px)
                    _TournamentLogo(
                      tournament: widget.tournament,
                      size: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeaderInfo(
                        tournament: widget.tournament,
                        compact: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _HeaderMeta(tournament: widget.tournament),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Nấc 2 (Đã cuộn xuống): Banner ẩn đi, Logo tự thu lại to ra (60px), dọn gọn các dòng chữ
  Widget _buildCollapsedHeader(AppColorsExtension colors) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo to rõ hơn ở nấc thu gọn (60px)
          _TournamentLogo(
            tournament: widget.tournament,
            size: 60,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SportPill(sportKey: widget.tournament.sport),
                    const SizedBox(width: 6),
                    StatusBadge(statusKey: widget.tournament.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.tournament.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _collectImages(Tournament tournament) {
    final images = <String>[];
    if (tournament.bannerUrl != null && tournament.bannerUrl!.isNotEmpty) {
      images.add(tournament.bannerUrl!);
    }
    if (tournament.galleryImages.isNotEmpty) {
      images.addAll(tournament.galleryImages);
    }
    return images;
  }
}

class _BannerCarousel extends StatelessWidget {
  final List<String> images;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _BannerCarousel({
    required this.images,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: colors.bgCard,
          child: images.isEmpty
              ? _FallbackBanner()
              : PageView.builder(
                  controller: pageController,
                  itemCount: images.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (context, index) {
                    return Image.network(
                      _resolveImageUrl(images[index]),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _FallbackBanner(),
                    );
                  },
                ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.08),
                Colors.black.withValues(alpha: 0.45),
              ],
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 34,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                final isActive = index == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: isActive ? 18 : 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _FallbackBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.network(
      "https://giaidau.vnvar.com/vndcsport.svg",
      fit: BoxFit.contain,
      placeholderBuilder: (_) => Container(
        color: const Color(0xFF1E293B),
        child: const Center(
          child: Text(
            "VNSPORT",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white24,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBadges extends StatelessWidget {
  final Tournament tournament;

  const _HeaderBadges({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SportPill(sportKey: tournament.sport),
        const SizedBox(width: 8),
        StatusBadge(statusKey: tournament.status),
      ],
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  final Tournament tournament;
  final bool compact;

  const _HeaderInfo({
    required this.tournament,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          style: TextStyle(
            fontSize: compact ? 20 : 24,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            height: 1.18,
            letterSpacing: -0.45,
          ),
          child: Text(
            tournament.name.toUpperCase(),
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _HeaderTag("ĐĂNG KÝ"),
            _HeaderTag(
              "VÒNG TRÒN",
              icon: Icons.loop_rounded,
              iconColor: const Color(0xFFD97706),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                minimumSize: const Size(0, 26),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: colors.textSecondary,
                side: BorderSide(color: colors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              onPressed: () {
                final text = '${tournament.name} - ${tournament.category ?? tournament.sport}';
                final url = 'https://giaidau.vnvar.com/tournaments/${tournament.id}';
                SharePlus.instance.share(ShareParams(text: '$text\n\n$url'));
              },
              icon: const Icon(Icons.share, size: 13),
              label: const Text(
                "Chia sẻ",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderMeta extends StatelessWidget {
  final Tournament tournament;

  const _HeaderMeta({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: 14,
      runSpacing: 7,
      children: [
        _HeaderIconText(
          icon: Icons.calendar_today_rounded,
          text: _formatDateRange(
            tournament.registrationStartDate,
            tournament.registrationEndDate,
          ),
        ),
        _HeaderIconText(
          icon: Icons.location_on_outlined,
          text: tournament.locationAddress ?? "Chưa cập nhật địa điểm",
        ),
        _HeaderIconText(
          icon: Icons.group_rounded,
          text: "0 / ${tournament.maxTeams} Đội",
        ),
      ].map((child) {
        return DefaultTextStyle.merge(
          style: TextStyle(color: colors.textSecondary),
          child: child,
        );
      }).toList(),
    );
  }
}

class _HeaderTag extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? iconColor;

  const _HeaderTag(
    this.text, {
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: iconColor ?? colors.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: colors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderIconText({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colors.textMuted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TournamentLogo extends StatelessWidget {
  final Tournament tournament;
  final double size;

  const _TournamentLogo({
    required this.tournament,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logoUrl = tournament.logoUrl;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: logoUrl != null && logoUrl.isNotEmpty
            ? Image.network(
                _resolveImageUrl(logoUrl),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _FallbackLogo(size: size),
              )
            : _FallbackLogo(size: size),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  final double size;

  const _FallbackLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.network(
      "https://giaidau.vnvar.com/vndcsport.svg",
      fit: BoxFit.contain,
      placeholderBuilder: (_) => Icon(Icons.emoji_events, size: size * 0.5),
    );
  }
}

String _resolveImageUrl(String url) {
  if (url.startsWith("http")) return url;
  return "https://qlgiaidau.esports.vn$url";
}

String _formatDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) {
    return "Chưa cập nhật";
  }
  final startStr = start != null
      ? "${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}"
      : "...";
  final endStr = end != null
      ? "${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}"
      : "...";
  return "$startStr - $endStr";
}

class TournamentBanner extends StatefulWidget {
  final Tournament tournament;

  const TournamentBanner({super.key, required this.tournament});

  @override
  State<TournamentBanner> createState() => _TournamentBannerState();
}

class _TournamentBannerState extends State<TournamentBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final List<String> images = [];
    if (widget.tournament.bannerUrl != null &&
        widget.tournament.bannerUrl!.isNotEmpty) {
      images.add(widget.tournament.bannerUrl!);
    }
    if (widget.tournament.galleryImages.isNotEmpty) {
      images.addAll(widget.tournament.galleryImages);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 240,
              width: double.infinity,
              color: colors.bgCard,
              child: images.isEmpty
                  ? SvgPicture.network(
                      "https://giaidau.vnvar.com/vndcsport.svg",
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) => Container(
                        color: const Color(0xFF1E293B),
                        child: const Center(
                          child: Text(
                            "VNSPORT",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white24,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final imgUrl = images[index].startsWith("http")
                            ? images[index]
                            : "https://qlgiaidau.esports.vn${images[index]}";
                        return Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return SvgPicture.network(
                              "https://giaidau.vnvar.com/vndcsport.svg",
                              fit: BoxFit.contain,
                              placeholderBuilder: (_) => Container(
                                color: const Color(0xFF1E293B),
                                child: const Center(
                                  child: Text(
                                    "VNSPORT",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white24,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: isActive ? 16.0 : 6.0,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SportPill(sportKey: widget.tournament.sport),
                  const SizedBox(width: 8),
                  StatusBadge(statusKey: widget.tournament.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.tournament.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  height: 1.35,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child:
                          widget.tournament.logoUrl != null &&
                              widget.tournament.logoUrl!.isNotEmpty
                          ? Image.network(
                              widget.tournament.logoUrl!.startsWith("http")
                                  ? widget.tournament.logoUrl!
                                  : "https://qlgiaidau.esports.vn${widget.tournament.logoUrl!}",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  SvgPicture.network(
                                    "https://giaidau.vnvar.com/vndcsport.svg",
                                    fit: BoxFit.contain,
                                    placeholderBuilder: (_) => const Icon(
                                      Icons.emoji_events,
                                      size: 28,
                                    ),
                                  ),
                            )
                          : SvgPicture.network(
                              "https://giaidau.vnvar.com/vndcsport.svg",
                              fit: BoxFit.contain,
                              placeholderBuilder: (_) =>
                                  const Icon(Icons.emoji_events, size: 28),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildTag("ĐĂNG KÝ", colors),
                            const SizedBox(width: 6),
                            _buildTag(
                              "VÒNG TRÒN",
                              colors,
                              icon: Icons.loop_rounded,
                              iconColor: const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: const Size(0, 24),
                                foregroundColor: colors.textSecondary,
                                side: BorderSide(color: colors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () {
                                final tournament = widget.tournament;
                                final text =
                                    '${tournament.name} - ${tournament.category ?? tournament.sport}';
                                final url =
                                    'https://giaidau.vnvar.com/tournaments/${tournament.id}';
                                SharePlus.instance.share(
                                  ShareParams(text: '$text\n\n$url'),
                                );
                              },
                              icon: const Icon(Icons.share, size: 12),
                              label: const Text(
                                "Chia sẻ",
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _iconText(
                              Icons.calendar_today_rounded,
                              _formatDateRange(
                                widget.tournament.registrationStartDate,
                                widget.tournament.registrationEndDate,
                              ),
                              colors,
                            ),
                            _iconText(
                              Icons.location_on_outlined,
                              widget.tournament.locationAddress ??
                                  "Chưa cập nhật địa điểm",
                              colors,
                            ),
                            _iconText(
                              Icons.group_rounded,
                              "0 / 16 Đội",
                              colors,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: colors.border, height: 1.0),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      return "Chưa cập nhật";
    }
    final startStr = start != null
        ? "${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}"
        : "...";
    final endStr = end != null
        ? "${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}"
        : "...";
    return "$startStr - $endStr";
  }

  Widget _buildTag(
    String text,
    AppColorsExtension colors, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: iconColor ?? colors.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text, AppColorsExtension colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
      ],
    );
  }
}
