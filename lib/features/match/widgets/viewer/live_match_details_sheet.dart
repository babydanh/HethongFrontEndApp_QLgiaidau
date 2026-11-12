import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_side_avatars.dart';
import 'package:flutter/material.dart';

/// One set pill in the "set scores" strip.
class LiveSetChipData {
  const LiveSetChipData({required this.label, this.current = false});

  final String label;

  /// The set being played right now (drawn red like the LIVE accent).
  final bool current;
}

/// One side of the match head of the details sheet.
class LiveEloSideData {
  const LiveEloSideData({
    required this.name,
    this.elo,
    this.athletes = '',
    this.avatars = const [],
  });

  final String name;

  /// Shown under the name only when there is a number ("1500").
  final String? elo;

  /// Athlete names ("A / B"); shown under [name] when they add information.
  final String athletes;

  /// One avatar for a single athlete / team, two for a pair.
  final List<LiveAvatarData> avatars;
}

/// One icon + label + value line of the info list; tappable when [onTap] is
/// set. A blank [text] means "no data": the row is not drawn.
class LiveInfoRowData {
  const LiveInfoRowData({
    required this.icon,
    required this.label,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String text;
  final VoidCallback? onTap;
}

/// "Match details" bottom sheet of the viewer live screen: the score head of
/// both sides, set chips, a flat info list and a small outlined report button.
/// Anything without data (ELO, referee, penalties) is simply not drawn.
class LiveMatchDetailsSheet extends StatelessWidget {
  const LiveMatchDetailsSheet({
    super.key,
    required this.sheetTitle,
    required this.sideA,
    required this.sideB,
    required this.score1,
    required this.score2,
    required this.live,
    required this.sets,
    required this.rows,
    required this.reportLabel,
    required this.closeTooltip,
    required this.onClose,
    required this.onReport,
    this.scrollController,
    this.extra,
  });

  final String sheetTitle;
  final LiveEloSideData sideA;
  final LiveEloSideData sideB;
  final int score1;
  final int score2;

  /// Red score while the match is being played.
  final bool live;
  final List<LiveSetChipData> sets;
  final List<LiveInfoRowData> rows;
  final String reportLabel;
  final String closeTooltip;
  final VoidCallback onClose;
  final VoidCallback onReport;
  final ScrollController? scrollController;

  /// Optional block under the info lines (e.g. the penalty log).
  final Widget? extra;

  static const _minTap = 44.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final danger = dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
    final shownRows = rows.where((r) => r.text.trim().isNotEmpty).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          ExcludeSemantics(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sheetTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: closeTooltip,
                  onPressed: onClose,
                  constraints: const BoxConstraints(
                    minWidth: _minTap,
                    minHeight: _minTap,
                  ),
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.border),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                _MatchHead(
                  a: sideA,
                  b: sideB,
                  score1: score1,
                  score2: score2,
                  live: live,
                ),
                if (sets.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final s in sets) _SetChip(data: s)],
                  ),
                ],
                if (shownRows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: colors.border),
                  for (final row in shownRows)
                    _InfoRow(data: row, minHeight: _minTap),
                ],
                ?extra,
                const SizedBox(height: 12),
                Center(
                  child: InkWell(
                    onTap: onReport,
                    borderRadius: BorderRadius.circular(999),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: _minTap),
                      child: Center(
                        widthFactor: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: danger.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                size: 16,
                                color: danger,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                reportLabel,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

/// Avatar + name (+ ELO when known) on both sides, big score in the middle.
class _MatchHead extends StatelessWidget {
  const _MatchHead({
    required this.a,
    required this.b,
    required this.score1,
    required this.score2,
    required this.live,
  });

  final LiveEloSideData a;
  final LiveEloSideData b;
  final int score1;
  final int score2;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scoreColor = live ? const Color(0xFFEF4444) : colors.textPrimary;
    final scoreStyle = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w900,
      color: scoreColor,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _Side(data: a)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score1', style: scoreStyle),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '–',
                  style: TextStyle(fontSize: 22, color: colors.border),
                ),
              ),
              Text('$score2', style: scoreStyle),
            ],
          ),
        ),
        Expanded(child: _Side(data: b)),
      ],
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.data});

  final LiveEloSideData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elo = data.elo;
    return Column(
      children: [
        LiveSideAvatars(
          avatars: data.avatars.isEmpty
              ? [LiveAvatarData(name: data.name)]
              : data.avatars,
          diameter: 34,
          borderColor: colors.bgDark,
          borderWidth: 2,
          rankRing: true,
        ),
        const SizedBox(height: 4),
        Text(
          data.name,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        if (data.athletes.isNotEmpty && data.athletes != data.name)
          Text(
            data.athletes,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.25,
              color: colors.textSecondary,
            ),
          ),
        if (elo != null && elo.isNotEmpty)
          Text(
            '$elo ELO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _SetChip extends StatelessWidget {
  const _SetChip({required this.data});

  final LiveSetChipData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = data.current ? const Color(0xFFEF4444) : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.55)),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.data, required this.minHeight});

  final LiveInfoRowData data;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final link = data.onTap != null;
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Row(
        children: [
          Icon(data.icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: 10),
          Text(
            data.label,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data.text,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: link ? AppTheme.primary : colors.textPrimary,
              ),
            ),
          ),
          if (link)
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
        ],
      ),
    );
    if (!link) return row;
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(10),
      child: row,
    );
  }
}
