import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';

class FootballScorePanel extends ConsumerWidget {
  final MatchControlParams params;
  final String team1Name;
  final String team2Name;

  const FootballScorePanel({super.key, required this.params, required this.team1Name, required this.team2Name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scorePanelNotifierProvider(params));
    final notifier = ref.read(scorePanelNotifierProvider(params).notifier);
    final score = state.football ?? const FootballLiveState();
    final phases = <String>['FIRST_HALF', 'HALFTIME', 'SECOND_HALF', 'STOPPAGE_TIME', 'FULL_TIME', 'EXTRA_TIME_FIRST_HALF', 'EXTRA_TIME_BREAK', 'EXTRA_TIME_SECOND_HALF', 'PENALTY_SHOOTOUT', 'COMPLETED'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Expanded(child: _TeamScore(name: team1Name, score: score.team1Goals, onAdd: () => notifier.footballAddGoal(true), onRemove: () => notifier.footballRemoveGoal(true))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
          Expanded(child: _TeamScore(name: team2Name, score: score.team2Goals, onAdd: () => notifier.footballAddGoal(false), onRemove: () => notifier.footballRemoveGoal(false))),
        ]))),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          const Icon(Icons.timer_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(child: TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Phút', isDense: true), onSubmitted: (value) => notifier.footballSetMinute(int.tryParse(value) ?? score.minute))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(value: score.phase, isExpanded: true, decoration: const InputDecoration(labelText: 'Trạng thái', isDense: true), items: phases.map((phase) => DropdownMenuItem(value: phase, child: Text(_label(phase), overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) { if (value != null) notifier.footballSetPhase(value); })),
        ]))),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final event in const [('YELLOW_CARD', 'Tháº» vÃ ng'), ('RED_CARD', 'Tháº» Ä‘á»'), ('FOUL', 'Pháº¡m lá»—i'), ('SUBSTITUTION', 'Thay ngÆ°á»i')])
            OutlinedButton.icon(onPressed: () => _showTeamPicker(context, ref, params, event.$1, event.$2), icon: const Icon(Icons.flag_outlined, size: 16), label: Text(event.$2)),
        ]))),
        if (score.events.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Diá»…n biáº¿n', style: TextStyle(fontWeight: FontWeight.w800)),
          for (final event in score.events.reversed.take(8)) Padding(padding: const EdgeInsets.only(top: 6), child: Text("${event.minute}' Â· ${event.type} Â· ${event.isTeam1 ? team1Name : team2Name}")),
        ]))),
        if (state.errorMessage case final message?) Padding(padding: const EdgeInsets.only(top: 8), child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      ]),
    );
  }

  static Future<void> _showTeamPicker(BuildContext context, WidgetRef ref, MatchControlParams params, String type, String label) async {
    final team = await showModalBottomSheet<bool>(context: context, builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(title: Text('$label Â· Äá»™i 1'), onTap: () => Navigator.pop(sheetContext, true)),
      ListTile(title: Text('$label Â· Äá»™i 2'), onTap: () => Navigator.pop(sheetContext, false)),
    ])));
    if (team != null && context.mounted) ref.read(scorePanelNotifierProvider(params).notifier).footballAddEvent(type, team);
  }

  static String _label(String phase) => switch (phase) {
    'FIRST_HALF' => 'Hiệp 1', 'HALFTIME' => 'Giải lao', 'SECOND_HALF' => 'Hiệp 2', 'STOPPAGE_TIME' => 'Bù giờ', 'FULL_TIME' => 'Hết giờ', 'EXTRA_TIME_FIRST_HALF' => 'Hiệp phụ 1', 'EXTRA_TIME_BREAK' => 'Nghỉ hiệp phụ', 'EXTRA_TIME_SECOND_HALF' => 'Hiệp phụ 2', 'PENALTY_SHOOTOUT' => 'Luân lưu', 'COMPLETED' => 'Hoàn thành', _ => phase,
  };
}

class _TeamScore extends StatelessWidget {
  final String name; final int score; final VoidCallback onAdd; final VoidCallback onRemove;
  const _TeamScore({required this.name, required this.score, required this.onAdd, required this.onRemove});
  @override
  Widget build(BuildContext context) => Column(children: [Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), Text('$score', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(onPressed: onRemove, icon: const Icon(Icons.remove_circle_outline)), IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle, color: Colors.green))])]);
}
