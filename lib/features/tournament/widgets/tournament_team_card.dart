import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/elo_tier_badge.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class TournamentTeamCard extends StatefulWidget {
  final Team team;
  final int? index;
  final bool isTeamSport;
  final Function(String? userId, String memberName)? onMemberTap;
  final bool showSeed;
  final bool isDoublesDivision;

  const TournamentTeamCard({
    super.key,
    required this.team,
    this.index,
    this.isTeamSport = false,
    this.onMemberTap,
    this.showSeed = false,
    this.isDoublesDivision = false,
  });

  @override
  State<TournamentTeamCard> createState() => _TournamentTeamCardState();
}

class _TournamentTeamCardState extends State<TournamentTeamCard> {
  /// Thông tin roster (elo, hạng) của VĐV, khớp theo userId; khách không có userId.
  MatchMemberInfo? _memberInfoFor(ParticipantPlayer player) {
    final userId = player.userId;
    if (userId == null) return null;
    for (final info in widget.team.memberInfos) {
      if (info.userId == userId) return info;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final team = widget.team;

    // Đơn/đôi theo số VĐV: players[] là chuẩn, rỗng thì fallback theo thứ tự
    // ưu tiên như matchSidePlayers (memberInfos rồi members).
    final players = team.players.isNotEmpty
        ? team.players
        : team.memberInfos.isNotEmpty
        ? participantPlayersFromMemberInfos(team.memberInfos)
        : participantPlayersFromNames(team.members);

    final seedLabel = widget.showSeed && team.seed > 0
        ? '${l10n.seedLabel} #${team.seed}'
        : null;

    final teamDisplay = resolveParticipantDisplay(
      teamName: team.name,
      players: players,
      teamOnly: widget.isTeamSport,
    );

    // Ô chờ đồng đội: đội đang PENDING_PARTNER hoặc roster thô còn thiếu một người trong hạng mục đôi
    final waitingPartner =
        team.isPendingPartner ||
        (widget.isDoublesDivision && team.members.length == 1);

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.35)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cột 1: Cột STT (#) giống bảng Web (nếu có index)
            if (widget.index != null)
              Container(
                width: 26,
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '${widget.index}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),

            // Cột 2: Nội dung Đội / Người chơi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề tên đội (khi có tên đội riêng biệt hoặc khi không có VĐV)
                  if (teamDisplay.isTeam || players.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5, top: 2),
                      child: Row(
                        children: [
                          Flexible(
                            child: ParticipantLabel(
                              teamName: team.name,
                              players: players,
                              teamOnly: widget.isTeamSport,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: colors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (seedLabel != null) ...[
                            const SizedBox(width: 6),
                            _buildSeedBadge(seedLabel),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Danh sách các vận động viên xếp dọc trực tiếp trong dòng (Flat layout giống Web)
                  if (players.isNotEmpty)
                    Column(
                      children: List.generate(players.length, (idx) {
                        final player = players[idx];
                        final mName = player.fullName;
                        final MatchMemberInfo? mInfo = _memberInfoFor(player);
                        final eloVal = mInfo?.eloPoints ?? team.eloPoints;
                        final tierStr = mInfo?.tierName;
                        final memberAvatar = player.avatarUrl ?? mInfo?.avatarUrl;
                        final isFirstItem = idx == 0;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              widget.onMemberTap?.call(player.userId, mName);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  // Avatar VĐV (RankAvatar có vòng viền tier nếu có xếp hạng)
                                  RankAvatar(
                                    imageUrl: memberAvatar,
                                    name: mName,
                                    elo: eloVal ?? 0,
                                    tierName: tierStr,
                                    size: 26,
                                    ringWidth: 1.5,
                                  ),
                                  const SizedBox(width: 8),

                                  // Tên vận động viên
                                  Expanded(
                                    child: Text(
                                      mName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Huy hiệu Tier (EloTierBadge hiển thị mã viết tắt LTD, HTD, HTC... giống Web)
                                  if (eloVal != null && eloVal > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: EloTierBadge(
                                        elo: eloVal,
                                        tierName: tierStr,
                                        scale: 0.72,
                                      ),
                                    ),

                                  // Hiển thị seed nếu không có hàng tên đội riêng
                                  if (!teamDisplay.isTeam && seedLabel != null && isFirstItem) ...[
                                    const SizedBox(width: 6),
                                    _buildSeedBadge(seedLabel),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                  // Ô chờ đồng đội tham gia (nếu là đội đôi đang thiếu người / PENDING_PARTNER)
                  if (waitingPartner) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 2),
                      child: Row(
                        children: [
                          _waitingPartnerChip(l10n),
                          const SizedBox(width: 8),
                          Text(
                            'Chờ đồng đội tham gia',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Cột 3: Trạng thái thanh toán (icon gọn gàng ở cột bên phải giống Web)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 6),
              child: _buildPaymentBadge(team),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedBadge(String seedLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: Text(
        seedLabel,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1D4ED8),
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(Team team) {
    return Tooltip(
      message: team.isPaid ? 'Đã đóng phí' : 'Chờ thanh toán',
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: team.isPaid
              ? const Color(0xFF059669).withValues(alpha: 0.12)
              : const Color(0xFFD97706).withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: team.isPaid
                ? const Color(0xFF059669).withValues(alpha: 0.4)
                : const Color(0xFFD97706).withValues(alpha: 0.4),
          ),
        ),
        child: Icon(
          team.isPaid
              ? Icons.check_circle_rounded
              : Icons.access_time_rounded,
          size: 14,
          color: team.isPaid
              ? const Color(0xFF059669)
              : const Color(0xFFD97706),
        ),
      ),
    );
  }

  /// Ô giữ chỗ cho đồng đội chưa vào: chỉ icon, chữ nằm trong tooltip.
  Widget _waitingPartnerChip(AppLocalizations l10n) {
    final label = l10n.teamStatusWaitingForPartner;
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: CustomPaint(
          painter: const _DashedPillPainter(color: Color(0xFFF59E0B)),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 13,
              color: Color(0xFFB45309),
            ),
          ),
        ),
      ),
    );
  }
}

/// Viền đứt bo tròn cho ô "Chờ đồng đội".
class _DashedPillPainter extends CustomPainter {
  const _DashedPillPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(13),
    );
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      for (double d = 0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPillPainter oldDelegate) =>
      oldDelegate.color != color;
}
