import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';

import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sport_pill.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/status_badge.dart';
import 'package:app_quanly_giaidau/shared/widgets/app_image_viewer.dart';

class TournamentHeaderView extends StatefulWidget {
  final Tournament tournament;
  final AppColorsExtension colors;
  final bool compact;
  final String? selectedDivision;
  final String? selectedDivisionId;
  final ValueChanged<TournamentDivision>? onChangedDivision;

  const TournamentHeaderView({
    super.key,
    required this.tournament,
    required this.colors,
    this.compact = false,
    this.selectedDivision,
    this.selectedDivisionId,
    this.onChangedDivision,
  });

  @override
  State<TournamentHeaderView> createState() => _TournamentHeaderViewState();
}

class _TournamentHeaderViewState extends State<TournamentHeaderView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final images = _collectImages(widget.tournament);
    final compact = widget.compact;
    final showBannerOverlay = !widget.tournament.hideFeaturedCardText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      color: colors.bgDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: compact ? 0 : 185,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: compact ? 0 : 1,
                  child: _BannerCarousel(
                    images: images,
                    pageController: _pageController,
                    currentPage: _currentPage,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    showOverlay: showBannerOverlay,
                    tournament: widget.tournament,
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: colors.bgDark,
            padding: EdgeInsets.fromLTRB(14, compact ? 6 : 8, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topLeft,
                  child: compact
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            _HeaderBadges(tournament: widget.tournament),
                            const SizedBox(height: 8),
                          ],
                        ),
                ),
                _HeaderInfo(
                  tournament: widget.tournament,
                  compact: compact,
                ),
                SizedBox(height: compact ? 8 : 10),
                _HeaderMeta(
                  tournament: widget.tournament,
                  selectedDivision: widget.selectedDivision,
                  selectedDivisionId: widget.selectedDivisionId,
                  onChangedDivision: widget.onChangedDivision,
                ),
                const SizedBox(height: 8),
                Divider(color: colors.border, height: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

class _BannerCarousel extends StatelessWidget {
  final Tournament tournament;
  final List<String> images;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final bool showOverlay;

  const _BannerCarousel({
    required this.tournament,
    required this.images,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.showOverlay,
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
                    final resolvedList = images
                        .map((i) => _resolveImageUrl(i))
                        .toList();
                    return GestureDetector(
                      onTap: () {
                        AppImageViewer.showGallery(
                          context,
                          imageUrls: resolvedList,
                          initialIndex: index,
                        );
                      },
                      child: Image.network(
                        resolvedList[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _FallbackBanner(),
                      ),
                    );
                  },
                ),
        ),
        if (showOverlay)
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
        if (tournament.logoUrl?.trim().isNotEmpty == true)
          Positioned(
            top: 12,
            right: 12,
            child: _TournamentLogo(tournament: tournament, size: 58),
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
    final l10n = AppLocalizations.of(context)!;
    return SvgPicture.network(
      "https://sporto.asia/sporto_v1.svg",
      fit: BoxFit.contain,
      placeholderBuilder: (_) => Container(
        color: const Color(0xFF1E293B),
        child: Center(
          child: Text(
            l10n.sporto,
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
    final l10n = AppLocalizations.of(context)!;
    final bracketLabel = l10n
        .bracketDisplayName(tournament.bracketType)
        .toUpperCase();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        SportPill(sportKey: tournament.sport),
        StatusBadge(statusKey: tournament.status),
        _HeaderTag(
          tournament.isRanked ? l10n.rankedELO : l10n.unranked,
          icon: tournament.isRanked
              ? Icons.stars_rounded
              : Icons.sports_score_rounded,
          iconColor: tournament.isRanked
              ? const Color(0xFFF59E0B)
              : const Color(0xFF10B981),
        ),
        _HeaderTag(
          bracketLabel.toUpperCase(),
          icon: Icons.loop_rounded,
          iconColor: const Color(0xFFD97706),
        ),
      ],
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  final Tournament tournament;
  final bool compact;

  const _HeaderInfo({required this.tournament, required this.compact});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      style: TextStyle(
        fontSize: compact ? 15 : 18,
        fontWeight: FontWeight.w900,
        color: colors.textPrimary,
        height: 1.18,
        letterSpacing: -0.35,
      ),
      child: Text(
        tournament.name.toUpperCase(),
        maxLines: compact ? 2 : 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _HeaderMeta extends StatelessWidget {
  final Tournament tournament;
  final String? selectedDivision;
  final String? selectedDivisionId;
  final ValueChanged<TournamentDivision>? onChangedDivision;

  const _HeaderMeta({
    required this.tournament,
    this.selectedDivision,
    this.selectedDivisionId,
    this.onChangedDivision,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final locationLabel = TournamentLocationFormatter.tournamentFullLocation(tournament);
    final divisions = tournament.divisions;

    final selected =
        divisions
            .where(
              (d) => d.id == selectedDivisionId || d.name == selectedDivision,
            )
            .firstOrNull ??
        divisions.firstOrNull;

    final registeredCount = selected?.participantCount ?? 0;
    final maxCount = selected?.maxParticipants ?? tournament.maxTeams;

    final divisionSelector = divisions.length > 1 && onChangedDivision != null
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selected?.name ?? selectedDivision,
                isDense: true,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                items: divisions.map((division) {
                  final divReg = division.participantCount;
                  final divMax =
                      division.maxParticipants ?? tournament.maxTeams;
                  return DropdownMenuItem<String>(
                    value: division.name,
                    child: Text(
                      '${division.name}  •  $divReg/$divMax',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final div = divisions.firstWhere(
                    (item) => item.name == value,
                  );
                  onChangedDivision!(div);
                },
              ),
            ),
          )
        : Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.groups_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    selected != null
                        ? '${selected.name}  •  $registeredCount/$maxCount'
                        : '$registeredCount / $maxCount ${l10n.teamsUnit}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _HeaderIconText(
              icon: Icons.calendar_today_rounded,
              text: _formatDateRange(
                tournament.registrationStartDate,
                tournament.registrationEndDate,
                l10n.notUpdated,
              ),
            ),
            _HeaderIconText(
              icon: Icons.location_on_outlined,
              text: locationLabel.isNotEmpty
                  ? locationLabel
                  : l10n.locationNotUpdated,
            ),
          ],
        ),
        if (selected != null) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.view_list_rounded, size: 16, color: colors.textMuted),
              const SizedBox(width: 7),
              Expanded(child: divisionSelector),
            ],
          ),
        ],
      ],
    );
  }
}

class _HeaderTag extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? iconColor;

  const _HeaderTag(this.text, {this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor ?? colors.textSecondary),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
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

  const _HeaderIconText({required this.icon, required this.text});

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

  const _TournamentLogo({required this.tournament, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logoUrl = tournament.logoUrl?.trim();
    if (logoUrl == null || logoUrl.isEmpty) return const SizedBox.shrink();

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
        child: Image.network(
          _resolveImageUrl(logoUrl),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const SizedBox.shrink(),
        ),
      ),
    );
  }
}



String _resolveImageUrl(String url) {
  if (url.startsWith("http")) return url;
  return "https://sporto.asia$url";
}

String _formatDateRange(DateTime? start, DateTime? end, String fallback) {
  if (start == null && end == null) {
    return fallback;
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
    final l10n = AppLocalizations.of(context)!;
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
                      "https://sporto.asia/sporto_v1.svg",
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) => Container(
                        color: const Color(0xFF1E293B),
                        child: Center(
                          child: Text(
                            l10n.sporto,
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
                            : "https://sporto.asia${images[index]}";
                        return Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return SvgPicture.network(
                              "https://sporto.asia/sporto_v1.svg",
                              fit: BoxFit.contain,
                              placeholderBuilder: (_) => Container(
                                color: const Color(0xFF1E293B),
                                child: Center(
                                  child: Text(
                                    l10n.sporto,
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
                                  : "https://sporto.asia${widget.tournament.logoUrl!}",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  SvgPicture.network(
                                    "https://sporto.asia/sporto_v1_with_text.svg",
                                    fit: BoxFit.contain,
                                    placeholderBuilder: (_) => const Icon(
                                      Icons.emoji_events,
                                      size: 28,
                                    ),
                                  ),
                            )
                          : SvgPicture.network(
                              "https://sporto.asia/sporto_v1_with_text.svg",
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
                            _buildTag(
                              (StatusHelper.isTournamentRegistrationClosed(
                                        widget.tournament.status,
                                      ) ||
                                      widget.tournament.status.toUpperCase() ==
                                          'REGISTRATION_CLOSED' ||
                                      widget.tournament.status.toUpperCase() ==
                                          'CLOSED')
                                  ? l10n.registrationClosedTag
                                  : l10n.registrationOpenTag,
                              colors,
                              color:
                                  (StatusHelper.isTournamentRegistrationClosed(
                                        widget.tournament.status,
                                      ) ||
                                      widget.tournament.status.toUpperCase() ==
                                          'REGISTRATION_CLOSED' ||
                                      widget.tournament.status.toUpperCase() ==
                                          'CLOSED')
                                  ? colors.error
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            _buildTag(
                              l10n.roundRobinTag,
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
                                AppShareModal.show(
                                  context: context,
                                  title: tournament.name,
                                  subtitle:
                                      '${tournament.locationAddress ?? l10n.vietnam} • ${tournament.category ?? tournament.sport}',
                                  webUrl:
                                      'https://sporto.asia/tournaments/${tournament.id}',
                                  imageUrl:
                                      tournament.logoUrl ??
                                      tournament.bannerUrl,
                                  badgeText: tournament.isClubLite
                                      ? l10n.liteTournament
                                      : l10n.advancedTournament,
                                );
                              },
                              icon: const Icon(Icons.share, size: 12),
                              label: Text(
                                l10n.share,
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
                                l10n.notUpdated,
                              ),
                              colors,
                            ),
                            _iconText(
                              Icons.location_on_outlined,
                              _locationLabel(widget.tournament),
                              colors,
                              maxTextWidth: 280,
                              maxLines: 5,
                            ),
                            _iconText(
                              Icons.group_rounded,
                              "0 / 16 ${l10n.teamsUnit}",
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

  String _formatDateRange(DateTime? start, DateTime? end, String fallback) {
    if (start == null && end == null) {
      return fallback;
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
    Color? color,
  }) {
    final textColor = color ?? colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color != null
            ? color.withValues(alpha: 0.12)
            : colors.bgElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color != null ? color.withValues(alpha: 0.3) : colors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: iconColor ?? textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconText(
    IconData icon,
    String text,
    AppColorsExtension colors, {
    double? maxTextWidth,
    int maxLines = 1,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.textMuted),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: maxTextWidth == null
              ? const BoxConstraints()
              : BoxConstraints(maxWidth: maxTextWidth),
          child: Text(
            text,
            softWrap: maxTextWidth != null,
            maxLines: maxTextWidth == null ? 1 : maxLines,

            overflow: maxTextWidth == null
                ? TextOverflow.ellipsis
                : TextOverflow.visible,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ),
      ],
    );
  }

  String _locationLabel(Tournament tournament) {
    final location = TournamentLocationFormatter.tournamentFullLocation(
      tournament,
    );

    return location.isEmpty
        ? AppLocalizations.of(context)!.locationNotUpdated
        : location;
  }
}
