import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Các lý do báo cáo vi phạm
class ReportReason {
  final String key;
  final IconData icon;

  const ReportReason({required this.key, required this.icon});
}

const _reportReasons = [
  ReportReason(key: 'spam', icon: Icons.campaign_rounded),
  ReportReason(key: 'inappropriate', icon: Icons.block_rounded),
  ReportReason(key: 'cheating', icon: Icons.gavel_rounded),
  ReportReason(key: 'other', icon: Icons.more_horiz_rounded),
];

String _categoryForReason(String key) => switch (key) {
  'cheating' => 'CHEATING',
  'inappropriate' => 'ABUSIVE_BEHAVIOR',
  'spam' => 'OTHER',
  _ => 'OTHER',
};

String _reasonLabel(AppLocalizations l10n, String key) => switch (key) {
  'spam' => l10n.report_reasonSpam,
  'inappropriate' => l10n.report_reasonInappropriate,
  'cheating' => l10n.report_reasonCheating,
  _ => l10n.report_reasonOther,
};

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
  static Future<bool> show(
    BuildContext context, {
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
  bool _isUploading = false;
  final List<String> _evidenceUrls = [];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isValid => _selectedReason.isNotEmpty;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(dioClientProvider).dio;
      final description = _reasonController.text.trim();
      await dio.post(
        '/reports',
        data: {
          'targetId': widget.targetId,
          'targetType': widget.targetType.toUpperCase(),
          'category': _categoryForReason(_selectedReason),
          'reason': description.isEmpty
              ? l10n.reportDefaultReason(_selectedReason)
              : description,
          'evidenceUrls': _evidenceUrls,
        },
      );

      _log.info('Báo cáo thành công: ${widget.targetType}/${widget.targetId}');

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.report_success),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi gửi báo cáo', e, stack);
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.report_error),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickEvidence() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isUploading || _evidenceUrls.length >= 5) return;
    final result = await FilePicker.pickFiles();
    final file = result?.files.single;
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (file.size > 15 * 1024 * 1024) {
      _showMessage(l10n.report_fileTooLarge);
      return;
    }
    setState(() => _isUploading = true);
    try {
      final response = await ref
          .read(dioClientProvider)
          .dio
          .post(
            '/upload/image',
            data: FormData.fromMap({
              'file': MultipartFile.fromBytes(bytes, filename: file.name),
            }),
            options: Options(contentType: 'multipart/form-data'),
          );
      final url = response.data['url']?.toString();
      if (url == null || url.isEmpty) {
        throw Exception(l10n.reportFileLinkMissing);
      }
      if (mounted) setState(() => _evidenceUrls.add(url));
    } catch (_) {
      _showMessage(l10n.report_uploadError);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  child: Icon(
                    Icons.flag_rounded,
                    color: colors.error,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.report_title,
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
              l10n.report_description,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Reason options
            ..._reportReasons.map(
              (reason) => _buildReasonOption(reason, colors, l10n),
            ),
            const SizedBox(height: 16),

            // Additional description
            Text(
              l10n.report_detailsLabel,
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
                  hintText: l10n.report_detailsHint,
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.report_evidenceLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _isUploading || _evidenceUrls.length >= 5
                      ? null
                      : _pickEvidence,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_rounded, size: 18),
                  label: Text(l10n.report_uploadFile),
                ),
              ],
            ),
            if (_evidenceUrls.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_evidenceUrls.length, (index) {
                  final url = _evidenceUrls[index];
                  final isImage = RegExp(
                    r'\.(png|jpe?g|webp)(\?|$)',
                    caseSensitive: false,
                  ).hasMatch(url);
                  return Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.border),
                        ),
                        child: InkWell(
                          onTap: isImage
                              ? null
                              : () => launchUrl(
                                  Uri.parse(url),
                                  mode: LaunchMode.externalApplication,
                                ),
                          child: isImage
                              ? Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.broken_image_outlined),
                                )
                              : const Icon(
                                  Icons.insert_drive_file_outlined,
                                  size: 30,
                                ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _evidenceUrls.removeAt(index)),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.close,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            const SizedBox(height: 8),
            Text(
              l10n.report_uploadedCount(_evidenceUrls.length),
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
            const SizedBox(height: 12),

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
                    : Text(
                        l10n.report_submit,
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

  Widget _buildReasonOption(
    ReportReason reason,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
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
                _reasonLabel(l10n, reason.key),
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
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
