import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Block under the video on the viewer live screen: bold title, one muted
/// info line (viewers · tournament link · round · "Details" link) and two pill
/// actions (cheer, share). Report lives in the details sheet.
class LiveViewerHeader extends StatelessWidget {
  const LiveViewerHeader({
    super.key,
    required this.title,
    required this.cheerCount,
    required this.onCheer,
    required this.onShare,
    required this.onMore,
    this.viewersLabel,
    this.roundLabel,
    this.tournamentLabel,
    this.onOpenTournament,
  });

  final String title;
  final int cheerCount;
  final VoidCallback onCheer;
  final VoidCallback onShare;
  final VoidCallback onMore;
  final String? viewersLabel;
  final String? roundLabel;
  final String? tournamentLabel;
  final VoidCallback? onOpenTournament;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final infoStyle = TextStyle(fontSize: 12, color: muted);
    final linkStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: scheme.primary,
    );
    final tournament = tournamentLabel?.trim() ?? '';
    final viewers = viewersLabel?.trim() ?? '';
    final round = roundLabel?.trim() ?? '';

    // Parts are joined with " · "; empty parts are skipped.
    final parts = <Widget>[
      if (viewers.isNotEmpty) Text(viewers, style: infoStyle),
      if (tournament.isNotEmpty)
        _InfoLink(
          label: tournament,
          style: linkStyle,
          onTap: onOpenTournament,
        ),
      if (round.isNotEmpty) Text(round, style: infoStyle),
      _InfoLink(label: l10n.liveViewerMore, style: linkStyle, onTap: onMore),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < parts.length; i++) ...[
                if (i > 0) Text(' · ', style: infoStyle),
                parts[i],
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Pill(
                icon: Icons.favorite_border,
                label: l10n.liveCheerLabel,
                trailing: cheerCount > 0 ? '$cheerCount' : null,
                highlighted: true,
                onTap: onCheer,
              ),
              const SizedBox(width: 8),
              _Pill(
                icon: Icons.share_outlined,
                label: l10n.liveShareAction,
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tappable text in the info line; plain text when [onTap] is null.
class _InfoLink extends StatelessWidget {
  const _InfoLink({required this.label, required this.style, this.onTap});

  final String label;
  final TextStyle style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: onTap == null ? style.copyWith(fontWeight: FontWeight.w500) : style,
    );
    if (onTap == null) return text;
    return InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: text),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = highlighted ? scheme.primary : scheme.onSurface;
    return Material(
      color: highlighted
          ? scheme.primary.withValues(alpha: 0.14)
          : scheme.onSurface.withValues(alpha: 0.08),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 5),
                Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
