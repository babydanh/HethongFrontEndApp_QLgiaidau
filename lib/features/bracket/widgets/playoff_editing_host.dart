import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_slot_editing_scope.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';

/// Gives a playoff view manager drag and drop: the holding tray above it and a
/// drop handler that sends the slot change, then reloads the bracket. When
/// [enabled] is false the view gets no handler and stays read-only.
class PlayoffEditingHost extends ConsumerWidget {
  const PlayoffEditingHost({
    super.key,
    required this.enabled,
    required this.tournamentId,
    required this.divisionId,
    required this.builder,
  });

  final bool enabled;
  final String tournamentId;
  final String? divisionId;
  final Widget Function(BuildContext context, BracketSlotDropCallback? onDrop)
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return builder(context, null);
    return BracketSlotEditingScope(
      enabled: true,
      tournamentId: tournamentId,
      divisionId: divisionId,
      isLite: () =>
          ref.read(tournamentProvider(tournamentId)).value?.isLite == true,
      onApplied: () {
        ref.invalidate(bracketMatchesProvider(tournamentId));
        ref.invalidate(
          bracketMatchesWithDivisionProvider((
            tournamentId: tournamentId,
            divisionId: divisionId,
          )),
        );
      },
      builder: (context, tray, onSlotDrop) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tray != null)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: tray),
          builder(context, onSlotDrop),
        ],
      ),
    );
  }
}
