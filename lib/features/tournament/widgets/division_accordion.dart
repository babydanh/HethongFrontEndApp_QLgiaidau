import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/bracket_format_icons.dart';

/// Danh sách hạng mục gọn dùng chung cho các tab chi tiết giải (Đang diễn ra,
/// Kết quả, Đội, Bảng đấu): vạch chọn · icon thể thức · tên · số đội · mũi tên.
/// Bấm hàng đang chọn thì thu/mở; nội dung của hạng mục mở ngay dưới hàng.
///
/// Trạng thái chọn/mở do màn cha giữ để các tab dùng chung một lựa chọn.
class DivisionAccordion extends StatelessWidget {
  const DivisionAccordion({
    super.key,
    required this.divisions,
    required this.selectedDivisionId,
    required this.expanded,
    required this.onTapDivision,
    this.fallbackBracketType,
    this.isCompleted = false,
    this.contentBuilder,
    this.badgeBuilder,
  });

  final List<TournamentDivision> divisions;
  final String? selectedDivisionId;

  /// Hạng mục đang chọn có đang mở nội dung không.
  final bool expanded;
  final ValueChanged<TournamentDivision> onTapDivision;
  final String? fallbackBracketType;

  /// Giải đã kết thúc: mọi hạng mục coi như đủ (hiện dấu tích).
  final bool isCompleted;

  /// Nội dung mở dưới hàng đang chọn. Null thì hàng chỉ để chọn, không có mũi tên.
  final Widget Function(TournamentDivision division)? contentBuilder;

  /// Nhãn phụ cạnh tên (vd. số trận đang diễn ra). Null = không có.
  final Widget? Function(TournamentDivision division)? badgeBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? const Duration(milliseconds: 1)
        : const Duration(milliseconds: 220);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < divisions.length; index++) ...[
            _row(context, divisions[index]),
            AnimatedSize(
              key: ValueKey('division-content-${divisions[index].id}'),
              duration: duration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child:
                  divisions[index].id == selectedDivisionId &&
                      expanded &&
                      contentBuilder != null
                  ? contentBuilder!(divisions[index])
                  : const SizedBox(width: double.infinity),
            ),
            if (index < divisions.length - 1)
              Divider(height: 1, thickness: 1, color: colors.border),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, TournamentDivision division) {
    final colors = context.colors;
    final isSelected = division.id == selectedDivisionId;
    final maxP = division.maxParticipants ?? 0;
    final curP = division.participantCount;
    final countLabel = maxP > 0 ? '$curP/$maxP' : '$curP';
    final isFull = (maxP > 0 && curP >= maxP) || isCompleted;
    final badge = badgeBuilder?.call(division);
    final accent = isSelected ? AppTheme.primary : colors.textMuted;

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '${division.name}, $countLabel',
        child: InkWell(
          onTap: () => onTapDivision(division),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.12)
                          : colors.bgSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: BracketFormatIcons.getIcon(
                        division.bracketType,
                        fallbackBracketType: fallbackBracketType,
                        size: 15,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      division.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? AppTheme.primary
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  if (badge != null) ...[const SizedBox(width: 6), badge],
                  const Spacer(),
                  if (isFull) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 7),
                  ],
                  Icon(
                    Icons.people_alt_outlined,
                    size: 13,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    countLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  if (contentBuilder != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isSelected && expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: colors.textMuted,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
