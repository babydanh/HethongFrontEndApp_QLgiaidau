import 'package:app_quanly_giaidau/core/config/app_spacing.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/swiss_pairing_draft.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/swiss_pairing_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Localized text for a [SwissApiException.code] / notifier `errorKey`.
String swissApiErrorText(AppLocalizations l10n, String key) => switch (key) {
  'SWISS_ROUND_INCOMPLETE' => l10n.swissApiErrorRoundIncomplete,
  'SWISS_ALL_ROUNDS_DONE' => l10n.swissApiErrorAllRoundsDone,
  'SWISS_ROUND_EXISTS' => l10n.swissApiErrorRoundExists,
  'SWISS_INVALID_PAIRING' => l10n.swissApiErrorInvalidPairing,
  'SWISS_WARNINGS_UNCONFIRMED' => l10n.swissApiErrorWarningsUnconfirmed,
  'SWISS_ROUND_STARTED' => l10n.swissApiErrorRoundStarted,
  'SWISS_UNDO_ROUND_ONE' => l10n.swissApiErrorUndoRoundOne,
  'SWISS_NOT_SWISS' => l10n.swissApiErrorNotSwiss,
  swissErrorNetwork => l10n.swissApiErrorNetwork,
  _ => l10n.swissApiErrorUnknown,
};

String _validationErrorText(AppLocalizations l10n, String code) =>
    switch (code) {
      'DUPLICATE_PARTICIPANT' => l10n.swissErrorDuplicateParticipant,
      'UNKNOWN_PARTICIPANT' => l10n.swissErrorUnknownParticipant,
      'MISSING_PARTICIPANT' => l10n.swissErrorMissingParticipant,
      'SELF_PAIRING' => l10n.swissErrorSelfPairing,
      _ => l10n.swissApiErrorInvalidPairing,
    };

String _warningText(AppLocalizations l10n, SwissWarning warning) =>
    switch (warning.type) {
      'REMATCH' => l10n.swissWarningRematch(warning.round ?? 0),
      'SECOND_BYE' => l10n.swissWarningSecondBye,
      _ => l10n.swissWarningScoreGap(warning.gap ?? 0),
    };

/// Pairing screen for the next Swiss round. One flat surface: rows separated by
/// dividers, the drag handle is the only icon, only Confirm is a filled button.
/// Long-press drags a name; tapping a name opens a sheet as the non-drag path.
class SwissPairingScreen extends ConsumerWidget {
  const SwissPairingScreen({
    super.key,
    required this.tournamentId,
    required this.divisionId,
    this.stageId,
    required this.roundNumber,
    required this.totalRounds,
  });

  final String tournamentId;
  final String divisionId;
  final String? stageId;
  final int roundNumber;
  final int totalRounds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final args = SwissPairingArgs(
      tournamentId: tournamentId,
      divisionId: divisionId,
      stageId: stageId,
    );
    final state = ref.watch(swissPairingProvider(args));
    final notifier = ref.read(swissPairingProvider(args).notifier);
    final preview = state.preview;
    final draft = state.draft;
    final round = preview?.roundNumber ?? roundNumber;
    final ready = preview != null && draft != null;

    return Scaffold(
      key: const Key('swiss-pairing-screen'),
      appBar: AppBar(title: Text(l10n.swissPairingTitle(round))),
      body: ready
          ? _Board(
              ctx: _Ctx(preview, draft, state, notifier),
              round: round,
              totalRounds: preview.totalRounds > 0
                  ? preview.totalRounds
                  : totalRounds,
            )
          : _Placeholder(state: state, onRetry: notifier.reload),
      bottomNavigationBar: ready
          ? _ConfirmBar(
              state: state,
              draft: draft,
              round: round,
              onConfirm: () => _confirm(context, ref, notifier, state, round),
            )
          : null,
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    SwissPairingNotifier notifier,
    SwissPairingState state,
    int round,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final created = await notifier.confirm(
      confirmWarnings: state.warnings.isNotEmpty,
    );
    if (!created) return;
    ref.invalidate(
      bracketMatchesWithDivisionProvider((
        tournamentId: tournamentId,
        divisionId: divisionId,
      )),
    );
    ref.invalidate(
      swissStageProvider((tournamentId: tournamentId, divisionId: divisionId)),
    );
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.swissPairingCreated(round))),
    );
    navigator.maybePop();
  }
}

/// What every row needs: the current draft, names/points and the notifier.
class _Ctx {
  const _Ctx(this.preview, this.draft, this.state, this.notifier);

  final SwissPreview preview;
  final SwissDraft draft;
  final SwissPairingState state;
  final SwissPairingNotifier notifier;

  bool get enabled => !state.submitting && !state.loading;

  Map<String, SwissPreviewParticipant> get people => {
    for (final p in preview.participants) p.id: p,
  };

  void move(String id, SwissSlotRef to) {
    if (enabled) notifier.move(id, to);
  }

  List<SwissWarning> warningsFor(Set<String> rowIds) => [
    for (final w in state.warnings)
      if (w.participantIds.isNotEmpty &&
          w.participantIds.every(rowIds.contains))
        w,
  ];
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.state, required this.onRetry});

  final SwissPairingState state;
  final Future<void> Function({String? keepErrorKey}) onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final errorKey = state.errorKey;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: state.loading || errorKey == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.swissPairingLoading),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    swissApiErrorText(l10n, errorKey),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.error),
                  ),
                  TextButton(
                    key: const Key('swiss-retry'),
                    onPressed: () => onRetry(),
                    child: Text(l10n.swissPairingRetry),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.ctx,
    required this.round,
    required this.totalRounds,
  });

  final _Ctx ctx;
  final int round;
  final int totalRounds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = ctx.draft;
    final zones = <Widget>[
      _Zone(
        key: const Key('swiss-pool'),
        title: l10n.swissPairingPool,
        ids: draft.poolIds,
        slot: const SwissPoolSlot(),
        ctx: ctx,
      ),
      _Zone(
        key: const Key('swiss-sitout'),
        title: l10n.swissPairingSitOut,
        ids: draft.sitOutIds,
        slot: const SwissSitOutSlot(),
        ctx: ctx,
      ),
    ];
    final pairs = <Widget>[
      for (var i = 0; i < draft.pairs.length; i++) _PairRow(index: i, ctx: ctx),
      _ByeRow(ctx: ctx),
    ];
    final header = _Header(
      text: l10n.swissPairingProgress(round, totalRounds, draft.pairs.length),
      onAuto: ctx.enabled ? ctx.notifier.autoPair : null,
      onUndo: ctx.enabled && ctx.state.canUndo ? ctx.notifier.undo : null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: header,
              ),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: zones,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: pairs,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            header,
            const Divider(height: 1),
            ...zones,
            const Divider(height: 1),
            ...pairs,
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.text, this.onAuto, this.onUndo});

  final String text;
  final VoidCallback? onAuto;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: Theme.of(context).textTheme.titleSmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              key: const Key('swiss-auto'),
              onPressed: onAuto,
              child: Text(l10n.swissPairingAutoPair),
            ),
            TextButton(
              key: const Key('swiss-undo'),
              onPressed: onUndo,
              child: Text(l10n.swissPairingUndo),
            ),
          ],
        ),
      ],
    );
  }
}

/// Drop target whose background tints while a name hovers over it.
class _DropCell extends StatelessWidget {
  const _DropCell({
    super.key,
    required this.slot,
    required this.ctx,
    required this.child,
  });

  final SwissSlotRef slot;
  final _Ctx ctx;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tint = Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);
    return DragTarget<String>(
      onAcceptWithDetails: (details) => ctx.move(details.data, slot),
      builder: (context, candidates, rejected) => Container(
        constraints: const BoxConstraints(minHeight: 48),
        color: candidates.isEmpty ? null : tint,
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

class _Zone extends StatelessWidget {
  const _Zone({
    super.key,
    required this.title,
    required this.ids,
    required this.slot,
    required this.ctx,
  });

  final String title;
  final List<String> ids;
  final SwissSlotRef slot;
  final _Ctx ctx;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return _DropCell(
      slot: slot,
      ctx: ctx,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Wrap(
          spacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (ids.isEmpty)
              Text(
                l10n.swissPairingDropHere,
                style: TextStyle(color: colors.textSecondary),
              ),
            for (final id in ids) _Token(id: id, ctx: ctx),
          ],
        ),
      ),
    );
  }
}

class _PairRow extends StatelessWidget {
  const _PairRow({required this.index, required this.ctx});

  final int index;
  final _Ctx ctx;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pair = ctx.draft.pairs[index];
    final rowIds = {
      if (pair.p1 != null) pair.p1!,
      if (pair.p2 != null) pair.p2!,
    };
    return Column(
      key: Key('swiss-pair-row-$index'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${index + 1}',
                semanticsLabel: l10n.swissPairingBoard(index + 1),
              ),
            ),
            Expanded(child: _slot(index, 1, pair.p1)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text('–'),
            ),
            Expanded(child: _slot(index, 2, pair.p2)),
          ],
        ),
        for (final warning in ctx.warningsFor(rowIds))
          Padding(
            padding: const EdgeInsets.only(left: 28, bottom: AppSpacing.xs),
            child: Text(
              _warningText(l10n, warning),
              style: TextStyle(color: context.colors.warning),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _slot(int index, int side, String? id) => _DropCell(
    key: Key('swiss-slot-$index-$side'),
    slot: SwissPairSlot(index, side),
    ctx: ctx,
    child: id == null ? const _EmptyHint() : _Token(id: id, ctx: ctx),
  );
}

class _ByeRow extends StatelessWidget {
  const _ByeRow({required this.ctx});

  final _Ctx ctx;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final byeId = ctx.draft.byeId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DropCell(
          key: const Key('swiss-bye'),
          slot: const SwissByeSlot(),
          ctx: ctx,
          child: Row(
            children: [
              SizedBox(
                width: 28 + AppSpacing.xs,
                child: Text(
                  l10n.swissBye,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: byeId == null
                    ? const _EmptyHint()
                    : _Token(id: byeId, ctx: ctx),
              ),
            ],
          ),
        ),
        if (byeId != null)
          for (final warning in ctx.warningsFor({byeId}))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                _warningText(l10n, warning),
                style: TextStyle(color: context.colors.warning),
              ),
            ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) => Text(
    AppLocalizations.of(context)!.swissPairingDropHere,
    style: TextStyle(color: context.colors.textSecondary),
  );
}

/// A draggable, tappable name. The drag-handle icon is the only icon on screen.
class _Token extends StatelessWidget {
  const _Token({required this.id, required this.ctx});

  final String id;
  final _Ctx ctx;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final person = ctx.people[id];
    final name = person?.teamName ?? id;
    final content = InkWell(
      onTap: ctx.enabled ? () => _showMoveSheet(context, ctx, id) : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: l10n.swissPairingDragHint,
              child: Icon(
                Icons.drag_indicator,
                size: 20,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (person != null)
                    Text(
                      l10n.swissPairingPoints(person.totalPoints),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return LongPressDraggable<String>(
      key: Key('swiss-chip-$id'),
      data: id,
      maxSimultaneousDrags: ctx.enabled ? 1 : 0,
      feedback: Material(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(name),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: content),
      child: content,
    );
  }
}

SwissSlotRef? _slotOf(SwissDraft draft, String id) {
  for (var i = 0; i < draft.pairs.length; i++) {
    if (draft.pairs[i].p1 == id) return SwissPairSlot(i, 1);
    if (draft.pairs[i].p2 == id) return SwissPairSlot(i, 2);
  }
  return draft.byeId == id ? const SwissByeSlot() : null;
}

/// Non-drag path: swap with someone, or move to a free place.
Future<void> _showMoveSheet(BuildContext context, _Ctx ctx, String id) {
  final l10n = AppLocalizations.of(context)!;
  final draft = ctx.draft;
  final mine = _slotOf(draft, id);

  final swaps = <(String, SwissSlotRef, bool)>[];
  for (final other in ctx.preview.participants) {
    if (other.id == id) continue;
    final theirs = _slotOf(draft, other.id);
    // A swap needs at least one of the two to hold a pair or BYE slot.
    if (mine != null) swaps.add((other.id, mine, true));
    if (mine == null && theirs != null) swaps.add((other.id, theirs, false));
  }

  final moves = <(String, String, SwissSlotRef)>[
    if (!draft.poolIds.contains(id))
      ('pool', l10n.swissPairingPool, const SwissPoolSlot()),
    if (!draft.sitOutIds.contains(id))
      ('sitout', l10n.swissPairingSitOut, const SwissSitOutSlot()),
    if (draft.byeId == null) ('bye', l10n.swissBye, const SwissByeSlot()),
    for (var i = 0; i < draft.pairs.length; i++) ...[
      if (draft.pairs[i].p1 == null)
        ('pair-$i-1', l10n.swissPairingBoard(i + 1), SwissPairSlot(i, 1)),
      if (draft.pairs[i].p2 == null)
        ('pair-$i-2', l10n.swissPairingBoard(i + 1), SwissPairSlot(i, 2)),
    ],
  ];

  final people = ctx.people;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              people[id]?.teamName ?? id,
              style: Theme.of(sheet).textTheme.titleMedium,
            ),
          ),
          if (swaps.isNotEmpty) _SheetHeader(l10n.swissPairingSwapWith),
          for (final (otherId, slot, moveOther) in swaps)
            ListTile(
              key: Key('swiss-swap-$otherId'),
              title: Text(
                people[otherId]?.teamName ?? otherId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                l10n.swissPairingPoints(people[otherId]?.totalPoints ?? 0),
              ),
              onTap: () {
                Navigator.pop(sheet);
                ctx.move(moveOther ? otherId : id, slot);
              },
            ),
          if (moves.isNotEmpty) _SheetHeader(l10n.swissPairingMoveTo),
          for (final (key, label, slot) in moves)
            ListTile(
              key: Key('swiss-move-$key'),
              title: Text(label),
              onTap: () {
                Navigator.pop(sheet);
                ctx.move(id, slot);
              },
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(sheet),
              child: Text(l10n.swissPairingCancel),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.xs,
    ),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: context.colors.textSecondary,
      ),
    ),
  );
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.state,
    required this.draft,
    required this.round,
    required this.onConfirm,
  });

  final SwissPairingState state;
  final SwissDraft draft;
  final int round;
  final VoidCallback onConfirm;

  int get _unplaced {
    if (draft.poolIds.isNotEmpty) return draft.poolIds.length;
    var vacant = 0;
    for (final pair in draft.pairs) {
      final filled = (pair.p1 == null ? 0 : 1) + (pair.p2 == null ? 0 : 1);
      if (filled == 1) vacant++;
    }
    return vacant;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final errorKey = state.errorKey;
    final codes = {for (final e in state.errors) e.code};
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isDraftComplete(draft))
                  Text(
                    l10n.swissPairingIncompleteHint(_unplaced),
                    key: const Key('swiss-incomplete-hint'),
                    style: TextStyle(color: colors.warning),
                  ),
                for (final code in codes)
                  Text(
                    _validationErrorText(l10n, code),
                    style: TextStyle(color: colors.error),
                  ),
                if (errorKey != null)
                  Text(
                    swissApiErrorText(l10n, errorKey),
                    style: TextStyle(color: colors.error),
                  ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  key: const Key('swiss-confirm'),
                  onPressed: state.canConfirm ? onConfirm : null,
                  child: Text(
                    state.warnings.isEmpty
                        ? l10n.swissPairingConfirm(round)
                        : l10n.swissPairingConfirmWithWarnings,
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
