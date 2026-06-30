import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sport_pill.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/status_badge.dart';

class TournamentBanner extends StatefulWidget {
  final Tournament tournament;

  const TournamentBanner({
    super.key,
    required this.tournament,
  });

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
    if (widget.tournament.bannerUrl != null && widget.tournament.bannerUrl!.isNotEmpty) {
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 56,
                            color: colors.textMuted.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Chưa cập nhật ảnh",
                            style: TextStyle(
                              color: colors.textMuted.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
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
                        return Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                color: colors.textMuted,
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
                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
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
                      child: widget.tournament.logoUrl != null && widget.tournament.logoUrl!.isNotEmpty
                          ? Image.network(
                              widget.tournament.logoUrl!.startsWith("http")
                                  ? widget.tournament.logoUrl!
                                  : "https://qlgiaidau.esports.vn${widget.tournament.logoUrl!}",
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.network(
                                widget.tournament.creatorAvatarUrl ?? "https://cdn-icons-png.flaticon.com/512/3344/3344397.png",
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, size: 28),
                              ),
                            )
                          : Image.network(
                              widget.tournament.creatorAvatarUrl ?? "https://cdn-icons-png.flaticon.com/512/3344/3344397.png",
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, size: 28),
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
                            _buildTag("VÒNG TRÒN", colors, icon: Icons.loop_rounded, iconColor: const Color(0xFFD97706)),
                            const SizedBox(width: 6),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: const Size(0, 24),
                                foregroundColor: colors.textSecondary,
                                side: BorderSide(color: colors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () {},
                              icon: const Icon(Icons.share, size: 12),
                              label: const Text("Chia sẻ", style: TextStyle(fontSize: 10)),
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
                              _formatDateRange(widget.tournament.registrationStartDate, widget.tournament.registrationEndDate),
                              colors,
                            ),
                            _iconText(
                              Icons.location_on_outlined,
                              widget.tournament.locationAddress ?? "Chưa cập nhật địa điểm",
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

  Widget _buildTag(String text, AppColorsExtension colors, {IconData? icon, Color? iconColor}) {
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
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
