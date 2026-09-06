import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_tournament_roster_widget.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/bracket_format_icons.dart';

class OverviewTab extends StatefulWidget {
  final Tournament tournament;
  final int teamCount;
  final String Function(String? url) resolveImageUrl;
  final VoidCallback? onNavigateToMatches;
  final void Function(TournamentDivision division)? onSelectDivision;
  final bool isFollowing;
  final VoidCallback? onToggleFollow;
  final String? inviteCode;

  const OverviewTab({
    super.key,
    required this.tournament,
    required this.teamCount,
    required this.resolveImageUrl,
    this.onNavigateToMatches,
    this.onSelectDivision,
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
  String? _expandedDivisionId;

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

  final GlobalKey _divisionsKey = GlobalKey();


  String _getBracketFormatLabel(String? bracketType, [String? fallbackBracketType]) {
    return BracketFormatIcons.getFormatLabel(
      context,
      bracketType,
      fallbackBracketType,
    );
  }

  void _scrollToDivisions() {
    final targetContext = _divisionsKey.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
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
    final isFootball = sportStr.contains('bóng đá') || sportStr.contains('football');

    if (isFootball) {
      return l10n.tournamentCategoryFootballMen;
    }
    final isDoubles = formatStr.contains('doubles') || formatStr.contains('đôi');
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

    String dateRangeStr;
    if (isClubLite) {
      if (t.startDate != null) {
        final dateStr = _formatDate(t.startDate);
        final hour = t.startDate!.hour;
        final minute = t.startDate!.minute;
        final timeStr = (hour != 0 || minute != 0)
            ? ' · ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'
            : '';

        String durationStr = '';
        if (t.endDate != null && t.endDate!.isAfter(t.startDate!)) {
          final diffMinutes = t.endDate!.difference(t.startDate!).inMinutes;
          if (diffMinutes > 0 && diffMinutes < 24 * 60) {
            final h = diffMinutes ~/ 60;
            final m = diffMinutes % 60;
            durationStr = h > 0 ? (m > 0 ? ' (${h}h${m}p)' : ' (${h}h)') : ' (${m}p)';
          }
        }
        dateRangeStr = '$dateStr$timeStr$durationStr';
      } else {
        dateRangeStr = 'Chưa cập nhật thời gian';
      }
    } else {
      dateRangeStr = (t.startDate != null && t.endDate != null)
          ? '${_formatDate(t.startDate)} - ${_formatDate(t.endDate)}'
          : (t.startDate != null
              ? _formatDate(t.startDate)
              : 'Chưa cập nhật thời gian');
    }
    final locationStr = TournamentLocationFormatter.tournamentFullLocation(t);
    final desc = t.description.trim();
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
                // Badges + Thể thức + Ban tổ chức (Responsive Wrap Layout để không bao giờ bị overflow)
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
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDBEAFE), width: 0.8),
                          ),
                          child: Text(
                            _resolveFormatBadge(t),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        _buildStatusBadge(t.status),
                        if (t.isRanked) _buildRankingBadge(true),
                      ],
                    ),
                    if (!hasCustomLogo && (resolvedAvatar.isNotEmpty || creatorName.isNotEmpty))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
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
                                  fontSize: 11.5,
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

                // Thông tin nhanh (Thời gian, Địa điểm, Lệ phí)
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
                const SizedBox(height: 6),
                _buildInlineInfo(
                  icon: Icons.payments_outlined,
                  label: 'Lệ phí:',
                  value: _formatCurrency(t.entryFee),
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

                // ─── Banner Quản lý giải đấu dành riêng cho Ban Tổ Chức (Chuẩn Web) ───
                Consumer(
                  builder: (context, ref, _) {
                    final authState = ref.watch(authProvider);
                    final userProfile = ref.watch(userProfileProvider).value;
                    final isCreator = userProfile != null &&
                        userProfile.id.isNotEmpty &&
                        userProfile.id == t.creatorId;
                    final canManage = authState.isAdmin ||
                        authState.isOrganizer ||
                        isCreator;

                    if (!canManage) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
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
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: AppTheme.primary,
                              size: 22,
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
                                  t.isLite
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
                              if (t.isLite) {
                                context.push('/lite-manage/${t.id}');
                              } else {
                                context.push('/organizer/tournaments/${t.id}/ops');
                              }
                            },
                            icon: const Icon(Icons.settings_suggest_rounded, size: 16),
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

                // Action Buttons (Hiển thị cho giải truyền thống / nâng cao / công khai)
                if (!isClubLite) ...[
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
                            'Lịch thi đấu',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      if (t.divisions.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: BorderSide(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _scrollToDivisions,
                          icon: const Icon(
                            Icons.layers_outlined,
                            size: 16,
                          ),
                          label: const Text(
                            'Nội dung',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          side: BorderSide(color: colors.border),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
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
                ],

                // ─── LƯỚI XÁC NHẬN THAM GIA 16/32 SLOT (ĐỒNG BỘ CHUẨN WEB) ───
                if (isClubLite || ((t.communityId != null && t.communityId!.isNotEmpty) && (t.isLite || t.divisions.isEmpty || t.divisions.length <= 1))) ...[
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
                  const SizedBox(height: 12),
                ],

                // ─── 3. DANH SÁCH NỘI DUNG / PHÂN HẠNG THI ĐẤU (CHUẨN WEB & TASTE SKILL) ───
                if (!isClubLite && t.divisions.isNotEmpty) ...[
                  KeyedSubtree(
                    key: _divisionsKey,
                    child: _buildSectionHeader('NỘI DUNG THI ĐẤU (${t.divisions.length})'),
                  ),
                  const SizedBox(height: 10),
                  ...t.divisions.map((div) => _buildDivisionItem(div, colors)),
                  const SizedBox(height: 20),
                  Divider(color: colors.border.withValues(alpha: 0.6), height: 1),
                  const SizedBox(height: 16),
                ],

                // ─── 4. THÔNG TIN ĐĂNG KÝ & LỆ PHÍ ───
                if (!isClubLite) ...[
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
                ],

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
                if (!isClubLite &&
                    t.prizeDescription != null &&
                    t.prizeDescription!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Divider(color: colors.border.withValues(alpha: 0.6), height: 1),
                  const SizedBox(height: 16),
                  _buildSectionHeader('CƠ CẤU GIẢI THƯỞNG'),
                  const SizedBox(height: 10),
                  _buildDescriptionContent(t.prizeDescription!),
                ],

                // ─── 7. NGƯỜI SÁNG LẬP GIẢI ĐẤU (ĐẶT Ở CUỐI KHI GIẢI CÓ LOGO) ───
                if (hasCustomLogo && (resolvedAvatar.isNotEmpty || creatorName.isNotEmpty)) ...[
                  const SizedBox(height: 20),
                  Divider(color: colors.border.withValues(alpha: 0.6), height: 1),
                  const SizedBox(height: 16),
                  _buildSectionHeader('NGƯỜI SÁNG LẬP GIẢI ĐẤU'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border.withValues(alpha: 0.7)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          backgroundImage: resolvedAvatar.isNotEmpty
                              ? NetworkImage(resolvedAvatar)
                              : null,
                          child: resolvedAvatar.isEmpty
                              ? Text(
                                  creatorName.isNotEmpty ? creatorName[0].toUpperCase() : 'B',
                                  style: TextStyle(
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                'Ban tổ chức giải đấu',
                                style: TextStyle(
                                  fontSize: 11.5,
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

  Widget _buildDivisionItem(TournamentDivision div, AppColorsExtension colors) {
    final displayName = widget.tournament.isClubLite
        ? (div.matchType == 'DOUBLES' ? 'Đôi' : 'Đơn')
        : div.name;
    final maxP = div.maxParticipants ?? 0;
    final curP = div.participantCount;
    final isFull = maxP > 0 && curP >= maxP;
    final isExpanded = _expandedDivisionId == div.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded ? AppTheme.primary : colors.border.withValues(alpha: 0.7),
          width: isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedDivisionId = isExpanded ? null : div.id;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Ô icon thể thức thi đấu (chuẩn Web getBracketFormatIcon)
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? AppTheme.primary
                          : AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isExpanded
                            ? AppTheme.primary
                            : AppTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: BracketFormatIcons.getIcon(
                        div.bracketType,
                        fallbackBracketType: widget.tournament.bracketType,
                        size: 18,
                        color: isExpanded ? Colors.white : AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isExpanded ? AppTheme.primary : colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getBracketFormatLabel(div.bracketType, widget.tournament.bracketType),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isFull) ...[
                    // Badge Đã kết thúc / Đã đủ theo style Muted Web
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 11,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            'Đã kết thúc',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
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
                        maxP > 0 ? '$curP/$maxP' : '$curP VĐV',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: isExpanded ? AppTheme.primary : colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(color: colors.border.withValues(alpha: 0.5), height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInlineInfo(
                    icon: Icons.sports_score_rounded,
                    label: 'Thể thức:',
                    value: _getBracketFormatLabel(div.bracketType, widget.tournament.bracketType),
                    colors: colors,
                  ),
                  const SizedBox(height: 6),
                  _buildInlineInfo(
                    icon: Icons.people_outline_rounded,
                    label: 'Định dạng:',
                    value: div.matchType == 'DOUBLES' ? 'Đánh Đôi' : 'Đánh Đơn',
                    colors: colors,
                  ),
                  if (div.genderRestriction != null && div.genderRestriction!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildInlineInfo(
                      icon: Icons.wc_rounded,
                      label: 'Giới tính:',
                      value: div.genderRestriction!,
                      colors: colors,
                    ),
                  ],
                  const SizedBox(height: 6),
                  _buildInlineInfo(
                    icon: Icons.group_outlined,
                    label: 'Quy mô:',
                    value: maxP > 0 ? '$curP / $maxP VĐV (đội)' : '$curP VĐV',
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (widget.onSelectDivision != null) {
                          widget.onSelectDivision!(div);
                        }
                      },
                      icon: const Icon(Icons.account_tree_outlined, size: 16),
                      label: const Text(
                        'Xem Bảng đấu phân hạng này',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final l10n = AppLocalizations.of(context)!;
    final label = StatusHelper.getTournamentStatusLabel(status, l10n: l10n);
    final bg = StatusHelper.getTournamentStatusColor(status, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
