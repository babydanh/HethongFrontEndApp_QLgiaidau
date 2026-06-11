import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminEditScoreDialog extends ConsumerStatefulWidget {
  final MatchModel match;
  
  const AdminEditScoreDialog({super.key, required this.match});

  @override
  ConsumerState<AdminEditScoreDialog> createState() => _AdminEditScoreDialogState();
}

class _AdminEditScoreDialogState extends ConsumerState<AdminEditScoreDialog> {
  late TextEditingController _score1Controller;
  late TextEditingController _score2Controller;
  String? _selectedWinnerId;

  @override
  void initState() {
    super.initState();
    _score1Controller = TextEditingController(text: widget.match.score1.toString());
    _score2Controller = TextEditingController(text: widget.match.score2.toString());
    _selectedWinnerId = widget.match.winnerId.isNotEmpty ? widget.match.winnerId : null;
  }

  @override
  void dispose() {
    _score1Controller.dispose();
    _score2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colors.bgCard,
      title: Text('Admin: Sửa kết quả', style: TextStyle(color: context.colors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhập lại điểm số:', style: TextStyle(color: context.colors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _score1Controller,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: context.colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: widget.match.team1Name,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _score2Controller,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: context.colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: widget.match.team2Name,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Chọn đội thắng:', style: TextStyle(color: context.colors.textSecondary)),
            const SizedBox(height: 12),
            RadioListTile<String>(
              title: Text(widget.match.team1Name, style: TextStyle(color: context.colors.textPrimary)),
              value: widget.match.team1Id,
              groupValue: _selectedWinnerId,
              activeColor: AppTheme.primary,
              onChanged: (val) => setState(() => _selectedWinnerId = val),
            ),
            RadioListTile<String>(
              title: Text(widget.match.team2Name, style: TextStyle(color: context.colors.textPrimary)),
              value: widget.match.team2Id,
              groupValue: _selectedWinnerId,
              activeColor: AppTheme.primary,
              onChanged: (val) => setState(() => _selectedWinnerId = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: AppTheme.secondaryLight)),
        ),
        ElevatedButton(
          onPressed: _selectedWinnerId == null
              ? null
              : () {
                  final score1 = int.tryParse(_score1Controller.text) ?? widget.match.score1;
                  final score2 = int.tryParse(_score2Controller.text) ?? widget.match.score2;
                  final loserId = _selectedWinnerId == widget.match.team1Id ? widget.match.team2Id : widget.match.team1Id;
                  
                  Navigator.pop(context, {
                    'score1': score1,
                    'score2': score2,
                    'winnerId': _selectedWinnerId,
                    'loserId': loserId,
                  });
                },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          child: const Text('Lưu kết quả'),
        ),
      ],
    );
  }
}
