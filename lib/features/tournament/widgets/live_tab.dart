import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/live_match_card_v2.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';

class LiveTab extends StatefulWidget {
  final List<MatchModel> liveMatches;
  final List<TournamentDivision> divisions;
  final String? selectedDivisionId;
  final ValueChanged<TournamentDivision>? onSelectDivision;

  const LiveTab({
    super.key,
    required this.liveMatches,
    this.divisions = const [],
    this.selectedDivisionId,
    this.onSelectDivision,
  });

  @override
  State<LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends State<LiveTab> {
  String? _expandedDivisionId;

  @override
  void initState() {
    super.initState();
    _expandedDivisionId = widget.selectedDivisionId ??
        (widget.divisions.isNotEmpty ? widget.divisions.first.id : null);
  }

  @override
  void didUpdateWidget(covariant LiveTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDivisionId != oldWidget.selectedDivisionId &&
        widget.selectedDivisionId != null) {
      setState(() {
        _expandedDivisionId = widget.selectedDivisionId;
      });
    }
  }

  IconData _getFormatIcon(String? bracketType) {
    final type = (bracketType ?? '').toUpperCase();
    if (type.contains('ROUND_ROBIN') || type.contains('ROBIN') || type.contains('VÒNG TRÒN')) {
      return Icons.sync_rounded;
    }
    if (type.contains('GROUP_STAGE') || type.contains('GROUP') || type.contains('BẢNG')) {
      return Icons.alt_route_rounded;
    }
    if (type.contains('DOUBLE_ELIMINATION') || type.contains('DOUBLE_ELIM') || type.contains('NHÁNH KÉP')) {
      return Icons.call_split_rounded;
    }
    return Icons.account_tree_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (widget.liveMatches.isEmpty && widget.divisions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.bgSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.radio_outlined,
                size: 26,
                color: colors.textMuted.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Không có trận nào đang diễn ra',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Các trận trực tiếp sẽ hiện ở đây khi bắt đầu',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Nếu có nhiều divisions (nội dung thi đấu), render danh sách division và danh sách trận đấu inline ngay dưới từng division
    if (widget.divisions.length > 1) {
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
        itemCount: widget.divisions.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _LiveHeaderBanner(count: widget.liveMatches.length),
            );
          }

          final div = widget.divisions[index - 1];
          final isExpanded = _expandedDivisionId == div.id;
          final maxP = div.maxParticipants ?? 0;
          final curP = div.participantCount;
          final isFull = maxP > 0 && curP >= maxP;
          final formatIcon = _getFormatIcon(div.bracketType);

          // Lọc các trận live thuộc division này
          final divLiveMatches = widget.liveMatches.where((m) {
            final mDiv = m.scoreDetails?['division_id']?.toString() ??
                m.tournamentConfig?['division_id']?.toString();
            if (mDiv != null && mDiv.isNotEmpty) {
              return mDiv == div.id;
            }
            return true;
          }).toList();

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Container Division Card tràn viền phẳng nhẹ nhàng
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _expandedDivisionId = isExpanded ? null : div.id;
                      });
                      widget.onSelectDivision?.call(div);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? AppTheme.primary.withValues(alpha: 0.10)
                            : colors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isExpanded
                                  ? AppTheme.primary
                                  : AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              formatIcon,
                              size: 16,
                              color: isExpanded ? Colors.white : AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  div.name,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isExpanded ? FontWeight.w800 : FontWeight.w600,
                                    color: isExpanded ? AppTheme.primary : colors.textPrimary,
                                  ),
                                ),
                                if (div.matchType.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    div.matchType == 'DOUBLES' ? 'Đánh Đôi' : 'Đánh Đơn',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isFull) ...[
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colors.bgSurface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: colors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_alt_outlined,
                                size: 13,
                                color: colors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                maxP > 0 ? '$curP/$maxP' : '$curP',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: isExpanded ? AppTheme.primary : colors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Danh sách trận đấu MỞ RA NGAY BÊN DƯỚI NỘI DUNG ĐÓ
                if (isExpanded) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: divLiveMatches.isNotEmpty
                        ? Column(
                            children: divLiveMatches.map((match) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: LiveMatchCardV2(
                                  match: match,
                                  isLive: true,
                                  onTap: () {
                                    context.push(
                                      '/tournaments/${match.tournamentId}/matches/${match.id}/official-score',
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          )
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                            decoration: BoxDecoration(
                              color: colors.bgSurface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: colors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Chưa có trận nào đang đấu ở nội dung này',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    }

    // Khi chỉ có 1 division hoặc không có divisions
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
      itemCount: widget.liveMatches.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _LiveHeaderBanner(count: widget.liveMatches.length),
          );
        }

        final match = widget.liveMatches[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: LiveMatchCardV2(
            match: match,
            isLive: true,
            onTap: () {
              context.push(
                '/tournaments/${match.tournamentId}/matches/${match.id}/official-score',
              );
            },
          ),
        );
      },
    );
  }
}

// Header banner đỏ chuẩn web: icon pulse + title + count
class _LiveHeaderBanner extends StatefulWidget {
  final int count;
  const _LiveHeaderBanner({required this.count});

  @override
  State<_LiveHeaderBanner> createState() => _LiveHeaderBannerState();
}

class _LiveHeaderBannerState extends State<_LiveHeaderBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Pulse dot icon
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  const Color(0xFFEF4444),
                  const Color(0xFFF87171),
                  _pulse.value,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(
                      alpha: _pulse.value * 0.35,
                    ),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Đang diễn ra trực tiếp',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.count}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ấn vào từng trận để xem chi tiết',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
