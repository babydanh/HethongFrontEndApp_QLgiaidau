import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter/material.dart';

/// One set pill in the "set scores" strip.
class LiveSetChipData {
  const LiveSetChipData({required this.label, this.current = false});

  final String label;

  /// The set being played right now (drawn red like the LIVE accent).
  final bool current;
}

/// One side of the head-to-head ELO card.
class LiveEloSideData {
  const LiveEloSideData({
    required this.name,
    required this.elo,
    this.athletes = '',
  });

  final String name;
  final String elo;

  /// Athlete names ("A / B"); shown under [name] when they add information.
  final String athletes;
}

/// One icon + text line of the info list; tappable when [onTap] is set.
class LiveInfoRowData {
  const LiveInfoRowData({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
}

/// "Match details" bottom sheet of the viewer live screen (YouTube-style
/// description sheet): title, three headline numbers, set scores, ELO
/// head-to-head, info lines and the report action.
class LiveMatchDetailsSheet extends StatelessWidget {
  const LiveMatchDetailsSheet({
    super.key,
    required this.sheetTitle,
    required this.matchTitle,
    required this.stats,
    required this.setsTitle,
    required this.sets,
    required this.eloTitle,
    required this.sideA,
    required this.sideB,
    required this.rows,
    required this.reportLabel,
    required this.closeTooltip,
    required this.onClose,
    required this.onReport,
    this.scrollController,
    this.extra,
  });

  final String sheetTitle;
  final String matchTitle;

  /// Exactly the headline numbers, each as (value, caption).
  final List<({String value, String caption})> stats;
  final String setsTitle;
  final List<LiveSetChipData> sets;
  final String eloTitle;
  final LiveEloSideData sideA;
  final LiveEloSideData sideB;
  final List<LiveInfoRowData> rows;
  final String reportLabel;
  final String closeTooltip;
  final VoidCallback onClose;
  final VoidCallback onReport;
  final ScrollController? scrollController;

  /// Optional block under the info lines (e.g. the penalty log).
  final Widget? extra;

  static const _minTap = 48.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final danger = dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);

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
                Text(
                  matchTitle,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                _StatsRow(stats: stats),
                if (sets.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _SectionLabel(setsTitle),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final s in sets) _SetChip(data: s)],
                  ),
                ],
                const SizedBox(height: 18),
                _SectionLabel(eloTitle),
                _EloCard(a: sideA, b: sideB),
                const SizedBox(height: 14),
                for (final row in rows) _InfoRow(data: row, minHeight: _minTap),
                ?extra,
                const SizedBox(height: 6),
                InkWell(
                  onTap: onReport,
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: _minTap),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Icon(
                            Icons.flag_outlined,
                            size: 20,
                            color: danger,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          reportLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: danger,
                          ),
                        ),
                      ],
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final List<({String value, String caption})> stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (final s in stats)
          Expanded(
            child: Column(
              children: [
                Text(
                  s.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: context.colors.textSecondary,
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.withValues(alpha: 0.55)),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}

class _EloCard extends StatelessWidget {
  const _EloCard({required this.a, required this.b});

  final LiveEloSideData a;
  final LiveEloSideData b;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _EloSide(data: a, end: false)),
          Container(
            width: 1,
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: colors.border,
          ),
          Expanded(child: _EloSide(data: b, end: true)),
        ],
      ),
    );
  }
}

/// Headline (team or athletes), athletes under a team name, then the ELO.
class _EloSide extends StatelessWidget {
  const _EloSide({required this.data, required this.end});

  final LiveEloSideData data;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final align = end ? TextAlign.end : TextAlign.start;
    return Column(
      crossAxisAlignment: end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          data.name,
          textAlign: align,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        if (data.athletes.isNotEmpty && data.athletes != data.name) ...[
          const SizedBox(height: 3),
          Text(
            data.athletes,
            textAlign: align,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.3,
              color: colors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          data.elo,
          textAlign: align,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
      ],
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
          SizedBox(
            width: 28,
            child: Icon(data.icon, size: 20, color: colors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                fontWeight: link ? FontWeight.w700 : FontWeight.w500,
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
