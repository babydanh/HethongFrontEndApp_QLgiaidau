import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_tournament_roster_widget.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_choice_tile.dart';
import 'package:app_quanly_giaidau/core/widgets/sporto_brand_fallback.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class OverviewTab extends StatefulWidget {
  final Tournament tournament;
  final int teamCount;
  final String Function(String? url) resolveImageUrl;
  final VoidCallback? onNavigateToIntro;
  final bool isFollowing;
  final VoidCallback? onToggleFollow;
  final String? inviteCode;
  final bool hasSliverBanner;
  final VoidCallback? onEditGeneral;
  final VoidCallback? onEditBranding;
  final VoidCallback? onEditVenues;
  final VoidCallback? onEditRegistration;
  final VoidCallback? onEditFinance;

  const OverviewTab({
    super.key,
    required this.tournament,
    required this.teamCount,
    required this.resolveImageUrl,
    this.onNavigateToIntro,
    this.isFollowing = false,
    this.onToggleFollow,
    this.inviteCode,
    this.hasSliverBanner = false,
    this.onEditGeneral,
    this.onEditBranding,
    this.onEditVenues,
    this.onEditRegistration,
    this.onEditFinance,
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

  Widget _editableItem({
    required Key key,
    required VoidCallback? onTap,
    required String sectionLabel,
    required Widget child,
  }) {
    if (onTap == null) return child;
    final editLabel = '${AppLocalizations.of(context)!.infoEdit} $sectionLabel';
    return Semantics(
      button: true,
      label: editLabel,
      child: Tooltip(
        message: editLabel,
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: child,
        ),
      ),
    );
  }

  Widget _editIndicator(VoidCallback? onTap) => onTap == null
      ? const SizedBox.shrink()
      : const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Icon(Icons.edit_outlined, size: 14, color: AppTheme.primary),
        );

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final resolvedAvatar = widget.resolveImageUrl(t.creatorAvatarUrl);
    final creatorName = (t.creatorFullName ?? '').trim();
    final isClubLite = t.isClubLite;
    final locationStr = TournamentLocationFormatter.tournamentFullLocation(t);
    final sportKey = t.sport.trim().toLowerCase();
    final categoryName = t.category?.trim();
    final sportName = categoryName != null && categoryName.isNotEmpty
        ? categoryName
        : AppConstants.sportNames[sportKey] ?? t.sport;
    final venueName = t.venueName?.trim();
    final locationTitle = venueName != null && venueName.isNotEmpty
        ? venueName
        : (locationStr.isNotEmpty
              ? locationStr.split(',').first.trim()
              : 'Đang cập nhật');
    final locationSubtitle = locationStr.isNotEmpty
        ? locationStr.split(',').last.trim()
        : 'Việt Nam';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. BANNER TRÀN VIỀN (Hiển thị nếu không dùng SliverBanner và không phải Siêu Lite) ───
          if (!isClubLite && !widget.hasSliverBanner)
            SizedBox(
              height: 195,
              width: double.infinity,
              child: _editableItem(
                key: const ValueKey('tournament-overview-banner-edit'),
                onTap: widget.onEditBranding,
                sectionLabel: l10n.tournamentManagementBranding,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildBannerView(t),
                    if (widget.onEditBranding != null)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.bgCard.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // ─── 2. NỘI DUNG TỔNG QUAN ───
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              (isClubLite || widget.hasSliverBanner) ? 16 : 14,
              16,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t.isRanked) ...[
                  _buildRankingBadge(true),
                  const SizedBox(height: 12),
                ],

                // Tên giải đấu lớn & nổi bật (ở ngoài card, tạo visual hierarchy mạnh mẽ)
                _editableItem(
                  key: const ValueKey('tournament-overview-name-edit'),
                  onTap: widget.onEditGeneral,
                  sectionLabel: l10n.tournamentManagementGeneral,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                            letterSpacing: -0.3,
                            height: 1.25,
                          ),
                        ),
                      ),
                      _editIndicator(widget.onEditGeneral),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ─── SUMMARY METRICS ROW (Flat columns with dividers) ───
                Row(
                  children: [
                    // Metric 1: Thời gian
                    Expanded(
                      child: _editableItem(
                        key: const ValueKey('tournament-overview-dates-edit'),
                        onTap: widget.onEditGeneral,
                        sectionLabel: l10n.tournamentManagementGeneral,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                    color: AppTheme.primary,
                                  ),
                                  _editIndicator(widget.onEditGeneral),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (t.startDate != null && t.endDate != null)
                                    ? '${t.startDate!.day} - ${t.endDate!.day}'
                                    : (t.startDate != null
                                          ? '${t.startDate!.day}'
                                          : '--'),
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
                    ),
                    Container(width: 1, height: 82, color: colors.border),

                    // Metric 2: Môn thể thao (centered)
                    Expanded(
                      child: Container(
                        key: const ValueKey('tournament-overview-sport-card'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SportChoiceTile.buildSportIcon(
                              sportKey,
                              22,
                              AppTheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              sportName,
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
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 82, color: colors.border),

                    // Metric 3: Vận động viên
                    Expanded(
                      child: _editableItem(
                        key: const ValueKey(
                          'tournament-overview-athletes-edit',
                        ),
                        onTap: widget.onEditRegistration,
                        sectionLabel: l10n.tournamentManagementRegistration,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.groups_rounded,
                                    size: 20,
                                    color: AppTheme.primary,
                                  ),
                                  _editIndicator(widget.onEditRegistration),
                                ],
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
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: colors.border),
                _editableItem(
                  key: const ValueKey('tournament-overview-location-edit'),
                  onTap: widget.onEditVenues,
                  sectionLabel: l10n.tournamentManagementVenues,
                  child: Container(
                    key: const ValueKey('tournament-overview-location-card'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 20,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                locationTitle,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                locationSubtitle,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: colors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _editIndicator(widget.onEditVenues),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: colors.border),

                // ─── ENTRY FEE ROW ───
                _editableItem(
                  key: const ValueKey('tournament-overview-entry-fee-edit'),
                  onTap: widget.onEditFinance,
                  sectionLabel: l10n.tournamentManagementFinance,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.payments_outlined,
                                  size: 16,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lệ phí giải',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if ((t.entryFee ?? 0) > 0)
                                      Text(
                                        'Thanh toán trực tiếp / QR',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: colors.textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatCurrency(t.entryFee),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: (t.entryFee != null && t.entryFee! > 0)
                                ? const Color(0xFFE11D48)
                                : const Color(0xFF10B981),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        _editIndicator(widget.onEditFinance),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: colors.border),
                const SizedBox(height: 14),

                if (t.description.trim().isNotEmpty) ...[
                  _editableItem(
                    key: const ValueKey('tournament-overview-description-edit'),
                    onTap: widget.onEditGeneral,
                    sectionLabel: l10n.tournamentManagementGeneral,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Giới thiệu',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            _editIndicator(widget.onEditGeneral),
                          ],
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                // Đếm ngược (nếu có - tinh tế, tinh gọn)
                if (_countdownLabel.isNotEmpty &&
                    _remainingTime > Duration.zero) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                        Flexible(
                          child: Text(
                            '$_countdownLabel: ${_formatDuration(_remainingTime)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Organizer management is available from the header when permitted.

                // Trận đấu vẫn hiển thị trong tab Lịch thi đấu.

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

                // ─── 3. LỘ TRÌNH GIẢI ĐẤU ───
                if (!isClubLite &&
                    (t.registrationStartDate != null ||
                        t.registrationEndDate != null ||
                        t.startDate != null)) ...[
                  _editableItem(
                    key: const ValueKey('tournament-overview-timeline-edit'),
                    onTap: widget.onEditGeneral,
                    sectionLabel: l10n.tournamentManagementGeneral,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSectionHeader('LỘ TRÌNH GIẢI ĐẤU'),
                            ),
                            _editIndicator(widget.onEditGeneral),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTimelineItem(
                                title: 'Mở đăng ký',
                                subtitle: _formatDate(t.registrationStartDate),
                                isFirst: true,
                                isLast: false,
                                isPassed:
                                    t.registrationStartDate != null &&
                                    DateTime.now().isAfter(
                                      t.registrationStartDate!,
                                    ),
                              ),
                              _buildTimelineItem(
                                title: 'Hạn chót đăng ký',
                                subtitle: _formatDate(t.registrationEndDate),
                                isFirst: false,
                                isLast: false,
                                isPassed:
                                    t.registrationEndDate != null &&
                                    DateTime.now().isAfter(
                                      t.registrationEndDate!,
                                    ),
                              ),
                              _buildTimelineItem(
                                title: 'Khai mạc thi đấu',
                                subtitle: _formatDate(t.startDate),
                                isFirst: false,
                                isLast: true,
                                isPassed:
                                    t.startDate != null &&
                                    DateTime.now().isAfter(t.startDate!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Keep organizer identity separate from the removed management notice.
                if (resolvedAvatar.isNotEmpty || creatorName.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildSectionHeader('BAN TỔ CHỨC GIẢI ĐẤU'),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
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
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        width: double.infinity,
        color: isDark ? const Color(0xFF16233A) : const Color(0xFFE8EEFB),
        child: const SportoBrandFallback(
          withTagline: true,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
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
          errorBuilder: (ctx, err, stack) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              width: double.infinity,
              color: isDark ? const Color(0xFF16233A) : const Color(0xFFE8EEFB),
              child: const SportoBrandFallback(
                withTagline: true,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                semanticsLabel: 'SportO tournament fallback banner',
              ),
            );
          },
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
    final dotColor = isPassed
        ? AppTheme.primary
        : colors.textMuted.withValues(alpha: 0.4);

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
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isPassed
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isPassed ? colors.textPrimary : colors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPassed
                            ? AppTheme.primary
                            : colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
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
