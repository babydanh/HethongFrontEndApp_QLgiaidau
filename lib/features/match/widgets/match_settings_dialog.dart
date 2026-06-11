import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';

class MatchSettingsDialog extends StatefulWidget {
  const MatchSettingsDialog({super.key});

  @override
  State<MatchSettingsDialog> createState() => _MatchSettingsDialogState();
}

class _MatchSettingsDialogState extends State<MatchSettingsDialog> {
  final _maxScoreController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final _refereeController = TextEditingController();

  @override
  void dispose() {
    _maxScoreController.dispose();
    _timeLimitController.dispose();
    _refereeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colors.bgSurface,
      title: Text(
        'Thiết lập trận đấu',
        style: TextStyle(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextFormField(
            controller: _maxScoreController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            label: 'Điểm tối đa (Tùy chọn)',
            hint: 'Để trống nếu không giới hạn',
          ),
          const SizedBox(height: 16),
          AppTextFormField(
            controller: _timeLimitController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            label: 'Thời gian thi đấu (Phút) (Tùy chọn)',
            hint: 'Để trống nếu không giới hạn',
          ),
          const SizedBox(height: 16),
          AppTextFormField(
            controller: _refereeController,
            keyboardType: TextInputType.name,
            label: 'Tên trọng tài (Bắt buộc)',
            hint: 'Nhập tên trọng tài',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy', style: TextStyle(color: context.colors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_refereeController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Vui lòng nhập tên trọng tài'), backgroundColor: context.colors.error),
              );
              return;
            }
            final maxScore = int.tryParse(_maxScoreController.text);
            final timeLimit = int.tryParse(_timeLimitController.text);
            Navigator.pop(context, {
              'maxScore': maxScore,
              'timeLimit': timeLimit,
              'refereeName': _refereeController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Bắt đầu'),
        ),
      ],
    );
  }
}
