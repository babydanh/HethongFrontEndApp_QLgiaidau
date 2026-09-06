import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class AboutTab extends StatefulWidget {
  final Tournament tournament;
  final int teamCount;
  final String Function(String? url) resolveImageUrl;
  final ScrollController? scrollController;
  final VoidCallback? onNavigateToMatches;
  final VoidCallback? onRegisterTap;
  final bool isFollowing;
  final VoidCallback? onToggleFollow;
  final String? selectedDivision;
  final String? selectedDivisionId;
  final ValueChanged<TournamentDivision>? onChangedDivision;

  const AboutTab({
    super.key,
    required this.tournament,
    required this.teamCount,
    required this.resolveImageUrl,
    this.scrollController,
    this.onNavigateToMatches,
    this.onRegisterTap,
    this.isFollowing = false,
    this.onToggleFollow,
    this.selectedDivision,
    this.selectedDivisionId,
    this.onChangedDivision,
  });

  @override
  State<AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<AboutTab> {
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  String _countdownLabel = '';

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(covariant AboutTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tournament != widget.tournament) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _calculateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _calculateCountdown();
      }
    });
  }

  void _calculateCountdown() {
    final now = DateTime.now();
    final t = widget.tournament;

    if (t.status == AppConstants.statusInProgress && t.endDate != null) {
      final diff = t.endDate!.difference(now);
      if (diff.isNegative) {
        setState(() {
          _remainingTime = Duration.zero;
          _countdownLabel = 'Đã kết thúc';
        });
      } else {
        setState(() {
          _remainingTime = diff;
          _countdownLabel = 'Kết thúc sau';
        });
      }
      return;
    }

    if (t.registrationEndDate != null && now.isBefore(t.registrationEndDate!)) {
      final diff = t.registrationEndDate!.difference(now);
      setState(() {
        _remainingTime = diff;
        _countdownLabel = 'Hạn đăng ký còn';
      });
      return;
    }

    if (t.startDate != null && now.isBefore(t.startDate!)) {
      final diff = t.startDate!.difference(now);
      setState(() {
        _remainingTime = diff;
        _countdownLabel = 'Khai mạc sau';
      });
      return;
    }

    setState(() {
      _remainingTime = Duration.zero;
      _countdownLabel = '';
    });
  }

  String _formatDuration(Duration d) {
    if (d <= Duration.zero) return '00:00:00';
    final days = d.inDays;
    final hours = (d.inHours % 24).toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (days > 0) {
      return '$days ngày $hours:$minutes:$seconds';
    }
    return '$hours:$minutes:$seconds';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa cập nhật';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatCurrency(double? amount) {
    if (amount == null || amount <= 0) return 'Miễn phí';
    final fmt = NumberFormat('#,###', 'vi_VN');
    return '${fmt.format(amount)} đ';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════
          // ─── 1. BENTO OVERVIEW HERO (Khung hình Tổng quan ban đầu) ───
          // ═══════════════════════════════════════════════════════════════
          _buildHeroOverviewCard(context, t),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════════════════════
          // ─── 2. CHI TIẾT GIỚI THIỆU & ĐIỀU LỆ (Khi cuộn xuống) ─────────
          // ═══════════════════════════════════════════════════════════════
          _buildDetailsSection(context, t),
        ],
      ),
    );
  }

  /// Khung hình tổng quan gọn gàng, tinh tế theo phong cách Bento
  Widget _buildHeroOverviewCard(BuildContext context, Tournament t) {
    final colors = context.colors;
    final resolvedAvatar = widget.resolveImageUrl(t.creatorAvatarUrl);
    final creatorName = t.creatorFullName ?? 'Ban tổ chức';
    final dateRangeStr = (t.startDate != null && t.endDate != null)
        ? '${_formatDate(t.startDate)} - ${_formatDate(t.endDate)}'
        : (t.startDate != null
            ? _formatDate(t.startDate)
            : 'Chưa cập nhật thời gian');
    final locationStr = TournamentLocationFormatter.tournamentFullLocation(t);
    final divisionCount = t.divisions.isNotEmpty ? t.divisions.length : 1;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Carousel
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 175,
              width: double.infinity,
              child: _buildBannerView(t),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Organizer row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: colors.bgSurface,
                      backgroundImage: resolvedAvatar.isNotEmpty
                          ? NetworkImage(resolvedAvatar)
                          : null,
                      child: resolvedAvatar.isEmpty
                          ? Text(
                              creatorName.isNotEmpty
                                  ? creatorName[0].toUpperCase()
                                  : 'B',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BAN TỔ CHỨC',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colors.textMuted,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            creatorName,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildSportBadge(t.sport),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  t.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                    letterSpacing: -0.2,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),

                // Info Rows in Compact Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        icon: Icons.calendar_today_outlined,
                        label: 'Thời gian',
                        value: dateRangeStr,
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniStat(
                        icon: Icons.emoji_events_outlined,
                        label: 'Nội dung',
                        value: '$divisionCount phân hạng',
                        colors: colors,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildMiniStat(
                  icon: Icons.location_on_outlined,
                  label: 'Địa điểm',
                  value: locationStr.isNotEmpty
                      ? locationStr
                      : 'Chưa cập nhật địa điểm',
                  colors: colors,
                ),
                const SizedBox(height: 14),

                // Countdown Pill
                if (_countdownLabel.isNotEmpty &&
                    _remainingTime > Duration.zero) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$_countdownLabel ${_formatDuration(_remainingTime)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: colors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (widget.onNavigateToMatches != null) {
                            widget.onNavigateToMatches!();
                          }
                        },
                        icon: const Icon(
                          Icons.calendar_month_rounded,
                          size: 16,
                        ),
                        label: const Text(
                          'Lịch thi đấu',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (widget.onToggleFollow != null) {
                          widget.onToggleFollow!();
                        }
                      },
                      icon: Icon(
                        widget.isFollowing
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 16,
                        color: widget.isFollowing
                            ? AppTheme.primary
                            : colors.textMuted,
                      ),
                      label: Text(
                        widget.isFollowing ? 'Đã lưu' : 'Lưu',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerView(Tournament t) {
    final images = <String>[];
    if (t.bannerUrl != null && t.bannerUrl!.isNotEmpty) {
      images.add(t.bannerUrl!);
    }
    if (t.logoUrl != null &&
        t.logoUrl!.isNotEmpty &&
        !images.contains(t.logoUrl)) {
      images.add(t.logoUrl!);
    }
    if (images.isEmpty) {
      return Container(
        color: context.colors.bgSurface,
        child: Center(
          child: Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: context.colors.textMuted.withValues(alpha: 0.4),
          ),
        ),
      );
    }
    final firstUrl = widget.resolveImageUrl(images.first);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          firstUrl,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Container(
            color: context.colors.bgSurface,
            child: const Center(child: Icon(Icons.broken_image, size: 36)),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 10,
          child: Row(
            children: [
              _buildStatusBadge(t.status),
              const SizedBox(width: 6),
              if (t.isRanked) _buildRankingBadge(true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
    required AppColorsExtension colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Khối giới thiệu chi tiết (Mô tả, Điều lệ, Quy định, Giải thưởng)
  Widget _buildDetailsSection(BuildContext context, Tournament t) {
    final colors = context.colors;
    final desc = t.description.trim();
    final resolvedAvatar = widget.resolveImageUrl(t.creatorAvatarUrl);
    final creatorName = t.creatorFullName ?? 'Ban tổ chức';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('GIỚI THIỆU & ĐIỀU LỆ GIẢI ĐẤU'),
          const SizedBox(height: 14),

          // Creator details
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.bgSurface,
                backgroundImage: resolvedAvatar.isNotEmpty
                    ? NetworkImage(resolvedAvatar)
                    : null,
                child: resolvedAvatar.isEmpty
                    ? Text(
                        creatorName.isNotEmpty
                            ? creatorName[0].toUpperCase()
                            : 'B',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creatorName,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Đơn vị tổ chức chuyên nghiệp',
                      style: TextStyle(fontSize: 11.5, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colors.border.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 16),

          // Rich Description
          if (desc.isNotEmpty) ...[
            Text(
              'Thông tin chi tiết',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildDescriptionContent(desc),
            const SizedBox(height: 16),
          ],

          // Registration details
          _buildSectionHeader('THÔNG TIN ĐĂNG KÝ'),
          const SizedBox(height: 10),
          _buildMetaRow('Mở đăng ký:', _formatDate(t.registrationStartDate)),
          const SizedBox(height: 8),
          _buildMetaRow('Hạn chót:', _formatDate(t.registrationEndDate)),
          const SizedBox(height: 8),
          _buildMetaRow(
            'Lệ phí tham gia:',
            _formatCurrency(t.entryFee),
            isFee: true,
          ),
          const SizedBox(height: 16),

          // Prizes
          if (t.prizeDescription != null && t.prizeDescription!.isNotEmpty) ...[
            _buildSectionHeader('CƠ CẤU GIẢI THƯỞNG'),
            const SizedBox(height: 8),
            _buildDescriptionContent(t.prizeDescription!),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: context.colors.textMuted,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildDescriptionContent(String text) {
    final colors = context.colors;
    final isHtml = text.contains('<') && text.contains('>');
    if (isHtml) {
      return HtmlWidget(
        text,
        textStyle: TextStyle(
          fontSize: 13,
          color: colors.textSecondary,
          height: 1.5,
        ),
      );
    }
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: colors.textSecondary,
        height: 1.5,
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isFee = false}) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: colors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isFee ? colors.error : colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final l10n = AppLocalizations.of(context)!;
    final label = StatusHelper.getTournamentStatusLabel(status, l10n: l10n);
    final bg = StatusHelper.getTournamentStatusColor(status, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSportBadge(String sport) {
    final colors = context.colors;
    final name = sport.isNotEmpty
        ? AppConstants.sportNames[sport.toLowerCase()] ?? sport
        : 'Thể thao';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports_tennis_rounded, size: 12),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingBadge(bool isRanked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isRanked
            ? const Color(0xFFF59E0B)
            : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isRanked ? '★ Tính ELO' : 'Phong trào',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
