import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Tên hiển thị của VĐV ở [index] trong đội; thiếu tên thì dùng "VĐV n".
String courtPlayerDisplayName(
  List<String> players,
  int index,
  AppLocalizations l10n,
) {
  if (index >= 0 && index < players.length) {
    final name = players[index].trim();
    if (name.isNotEmpty) return name;
  }
  return l10n.pickleballCourtPlayerLabel(index + 1);
}

/// Sơ đồ sân pickleball: hai nửa sân ngăn bởi lưới, mỗi nửa có ô phải và ô trái.
/// Chỉ vẽ từ [CourtLayout]; không chứa logic luật.
class PickleballCourtView extends StatelessWidget {
  const PickleballCourtView({
    super.key,
    required this.layout,
    required this.team1Players,
    required this.team2Players,
    this.onOpenSettings,
  });

  static const _courtHeight = 232.0;
  static const _motion = Duration(milliseconds: 240);

  final CourtLayout layout;
  final List<String> team1Players;
  final List<String> team2Players;

  /// Null thì ẩn nút ⚙ (người không có quyền ghi điểm).
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _motion;
    final topTeam = layout.team1First ? 1 : 2;
    final bottomTeam = 3 - topTeam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.pickleballCourtTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onOpenSettings != null)
              IconButton(
                tooltip: l10n.pickleballCourtSettings,
                onPressed: onOpenSettings,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: Icon(Icons.settings_outlined, color: colors.textSecondary),
              ),
          ],
        ),
        AnimatedSwitcher(
          duration: motion,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: _CourtSurface(
            key: ValueKey(layout.team1First),
            layout: layout,
            topTeam: topTeam,
            bottomTeam: bottomTeam,
            topPlayers: topTeam == 1 ? team1Players : team2Players,
            bottomPlayers: bottomTeam == 1 ? team1Players : team2Players,
            motion: motion,
            l10n: l10n,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _summaryText(layout, l10n),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  static String _summaryText(CourtLayout layout, AppLocalizations l10n) {
    if (layout.servingTeam == null) return l10n.pickleballCourtNoServingTeam;
    final serving = layout.servingScore;
    final receiving = layout.receivingScore;
    if (serving == null || receiving == null) return '';
    final call = layout.callServerNumber;
    final score = '$serving–$receiving';
    return call == null
        ? score
        : '${l10n.pickleballCourtCallLabel}: $score–$call';
  }
}

class _CourtSurface extends StatelessWidget {
  const _CourtSurface({
    super.key,
    required this.layout,
    required this.topTeam,
    required this.bottomTeam,
    required this.topPlayers,
    required this.bottomPlayers,
    required this.motion,
    required this.l10n,
  });

  final CourtLayout layout;
  final int topTeam;
  final int bottomTeam;
  final List<String> topPlayers;
  final List<String> bottomPlayers;
  final Duration motion;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: PickleballCourtView._courtHeight,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Expanded(
            child: _CourtHalf(
              team: topTeam,
              isTopHalf: true,
              layout: layout,
              players: topPlayers,
              motion: motion,
              l10n: l10n,
            ),
          ),
          Container(height: 3, color: colors.textSecondary),
          Expanded(
            child: _CourtHalf(
              team: bottomTeam,
              isTopHalf: false,
              layout: layout,
              players: bottomPlayers,
              motion: motion,
              l10n: l10n,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourtHalf extends StatelessWidget {
  const _CourtHalf({
    required this.team,
    required this.isTopHalf,
    required this.layout,
    required this.players,
    required this.motion,
    required this.l10n,
  });

  final int team;
  final bool isTopHalf;
  final CourtLayout layout;
  final List<String> players;
  final Duration motion;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final slots = layout.slotsOf(team);
    final isServingTeam = layout.servingTeam == team;

    // Nhìn từ sân: đội nửa trên quay mặt xuống, ô phải của họ nằm bên trái
    // màn hình; đội nửa dưới ngược lại.
    final cells = isTopHalf
        ? const [CourtCell.left, CourtCell.right]
        : const [CourtCell.right, CourtCell.left];

    Widget cellFor(CourtCell cell) {
      final playerIndex = slots.playerIn(cell);
      final isServing =
          isServingTeam &&
          layout.serverCell == cell &&
          layout.serverPlayerIndex != null &&
          playerIndex == layout.serverPlayerIndex;
      return Expanded(
        child: _CourtCellTile(
          cell: cell,
          playerIndex: playerIndex,
          playerName: playerIndex == null
              ? null
              : courtPlayerDisplayName(players, playerIndex, l10n),
          isServing: isServing,
          motion: motion,
          l10n: l10n,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              team == 1 ? l10n.pickleballTeam1 : l10n.pickleballTeam2,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              cellFor(cells[0]),
              Container(width: 1, color: colors.borderLight),
              cellFor(cells[1]),
            ],
          ),
        ),
      ],
    );
  }
}

class _CourtCellTile extends StatelessWidget {
  const _CourtCellTile({
    required this.cell,
    required this.playerIndex,
    required this.playerName,
    required this.isServing,
    required this.motion,
    required this.l10n,
  });

  final CourtCell cell;
  final int? playerIndex;
  final String? playerName;
  final bool isServing;
  final Duration motion;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final cellLabel = cell == CourtCell.right
        ? l10n.pickleballCourtRightCell
        : l10n.pickleballCourtLeftCell;
    final name = playerName;
    final semanticsLabel = name == null
        ? cellLabel
        : isServing
        ? '$cellLabel: $name, ${l10n.pickleballServing}'
        : '$cellLabel: $name';

    return Semantics(
      label: semanticsLabel,
      child: AnimatedContainer(
        duration: motion,
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isServing
              ? AppTheme.primary.withValues(alpha: 0.16)
              : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isServing ? AppTheme.primary : colors.borderLight,
            width: isServing ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (name != null)
              CircleAvatar(
                radius: 16,
                backgroundColor: isServing
                    ? AppTheme.primary
                    : colors.chipBackground,
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: isServing ? scheme.onPrimary : colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Text(
                '—',
                style: TextStyle(color: colors.textMuted, fontSize: 18),
              ),
            const SizedBox(height: 4),
            Text(
              name ?? cellLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: name == null ? colors.textMuted : colors.textPrimary,
                fontWeight: isServing ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
