import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';

/// Các lý do báo cáo vi phạm
class ReportReason {
  final String key;
  final String label;
  final IconData icon;

  const ReportReason({
    required this.key,
    required this.label,
    required this.icon,
  });
}

const _reportReasons = [
  ReportReason(key: 'spam', label: 'Spam / Quảng cáo', icon: Icons.campaign_rounded),
  ReportReason(key: 'inappropriate', label: 'Nội dung không phù hợp', icon: Icons.block_rounded),
  ReportReason(key: 'cheating', label: 'Gian lận', icon: Icons.gavel_rounded),
  ReportReason(key: 'other', label: 'Khác', icon: Icons.more_horiz_rounded),
];

/// Hiển thị bottom sheet báo cáo vi phạm.
///
/// Sử dụng:
/// ```dart
/// final result = await ReportSheet.show(context, targetId: '...', targetType: 'match');
/// ```
class ReportSheet extends ConsumerStatefulWidget {
  final String targetId;
  final String targetType; // 'match', 'user', 'comment', 'tournament'

  const ReportSheet({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  /// Show bottom sheet và trả về true nếu gửi thành công
  static Future<bool> show(BuildContext context, {
    required String targetId,
    required String targetType,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportSheet(targetId: targetId, targetType: targetType),
    ).then((r) => r ?? false);
  }

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  static const _log = AppLogger('ReportSheet');
  String _selectedReason = '';
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isValid => _selectedReason.isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/reports', data: {
        'targetId': widget.targetId,
        'targetType': widget.targetType,
        'reason': _selectedReason,
        'description': _reasonController.text.trim(),
      });

      _log.info('Báo cáo thành công: ${widget.targetType}/${widget.targetId}');

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cảm ơn bạn đã báo cáo. Chúng tôi sẽ xem xét.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi gửi báo cáo', e, stack);
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể gửi báo cáo. Hãy thử lại.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.flag_rounded, color: colors.error, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Báo cáo vi phạm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng chọn lý do báo cáo. Thông tin của bạn sẽ được bảo mật.',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Reason options
            ..._reportReasons.map((reason) => _buildReasonOption(reason, colors)),
            const SizedBox(height: 16),

            // Additional description
            Text(
              'Mô tả chi tiết (không bắt buộc)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: TextField(
                controller: _reasonController,
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập lý do chi tiết...',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isValid && !_isSubmitting ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  disabledBackgroundColor: colors.error.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Gửi báo cáo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonOption(ReportReason reason, AppColorsExtension colors) {
    final isSelected = _selectedReason == reason.key;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason.key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.error.withValues(alpha: 0.08)
              : colors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.error.withValues(alpha: 0.4)
                : colors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              reason.icon,
              size: 20,
              color: isSelected ? colors.error : colors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colors.error : colors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
