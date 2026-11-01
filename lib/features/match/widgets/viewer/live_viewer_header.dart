import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Block under the video on the viewer live screen: bold title, one muted
/// info line ending in a "more" link, and a row of pill actions.
class LiveViewerHeader extends StatelessWidget {
  const LiveViewerHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.cheerCount,
    required this.onCheer,
    required this.onShare,
    required this.onMore,
    this.tournamentLabel,
    this.onOpenTournament,
  });

  final String title;
  final String subtitle;
  final int cheerCount;
  final VoidCallback onCheer;
  final VoidCallback onShare;
  final VoidCallback onMore;
  final String? tournamentLabel;
  final VoidCallback? onOpenTournament;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final hasTournament =
        tournamentLabel != null &&
        tournamentLabel!.isNotEmpty &&
        onOpenTournament != null;

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
          Row(
            children: [
              Flexible(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onMore,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    l10n.liveViewerMore,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Pill(
                  icon: Icons.favorite_border,
                  label: l10n.liveCheerLabel,
                  trailing: cheerCount > 0 ? '$cheerCount' : null,
                  onTap: onCheer,
                ),
                const SizedBox(width: 8),
                _Pill(
                  icon: Icons.share_outlined,
                  label: l10n.liveShareAction,
                  onTap: onShare,
                ),
                if (hasTournament) ...[
                  const SizedBox(width: 8),
                  _Pill(
                    icon: Icons.emoji_events_outlined,
                    label: tournamentLabel!,
                    onTap: onOpenTournament!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.onSurface.withValues(alpha: 0.08),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
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
