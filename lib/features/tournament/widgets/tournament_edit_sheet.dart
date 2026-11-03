import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Share of the screen height a sheet may take before its body scrolls.
const _maxSheetHeightFactor = 0.85;

/// The one frame every edit popup of the overview shares: a title row with a
/// close button, then the body. The body shrinks to its content (no fixed
/// empty space) and scrolls only when it is taller than the screen allows.
class TournamentEditSheet extends StatelessWidget {
  const TournamentEditSheet({
    super.key,
    required this.title,
    required this.child,
    this.fillHeight = false,
  });

  final String title;
  final Widget child;

  /// For bodies that lay themselves out with `Expanded` and need a bounded
  /// height (venues, entry fee).
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * _maxSheetHeightFactor;
    final body = fillHeight ? Expanded(child: child) : Flexible(child: child);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SizedBox(
          height: fillHeight ? maxHeight : null,
          child: Column(
            mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('tournament-edit-sheet-close'),
                      tooltip: l10n.close,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              body,
            ],
          ),
        ),
      ),
    );
  }
}
