import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

/// UI-only Lite score sheet. It deliberately does not receive a controller
/// so the preview cannot accidentally write scores before the API is ready.
void showLiteScoreModal(BuildContext context, {required MatchModel match}) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => LiteScorePage(match: match)),
  );
}

class LiteScorePage extends StatefulWidget {
  final MatchModel match;

  const LiteScorePage({super.key, required this.match});

  @override
  State<LiteScorePage> createState() => _LiteScorePageState();
}

class _LiteScorePageState extends State<LiteScorePage> {
  int _score1 = 0;
  int _score2 = 0;
  final List<(int, int)> _sets = [];
  String? _notice;

  void _change(int team, int amount) {
    setState(() {
      if (team == 1) _score1 = (_score1 + amount).clamp(0, 999);
      if (team == 2) _score2 = (_score2 + amount).clamp(0, 999);
      _notice = null;
    });
  }

  void _commitSetPreview() {
    if (_score1 == _score2) {
      setState(() => _notice = 'Hai đội cần có điểm khác nhau trước khi chốt set.');
      return;
    }
    setState(() {
      _sets.add((_score1, _score2));
      _score1 = 0;
      _score2 = 0;
      _notice = 'Set đã chốt trong bản xem trước, chưa đồng bộ lên trận.';
    });
  }

  void _undo() {
    if (_sets.isEmpty) return;
    final previous = _sets.removeLast();
    setState(() {
      _score1 = previous.$1;
      _score2 = previous.$2;
      _notice = 'Đã hoàn tác set gần nhất trong bản xem trước.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final sport = widget.match.sportKey?.toUpperCase() ?? 'THỂ THAO';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Bảng điểm Lite'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$sport · LITE', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _NoticeCard(text: 'Tự chấm điểm nhanh, không cần cấu hình trước. Đây là bản xem trước, chưa lưu vào trận.'),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _ScoreCard(name: widget.match.team1Name, score: _score1, color: const Color(0xFF2563EB), onMinus: () => _change(1, -1), onPlus: () => _change(1, 1))),
                  const SizedBox(width: 12),
                  Expanded(child: _ScoreCard(name: widget.match.team2Name, score: _score2, color: const Color(0xFFEA580C), onMinus: () => _change(2, -1), onPlus: () => _change(2, 1))),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('SET ĐÃ CHỐT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.black54)),
                    const SizedBox(height: 8),
                    if (_sets.isEmpty) const Text('Chưa có set nào', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54))
                    else Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < _sets.length; i++) Chip(label: Text('S${i + 1}: ${_sets[i].$1} - ${_sets[i].$2}'))]),
                    const SizedBox(height: 12),
                    Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _sets.isEmpty ? null : _undo, icon: const Icon(Icons.undo_rounded), label: const Text('Hoàn tác'))), const SizedBox(width: 8), Expanded(child: OutlinedButton(onPressed: _sets.isEmpty && _score1 == 0 && _score2 == 0 ? null : () => setState(() { _sets.clear(); _score1 = 0; _score2 = 0; _notice = 'Đã xóa bản xem trước.'; }), child: const Text('Xóa')))]),
                  ]),
                ),
              ),
              if (_notice != null) ...[const SizedBox(height: 10), _NoticeCard(text: _notice!, warning: true)],
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _commitSetPreview, icon: const Icon(Icons.check_rounded), label: const Text('CHỐT SET XEM TRƯỚC'))),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.emoji_events_rounded), label: const Text('CHỐT TRẬN (SẼ NỐI API SAU)'))),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final String text;
  final bool warning;
  const _NoticeCard({required this.text, this.warning = false});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: warning ? const Color(0xFFFFF7E6) : const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: warning ? const Color(0xFFF3C56B) : const Color(0xFFA9C7FF))), child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: warning ? const Color(0xFF895A00) : const Color(0xFF174A9C))));
}

class _ScoreCard extends StatelessWidget {
  final String name;
  final int score;
  final Color color;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _ScoreCard({required this.name, required this.score, required this.color, required this.onMinus, required this.onPlus});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 10), Text('$score', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: color)), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_circle_outline)), IconButton(onPressed: onPlus, icon: Icon(Icons.add_circle, color: color))])])));
}
