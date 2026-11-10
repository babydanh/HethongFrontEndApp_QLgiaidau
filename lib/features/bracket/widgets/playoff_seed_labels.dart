import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/knockout_seed_labels.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the playoff board needs to draw "Nhất A / Nhì B" placeholders in empty
/// round-one slots and to let a manager swap two of them.
class PlayoffSeedLabels {
  const PlayoffSeedLabels({
    required this.slotIndexFor,
    required this.textFor,
    this.onSwap,
  });

  /// Index into the slot order of a round-one slot ([side] 1 or 2), or null.
  final int? Function(String matchId, int side) slotIndexFor;
  final String Function(int slotIndex) textFor;

  /// Null makes the labels read-only (viewers, started playoff, saving).
  final Future<void> Function(int from, int to)? onSwap;
}

typedef SeedPlanParams = ({String tournamentId, String divisionId});

/// Playoff seed plan of one division; null when it has no group-stage playoff.
/// Refetched whenever the bracket reloads: a regenerated bracket has a new
/// playoff stage id and goes back to the default slot order.
final knockoutSeedPlanProvider = FutureProvider.autoDispose
    .family<KnockoutSeedPlan?, SeedPlanParams>((ref, params) async {
      ref.watch(
        bracketMatchesWithDivisionProvider((
          tournamentId: params.tournamentId,
          divisionId: params.divisionId,
        )),
      );
      final stages = await ref
          .watch(tournamentRepositoryProvider)
          .getDivisionStages(
            params.tournamentId,
            divisionId: params.divisionId,
          );
      return KnockoutSeedPlan.fromStages(stages);
    });

final _groupPrefix = RegExp(
  r'^(bảng|group)\s+',
  caseSensitive: false,
  unicode: true,
);

/// "Nhất A", "Nhì B", "Hạng 3 A" or "Hạng 3 xuất sắc nhất".
String seedLabelText(
  AppLocalizations l10n,
  KnockoutSeedPlan plan,
  AdvanceSlot slot,
) {
  if (slot.wildcard) return l10n.playoff_seedWildcard;
  final group = plan
      .groupName(slot.groupIndex ?? 0)
      .trim()
      .replaceFirst(_groupPrefix, '');
  return switch (slot.rank) {
    1 => l10n.playoff_seedFirst(group),
    2 => l10n.playoff_seedSecond(group),
    _ => l10n.playoff_seedRank(slot.rank, group),
  };
}

/// Loads the seed plan of a division and hands the board its labels.
/// Dragging is on only for [canEdit] users while no playoff match started.
class PlayoffSeedHost extends ConsumerStatefulWidget {
  const PlayoffSeedHost({
    super.key,
    required this.tournamentId,
    required this.divisionId,
    required this.matches,
    required this.canEdit,
    required this.builder,
  });

  final String tournamentId;
  final String? divisionId;

  /// Playoff matches, used to detect a started playoff.
  final List<MatchModel> matches;
  final bool canEdit;
  final Widget Function(BuildContext context, PlayoffSeedLabels? labels)
  builder;

  @override
  ConsumerState<PlayoffSeedHost> createState() => _PlayoffSeedHostState();
}

class _PlayoffSeedHostState extends ConsumerState<PlayoffSeedHost> {
  /// True while a swap request is in flight (double drop).
  bool _busy = false;

  SeedPlanParams? get _params {
    final divisionId = widget.divisionId;
    if (divisionId == null || divisionId.isEmpty) return null;
    return (tournamentId: widget.tournamentId, divisionId: divisionId);
  }

  bool get _started =>
      widget.matches.any((m) => !m.isBye && (m.isLive || m.isCompleted));

  Future<void> _swap(KnockoutSeedPlan plan, int from, int to) async {
    final params = _params;
    final next = plan.withSwapped(from, to);
    if (_busy || params == null || identical(next, plan)) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    // Captured before the await: the widget may be disposed mid-request.
    final container = ProviderScope.containerOf(context, listen: false);
    final repository = ref.read(tournamentRepositoryProvider);
    setState(() => _busy = true);
    try {
      await repository.updateSeedOrder(
        params.tournamentId,
        divisionId: params.divisionId,
        stageId: plan.stageId,
        slotOrder: [for (final slot in next.slotOrder) slot.toJson()],
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.playoff_seedSaveError(error.toString()))),
      );
    } finally {
      container.invalidate(knockoutSeedPlanProvider(params));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = _params;
    final plan = params == null
        ? null
        : ref.watch(knockoutSeedPlanProvider(params)).value;
    if (plan == null) return widget.builder(context, null);
    final l10n = AppLocalizations.of(context)!;
    final editable = widget.canEdit && !_started && !_busy;
    return widget.builder(
      context,
      PlayoffSeedLabels(
        slotIndexFor: plan.slotIndex,
        textFor: (index) => seedLabelText(l10n, plan, plan.slotOrder[index]),
        onSwap: editable ? (from, to) => _swap(plan, from, to) : null,
      ),
    );
  }
}
