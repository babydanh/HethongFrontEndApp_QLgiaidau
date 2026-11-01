import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// "N new messages" chip shown over the chat while the viewer is scrolled up.
class LiveNewMessagesPill extends StatelessWidget {
  const LiveNewMessagesPill({
    super.key,
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      shape: const StadiumBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.liveNewMessages(count),
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_downward_rounded,
                size: 14,
                color: scheme.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
