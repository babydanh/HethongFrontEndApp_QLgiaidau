import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class TournamentTeamCard extends StatefulWidget {
  final Team team;
  final bool isTeamSport;

  /// Nội dung đôi: đội chỉ có 1 người thì hiện ô "Chờ đồng đội".
  final bool isDoublesDivision;
  final Function(String? userId, String memberName)? onMemberTap;

  const TournamentTeamCard({
    super.key,
    required this.team,
    this.isTeamSport = false,
    this.isDoublesDivision = false,
    this.onMemberTap,
  });

  @override
  State<TournamentTeamCard> createState() => _TournamentTeamCardState();
}

class _TournamentTeamCardState extends State<TournamentTeamCard> {
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final team = widget.team;

    // Check if Doubles
    final isDoubles =
        widget.isTeamSport ||
        widget.isDoublesDivision ||
        team.members.length > 1 ||
        team.name.contains(' - ') ||
        team.name.contains(' / ') ||
        team.name.contains(' & ');

    // Chip thành viên chỉ lấy roster thật từ API. Không dựng tên giả từ tên
    // đội: đội chưa có roster thì không hiện chip.
    final List<String> memberNames = team.members;

    final memberInfos = team.memberInfos;

    final seedLabel = team.seed > 0 ? '${l10n.seedLabel} #${team.seed}' : null;

    if (!isDoubles) {
      // ── SINGLES (ĐƠN) LAYOUT: DIRECT PROFILE TAP, NO EXPANSION ──
      final singleInfo = memberInfos.isNotEmpty ? memberInfos.first : null;
      // VĐV khách (info không userId) không mở hồ sơ người đăng ký thay họ.
      final effectiveUserId =
          singleInfo != null ? singleInfo.userId : team.userId;
      final eloVal = singleInfo?.eloPoints ?? team.eloPoints ?? 1200;
      final eloStr = '${l10n.eloLabel} $eloVal';

      return Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.border.withValues(alpha: 0.45)),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              widget.onMemberTap?.call(effectiveUserId, team.name);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 2),

                  // Singles rows represent a real participant. Show the
                  // roster avatar when the API provides it, falling back to
                  // initials only when the profile has no image.
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                    child: singleInfo?.avatarUrl?.isNotEmpty == true
                        ? ClipOval(
                            child: Image.network(
                              singleInfo!.avatarUrl!,
                              fit: BoxFit.cover,
                              width: 36,
                              height: 36,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                    _getInitials(team.name),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                            ),
                          )
                        : Text(
                            _getInitials(team.name),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),

                  // Athlete Name + Badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFBAE6FD),
                                ),
                              ),
                              child: Text(
                                eloStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                            if (seedLabel != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
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
                              ),
                            ],
                            const SizedBox(width: 6),
                            Tooltip(
                              message: team.isPaid
                                  ? 'Đã đóng phí'
                                  : 'Chờ thanh toán',
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: team.isPaid
                                      ? const Color(
                                          0xFF059669,
                                        ).withValues(alpha: 0.12)
                                      : const Color(
                                          0xFFD97706,
                                        ).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: team.isPaid
                                        ? const Color(
                                            0xFF059669,
                                          ).withValues(alpha: 0.4)
                                        : const Color(
                                            0xFFD97706,
                                          ).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Icon(
                                  team.isPaid
                                      ? Icons.check_circle_rounded
                                      : Icons.access_time_rounded,
                                  size: 13,
                                  color: team.isPaid
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Chevron right profile indicator
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── DOUBLES (ĐÔI) LAYOUT: thành viên hiện sẵn dạng chip gọn ──
    final waitingPartner =
        team.approvalStatus.toUpperCase() == 'PENDING_PARTNER' ||
        (widget.isDoublesDivision && memberNames.length == 1);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.45)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  team.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: colors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (seedLabel != null) ...[
                const SizedBox(width: 6),
                Text(
                  seedLabel,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Tooltip(
                message: team.isPaid ? 'Đã đóng phí' : 'Chờ thanh toán',
                child: Icon(
                  team.isPaid
                      ? Icons.check_circle_rounded
                      : Icons.access_time_rounded,
                  size: 15,
                  color: team.isPaid
                      ? const Color(0xFF059669)
                      : const Color(0xFFD97706),
                ),
              ),
            ],
          ),
          if (memberNames.isNotEmpty || waitingPartner) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var idx = 0; idx < memberNames.length; idx++)
                  _memberChip(
                    context,
                    memberNames[idx],
                    _memberInfoFor(memberNames[idx], idx, memberInfos),
                  ),
                if (waitingPartner) _waitingPartnerChip(l10n),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Khớp tên với hồ sơ thành viên; không khớp thì lấy theo vị trí.
  MatchMemberInfo? _memberInfoFor(
    String name,
    int index,
    List<MatchMemberInfo> infos,
  ) {
    final key = name.trim().toLowerCase();
    for (final info in infos) {
      if (info.fullName.trim().toLowerCase() == key) return info;
    }
    return index < infos.length ? infos[index] : null;
  }

  Widget _memberChip(
    BuildContext context,
    String name,
    MatchMemberInfo? info,
  ) {
    final colors = context.colors;
    final avatar = info?.avatarUrl;
    final initials = Text(
      _getInitials(name),
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
    );
    // Hai chip vừa một hàng trên điện thoại hẹp; tên dài cắt "…".
    final maxWidth = (MediaQuery.sizeOf(context).width - 72) / 2;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth.clamp(110, 220)),
      child: Material(
        color: colors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderLight),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onTap: () => widget.onMemberTap?.call(info?.userId, name),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 3, 10, 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.14),
                  child: avatar != null && avatar.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            avatar,
                            fit: BoxFit.cover,
                            width: 22,
                            height: 22,
                            errorBuilder: (_, _, _) => initials,
                          ),
                        )
                      : initials,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 14,
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
      const Radius.circular(16),
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
