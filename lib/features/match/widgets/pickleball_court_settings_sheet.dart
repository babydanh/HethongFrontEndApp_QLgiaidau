import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/pickleball_court_notifier.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mở sheet "Cài đặt sân" (⚙). Chỉ gọi khi người dùng có quyền ghi điểm.
Future<void> showPickleballCourtSettingsSheet(
  BuildContext context,
  MatchControlParams params,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => PickleballCourtSettingsSheet(params: params),
  );
}

/// Cài đặt sân riêng của trọng tài: VĐV ô phải lúc xuất phát, đổi sân ngay,
/// tự đổi sân, chỉ định người giao, hoàn tác, khôi phục tự động.
/// Mọi thao tác đi qua hàm thuần trong pickleball_court.dart rồi notifier ghi server.
class PickleballCourtSettingsSheet extends ConsumerWidget {
  const PickleballCourtSettingsSheet({super.key, required this.params});

  final MatchControlParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final court = ref.watch(pickleballCourtNotifierProvider(params));
    final courtContext = ref.watch(pickleballCourtContextProvider(params));
    final match = ref.watch(singleMatchProvider(params)).value;
    if (courtContext == null) return const SizedBox.shrink();

    final team1Players = match?.team1Members ?? const <String>[];
    final team2Players = match?.team2Members ?? const <String>[];
    List<String> playersOf(int team) =>
        team == 1 ? team1Players : team2Players;
    final isDoubles = courtContext.isDoubles;
    final servingTeam = courtContext.servingTeam;

    Future<void> run(
      CourtState Function(CourtState state, CourtContext context) action,
    ) async {
      final error = await ref
          .read(pickleballCourtNotifierProvider(params).notifier)
          .apply(action);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              ErrorParser.parse(error, l10n.pickleballCourtSaveError, l10n),
            ),
          ),
        );
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.pickleballCourtSettings,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (isDoubles) ...[
              _SectionTitle(l10n.pickleballCourtStartingRight),
              for (final team in const [1, 2])
                _PlayerChoiceRow(
                  label: team == 1 ? l10n.pickleballTeam1 : l10n.pickleballTeam2,
                  playerCount: 2,
                  players: playersOf(team),
                  selectedIndex: court.startingRightOf(team),
                  l10n: l10n,
                  onSelected: (index) => run(
                    (state, context) =>
                        setStartingRight(state, context, team, index),
                  ),
                ),
              const Divider(height: 24),
            ],
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => run(swapEndsNow),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(l10n.pickleballCourtSwapNow),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.pickleballCourtAutoSwitch),
              subtitle: Text(l10n.pickleballCourtAutoSwitchHint),
              value: court.autoSwitchEnds,
              onChanged: (value) => run(
                (state, context) => setAutoSwitchEnds(state, context, value),
              ),
            ),
            if (servingTeam != null) ...[
              const Divider(height: 24),
              _SectionTitle(l10n.pickleballCourtServerOverride),
              _PlayerChoiceRow(
                label: servingTeam == 1
                    ? l10n.pickleballTeam1
                    : l10n.pickleballTeam2,
                playerCount: isDoubles ? 2 : 1,
                players: playersOf(servingTeam),
                selectedIndex: court.serverOverride?.team == servingTeam
                    ? court.serverOverride?.playerIndex
                    : null,
                l10n: l10n,
                onSelected: (index) => run(
                  (state, context) =>
                      setServerOverride(state, context, servingTeam, index),
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: court.history.isEmpty
                        ? null
                        : () => run((state, _) => undoCourtChange(state)),
                    icon: const Icon(Icons.undo_rounded),
                    label: Text(l10n.pickleballCourtUndo),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => run(restoreAutomaticCourt),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(l10n.pickleballCourtRestoreAutomatic),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Một đội với các lựa chọn VĐV dạng chip (tối thiểu 44 px chạm được).
class _PlayerChoiceRow extends StatelessWidget {
  const _PlayerChoiceRow({
    required this.label,
    required this.playerCount,
    required this.players,
    required this.selectedIndex,
    required this.l10n,
    required this.onSelected,
  });

  final String label;
  final int playerCount;
  final List<String> players;
  final int? selectedIndex;
  final AppLocalizations l10n;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
          for (var index = 0; index < playerCount; index++)
            ChoiceChip(
              materialTapTargetSize: MaterialTapTargetSize.padded,
              label: Text(courtPlayerDisplayName(players, index, l10n)),
              selected: selectedIndex == index,
              onSelected: (_) => onSelected(index),
            ),
        ],
      ),
    );
  }
}
