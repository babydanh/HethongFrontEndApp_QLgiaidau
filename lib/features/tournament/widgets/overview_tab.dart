import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_choice_tile.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_tournament_roster_widget.dart';
import 'package:app_quanly_giaidau/core/widgets/sporto_brand_fallback.dart';

class OverviewTab extends StatefulWidget {
  final Tournament tournament;
  final int teamCount;
  final String Function(String? url) resolveImageUrl;
  final VoidCallback? onNavigateToMatches;
  final VoidCallback? onNavigateToIntro;
  final bool isFollowing;
  final VoidCallback? onToggleFollow;
  final String? inviteCode;

  const OverviewTab({
    super.key,
    required this.tournament,
    required this.teamCount,
    required this.resolveImageUrl,
    this.onNavigateToMatches,
    this.onNavigateToIntro,
    this.isFollowing = false,
    this.onToggleFollow,
    this.inviteCode,
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

  String _resolveFormatBadge(Tournament t) {
    final l10n = AppLocalizations.of(context)!;
    final formatStr = (t.format).toLowerCase();
    final sportStr = (t.sport).toLowerCase();
    final isFootball =
        sportStr.contains('bóng đá') || sportStr.contains('football');

    if (isFootball) {
      return l10n.tournamentCategoryFootballMen;
    }
    final isDoubles =
        formatStr.contains('doubles') || formatStr.contains('đôi');
    return isDoubles
        ? l10n.createClubTournament_formatDoubles
        : l10n.createClubTournament_formatSingles;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final colors = context.colors;
    final resolvedAvatar = widget.resolveImageUrl(t.creatorAvatarUrl);
    final creatorName = t.creatorFullName ?? 'Ban tổ chức';
    final isClubLite = t.isClubLite;
    final locationStr = TournamentLocationFormatter.tournamentFullLocation(t);
    final hasCustomLogo = t.logoUrl != null && t.logoUrl!.trim().isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. BANNER TRÀN VIỀN (Hiển thị cho mọi giải trừ giải Siêu Lite nội bộ CLB) ───
          if (!isClubLite)
            SizedBox(
              height: 195,
              width: double.infinity,
              child: _buildBannerView(t),
            ),

          // ─── 2. NỘI DUNG TỔNG QUAN ───
          Padding(
            padding: EdgeInsets.fromLTRB(16, isClubLite ? 16 : 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Bar: Badges + Organizer Pill
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildSportBadge(t.sport),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            _resolveFormatBadge(t),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        _buildStatusBadge(t.status),
                        if (t.isRanked) _buildRankingBadge(true),
                      ],
                    ),
                    if (!hasCustomLogo &&
                        (resolvedAvatar.isNotEmpty || creatorName.isNotEmpty))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.border.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 9,
                              backgroundColor: AppTheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              backgroundImage: resolvedAvatar.isNotEmpty
                                  ? NetworkImage(resolvedAvatar)
                                  : null,
                              child: resolvedAvatar.isEmpty
                                  ? Text(
                                      creatorName.isNotEmpty
                                          ? creatorName[0].toUpperCase()
                                          : 'B',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 5),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 120),
                              child: Text(
                                creatorName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tên giải đấu lớn & nổi bật (ở ngoài card, tạo visual hierarchy mạnh mẽ)
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
                const SizedBox(height: 14),

                // ─── 3 STATS CARDS ROW (Matching Mockup Hình 2) ───
                Row(
                  children: [
                    // Card 1: Thời gian
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.border.withValues(alpha: 0.65),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              (t.startDate != null && t.endDate != null)
                                  ? '${t.startDate!.day} - ${t.endDate!.day}'
                                  : (t.startDate != null ? '${t.startDate!.day}' : '--'),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.startDate != null
                                  ? 'Tháng ${t.startDate!.month}, ${t.startDate!.year}'
                                  : 'Dự kiến',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: colors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Card 2: Địa điểm
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.border.withValues(alpha: 0.65),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 20,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t.venueName != null && t.venueName!.trim().isNotEmpty
                                  ? t.venueName!
                                  : (locationStr.isNotEmpty ? locationStr.split(',').first.trim() : 'Đang cập nhật'),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              locationStr.isNotEmpty
                                  ? locationStr.split(',').last.trim()
                                  : 'Việt Nam',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: colors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Card 3: Vận động viên
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.border.withValues(alpha: 0.65),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.groups_rounded,
                              size: 20,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.teamCount > 0 ? widget.teamCount : (t.maxTeams > 0 ? t.maxTeams : 0)}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Vận động viên',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: colors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── CARD LỆ PHÍ THAM GIA (Entry Fee Card) ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.65),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lệ phí giải',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                t.entryFee != null && t.entryFee! > 0
                                    ? 'Thanh toán trực tiếp / QR'
                                    : 'Miễn phí tham dự',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        _formatCurrency(t.entryFee),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: (t.entryFee != null && t.entryFee! > 0)
                              ? const Color(0xFFE11D48)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ─── GIỚI THIỆU SECTION (Matching Mockup Hình 2) ───
                if (t.description.trim().isNotEmpty) ...[
                  Text(
                    'Giới thiệu',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.description
                        .replaceAll(RegExp(r'<[^>]*>'), ' ')
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: colors.textSecondary,
                    ),
                  ),
                  if (widget.onNavigateToIntro != null) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: widget.onNavigateToIntro,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem thêm',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                ],

                // Đếm ngược (nếu có - tinh tế, tinh gọn)
                if (_countdownLabel.isNotEmpty &&
                    _remainingTime > Duration.zero) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.error.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_countdownLabel: ${_formatDuration(_remainingTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ─── BANNER QUẢN LÝ CHO BAN TỔ CHỨC ───
                Consumer(
                  builder: (context, ref, _) {
                    final authState = ref.watch(authProvider);
                    final userProfile = ref.watch(userProfileProvider).value;
                    final isCreator =
                        userProfile != null &&
                        userProfile.id.isNotEmpty &&
                        userProfile.id == t.creatorId;
                    final canManage =
                        authState.isAdmin || authState.isOrganizer || isCreator;

                    if (!canManage) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bạn là Ban tổ chức',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  t.isSuperLite
                                      ? 'Quản lý danh sách VĐV, tạo nhánh đấu'
                                      : 'Bốc thăm, điều hành trận & cập nhật tỉ số',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              if (t.isSuperLite) {
                                context.push('/lite-manage/${t.id}');
                              } else {
                                context.push(
                                  '/organizer/tournaments/${t.id}/manage',
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.settings_suggest_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Quản lý',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Nút Lịch thi đấu (nhanh gọn)
                if (!isClubLite) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        backgroundColor: colors.bgCard,
                        side: BorderSide(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          width: 1,
                        ),
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
                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                      label: const Text(
                        'Xem lịch thi đấu chi tiết',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ─── LƯỚI XÁC NHẬN THAM GIA 16/32 SLOT (ĐỒNG BỘ CHUẨN WEB) ───
                if (isClubLite ||
                    ((t.communityId != null && t.communityId!.isNotEmpty) &&
                        (t.isLite ||
                            t.divisions.isEmpty ||
                            t.divisions.length <= 1))) ...[
                  CommunityTournamentRosterWidget(
                    tournamentId: t.id,
                    communityId: t.communityId,
                    initialTournamentName: t.name,
                    categoryName: t.sport,
                    status: t.status,
                    inviteCode: widget.inviteCode,
                    maxParticipants: t.maxTeams,
                    startDate: t.startDate,
                    showTopBar: false,
                  ),
                  const SizedBox(height: 14),
                ],

                // ─── 3. LỘ TRÌNH ĐĂNG KÝ & THỜI GIAN BIỂU (Timeline Roadmap Card) ───
                if (!isClubLite &&
                    (t.registrationStartDate != null ||
                        t.registrationEndDate != null ||
                        t.startDate != null)) ...[
                  _buildSectionHeader('LỘ TRÌNH GIẢI ĐẤU'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.65),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimelineItem(
                          title: 'Mở đăng ký',
                          subtitle: _formatDate(t.registrationStartDate),
                          isFirst: true,
                          isLast: false,
                          isPassed: t.registrationStartDate != null &&
                              DateTime.now().isAfter(t.registrationStartDate!),
                        ),
                        _buildTimelineItem(
                          title: 'Hạn chót đăng ký',
                          subtitle: _formatDate(t.registrationEndDate),
                          isFirst: false,
                          isLast: false,
                          isPassed: t.registrationEndDate != null &&
                              DateTime.now().isAfter(t.registrationEndDate!),
                        ),
                        _buildTimelineItem(
                          title: 'Khai mạc thi đấu',
                          subtitle: _formatDate(t.startDate),
                          isFirst: false,
                          isLast: true,
                          isPassed: t.startDate != null &&
                              DateTime.now().isAfter(t.startDate!),
                        ),
                      ],
                    ),
                  ),
                ],

                // ─── 4. NGƯỜI SÁNG LẬP GIẢI ĐẤU (ĐẶT Ở CUỐI KHI GIẢI CÓ LOGO) ───
                if (hasCustomLogo &&
                    (resolvedAvatar.isNotEmpty || creatorName.isNotEmpty)) ...[
                  const SizedBox(height: 14),
                  _buildSectionHeader('BAN TỔ CHỨC GIẢI ĐẤU'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.65),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage: resolvedAvatar.isNotEmpty
                              ? NetworkImage(resolvedAvatar)
                              : null,
                          child: resolvedAvatar.isEmpty
                              ? Text(
                                  creatorName.isNotEmpty
                                      ? creatorName[0].toUpperCase()
                                      : 'B',
                                  style: const TextStyle(
                                    fontSize: 14,
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
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                'Ban tổ chức giải đấu',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460),
            ],
          ),
        ),
        child: const SportoBrandFallback(
          withTagline: true,
          padding: EdgeInsets.all(32),
          semanticsLabel: 'SportO tournament fallback banner',
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
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
            child: const SportoBrandFallback(
              withTagline: true,
              padding: EdgeInsets.all(32),
              semanticsLabel: 'SportO tournament fallback banner',
            ),
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

  Widget _buildStatusBadge(String status) {
    final l10n = AppLocalizations.of(context)!;
    final label = StatusHelper.getTournamentStatusLabel(status, l10n: l10n);
    final bg = StatusHelper.getTournamentStatusColor(status, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSportBadge(String sport) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = sport.isNotEmpty
        ? AppConstants.sportNames[sport.toLowerCase()] ?? sport
        : 'Thể thao';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.12)
            : colors.bgCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : colors.border.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SportChoiceTile.buildSportIcon(sport, 14),
          const SizedBox(width: 5),
          Text(
            name,
            style: TextStyle(
              fontSize: 11.5,
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

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required bool isFirst,
    required bool isLast,
    required bool isPassed,
  }) {
    final colors = context.colors;
    final dotColor = isPassed ? AppTheme.primary : colors.textMuted.withValues(alpha: 0.4);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPassed ? dotColor : Colors.transparent,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: isPassed
                          ? AppTheme.primary.withValues(alpha: 0.4)
                          : colors.border.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isPassed ? FontWeight.w700 : FontWeight.w600,
                      color: isPassed ? colors.textPrimary : colors.textMuted,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPassed ? AppTheme.primary : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

