import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class OverviewTab extends StatefulWidget {
  final Tournament tournament;
  final int teamCount;
  final String Function(String? url) resolveImageUrl;
  final VoidCallback? onNavigateToMatches;
  final void Function(TournamentDivision division)? onSelectDivision;
  final bool isFollowing;
  final VoidCallback? onToggleFollow;

  const OverviewTab({
    super.key,
    required this.tournament,
    required this.teamCount,
    required this.resolveImageUrl,
    this.onNavigateToMatches,
    this.onSelectDivision,
    this.isFollowing = false,
    this.onToggleFollow,
  });

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  String _countdownLabel = '';

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(covariant OverviewTab oldWidget) {
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
    final colors = context.colors;
    final resolvedAvatar = widget.resolveImageUrl(t.creatorAvatarUrl);
    final creatorName = t.creatorFullName ?? 'Ban tổ chức';
    final dateRangeStr = (t.startDate != null && t.endDate != null)
        ? '${_formatDate(t.startDate)} - ${_formatDate(t.endDate)}'
        : (t.startDate != null
            ? _formatDate(t.startDate)
            : 'Chưa cập nhật thời gian');
    final locationStr = TournamentLocationFormatter.tournamentFullLocation(t);
    final desc = t.description.trim();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. BANNER TRÀN VIỀN ───
          SizedBox(
            height: 195,
            width: double.infinity,
            child: _buildBannerView(t),
          ),

          // ─── 2. NỘI DUNG TỔNG QUAN ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges + Ban tổ chức Row
                Row(
                  children: [
                    _buildSportBadge(t.sport),
                    const SizedBox(width: 6),
                    _buildStatusBadge(t.status),
                    if (t.isRanked) ...[
                      const SizedBox(width: 6),
                      _buildRankingBadge(true),
                    ],
                    const Spacer(),
                    if (resolvedAvatar.isNotEmpty || creatorName.isNotEmpty)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
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
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 110),
                            child: Text(
                              creatorName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tên giải đấu lớn
                Text(
                  t.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),

                // Thông tin nhanh
                _buildInlineInfo(
                  icon: Icons.calendar_today_outlined,
                  label: 'Thời gian:',
                  value: dateRangeStr,
                  colors: colors,
                ),
                const SizedBox(height: 6),
                _buildInlineInfo(
                  icon: Icons.location_on_outlined,
                  label: 'Địa điểm:',
                  value: locationStr.isNotEmpty
                      ? locationStr
                      : 'Chưa cập nhật địa điểm',
                  colors: colors,
                ),
                const SizedBox(height: 12),

                // Đếm ngược (nếu có)
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
                          padding: const EdgeInsets.symmetric(vertical: 11),
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
                          'Xem Lịch thi đấu',
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
                          vertical: 11,
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
                const SizedBox(height: 20),
                Divider(color: colors.border.withValues(alpha: 0.6), height: 1),
                const SizedBox(height: 16),

                // ─── 3. DANH SÁCH NỘI DUNG / PHÂN HẠNG THI ĐẤU (CHUẨN WEB) ───
                _buildSectionHeader('NỘI DUNG THI ĐẤU (${t.divisions.length})'),
                const SizedBox(height: 10),
                if (t.divisions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Chưa có phân hạng thi đấu',
                      style: TextStyle(fontSize: 13, color: colors.textMuted),
                    ),
                  )
                else
                  ...t.divisions.map((div) => _buildDivisionItem(div, colors)),

                const SizedBox(height: 20),
                Divider(color: colors.border.withValues(alpha: 0.6), height: 1),
                const SizedBox(height: 16),

                // ─── 4. THÔNG TIN ĐĂNG KÝ & LỆ PHÍ ───
                _buildSectionHeader('THỜI GIAN ĐĂNG KÝ & LỆ PHÍ'),
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

                // ─── 5. GIỚI THIỆU CHI TIẾT ───
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Divider(color: colors.border.withValues(alpha: 0.6), height: 1),
                  const SizedBox(height: 16),
                  _buildSectionHeader('THÔNG TIN GIỚI THIỆU'),
                  const SizedBox(height: 10),
                  _buildDescriptionContent(desc),
                ],

                // ─── 6. CƠ CẤU GIẢI THƯỞNG ───
                if (t.prizeDescription != null &&
                    t.prizeDescription!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Divider(color: colors.border.withValues(alpha: 0.6), height: 1),
                  const SizedBox(height: 16),
                  _buildSectionHeader('CƠ CẤU GIẢI THƯỞNG'),
                  const SizedBox(height: 10),
                  _buildDescriptionContent(t.prizeDescription!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivisionItem(TournamentDivision div, AppColorsExtension colors) {
    final maxP = div.maxParticipants ?? 0;
    final curP = div.participantCount;
    final isFull = maxP > 0 && curP >= maxP;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: () {
          if (widget.onSelectDivision != null) {
            widget.onSelectDivision!(div);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  div.name,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (isFull) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bgDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    'Đã đủ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    size: 14,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    maxP > 0 ? '$curP / $maxP' : '$curP VĐV',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                Colors.black.withValues(alpha: 0.1),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineInfo({
    required IconData icon,
    required String label,
    required String value,
    required AppColorsExtension colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: colors.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: colors.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
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
          fontSize: 13.5,
          color: colors.textSecondary,
          height: 1.55,
        ),
      );
    }
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        color: colors.textSecondary,
        height: 1.55,
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
            fontSize: 13,
            color: colors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isFee ? colors.error : colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final colors = context.colors;
    final s = status.toUpperCase();
    Color bg = colors.bgSurface;
    Color fg = colors.textSecondary;
    String label = 'Sắp diễn ra';

    if (s == 'IN_PROGRESS' || s == 'ONGOING' || s == 'LIVE') {
      bg = colors.error;
      fg = Colors.white;
      label = '● LIVE';
    } else if (s == 'REGISTRATION' || s == 'REGISTRATION_OPEN' || s == 'OPEN') {
      bg = colors.success;
      fg = Colors.white;
      label = 'Mở đăng ký';
    } else if (s == 'COMPLETED' || s == 'FINISHED') {
      bg = colors.bgSurface;
      fg = colors.textMuted;
      label = 'Đã kết thúc';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        '🏓 $name',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildRankingBadge(bool isRanked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isRanked
            ? const Color(0xFFF59E0B)
            : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isRanked ? '★ ELO' : 'Phong trào',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
