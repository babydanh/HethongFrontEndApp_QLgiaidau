import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/core/widgets/app_icons.dart';

class _EvidenceUploadItem {
  final XFile? file;
  Uint8List? bytes;
  String? url;
  String? error;
  bool isUploading;

  _EvidenceUploadItem({this.file, this.url, this.isUploading = true});
}

/// BottomSheet cho phép người dùng nộp đơn xin cấp quyền Ban Tổ Chức (Organizer)
/// Gọi POST /admin/verification-tickets và GET /admin/verification-tickets/my
class OrganizerVerificationSheet extends ConsumerStatefulWidget {
  const OrganizerVerificationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OrganizerVerificationSheet(),
    );
  }

  @override
  ConsumerState<OrganizerVerificationSheet> createState() =>
      _OrganizerVerificationSheetState();
}

class _OrganizerVerificationSheetState
    extends ConsumerState<OrganizerVerificationSheet> {
  static const _maxEvidenceImages = 5;
  static const _log = AppLogger('OrganizerVerificationSheet');
  final _phoneCtrl = TextEditingController();
  final List<_EvidenceUploadItem> _evidenceItems = [];
  bool _isUploading = false;
  bool _isSubmitting = false;
  bool _isCancelling = false;
  bool _isLoadingTicket = true;
  Map<String, dynamic>? _existingTicket;

  @override
  void initState() {
    super.initState();
    _fetchExistingTicket();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchExistingTicket() async {
    setState(() => _isLoadingTicket = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.get('/admin/verification-tickets/my');
      final raw = response.data;
      final list = raw is Map ? (raw['data'] ?? raw) : raw;
      if (list is List && list.isNotEmpty) {
        final ticket = list.first as Map<String, dynamic>;
        _existingTicket = ticket;
        if (ticket['contactPhone'] != null) {
          _phoneCtrl.text = ticket['contactPhone'].toString();
        }
        final evidenceUrls = ticket['evidenceUrls'];
        if (ticket['status'] != 'PENDING' && evidenceUrls is List) {
          _evidenceItems.clear();
          _evidenceItems.addAll(
            evidenceUrls
                .map((value) => value.toString().trim())
                .where((value) => value.isNotEmpty)
                .take(_maxEvidenceImages)
                .map(
                  (url) => _EvidenceUploadItem(url: url, isUploading: false),
                ),
          );
        }
      }
    } catch (e) {
      _log.warning('Could not fetch existing ticket: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTicket = false);
    }
  }

  Future<void> _uploadEvidenceAt(int index) async {
    if (index < 0 || index >= _evidenceItems.length) return;
    final item = _evidenceItems[index];
    final file = item.file;
    if (file == null) return;

    setState(() {
      item.isUploading = true;
      item.error = null;
      item.url = null;
    });
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw StateError('Kích thước mỗi ảnh tối đa là 5MB');
      }
      item.bytes = bytes;
      final url = await ref
          .read(communitySocialRepositoryProvider)
          .uploadImage(bytes, file.name);
      final normalizedUrl = url.trim();
      if (normalizedUrl.isEmpty) {
        throw StateError('Máy chủ không trả về link ảnh');
      }
      item.url = normalizedUrl;
    } catch (e) {
      item.error = e.toString().replaceFirst('Bad state: ', '');
      _log.error('Upload evidence error: $e');
    } finally {
      item.isUploading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickAndUploadImages() async {
    if (_isUploading || _evidenceItems.length >= _maxEvidenceImages) return;
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked.isEmpty || !mounted) return;
    final available = _maxEvidenceImages - _evidenceItems.length;
    final files = picked.take(available).toList();

    setState(() => _isUploading = true);
    for (final file in files) {
      final item = _EvidenceUploadItem(file: file);
      setState(() => _evidenceItems.add(item));
      await _uploadEvidenceAt(_evidenceItems.length - 1);
    }
    if (mounted) {
      setState(() => _isUploading = false);
      if (picked.length > available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.organizer_evidenceLimit,
            ),
          ),
        );
      }
      if (_evidenceItems.any((item) => item.error != null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.organizer_uploadFailed),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  void _removeEvidenceAt(int index) {
    if (index < 0 || index >= _evidenceItems.length) return;
    setState(() => _evidenceItems.removeAt(index));
  }

  bool get _canSubmit =>
      !_isSubmitting &&
      !_isUploading &&
      _evidenceItems.isNotEmpty &&
      _evidenceItems.every(
        (item) =>
            !item.isUploading &&
            item.error == null &&
            (item.url?.trim().isNotEmpty ?? false),
      );

  Future<void> _submitTicket() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.organizer_phoneRequired),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }
    final evidenceUrls = _evidenceItems
        .where((item) => !item.isUploading && item.error == null)
        .map((item) => item.url?.trim() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
    final hasIncompleteUpload = _evidenceItems.any(
      (item) => item.isUploading || item.error != null || item.url == null,
    );
    if (evidenceUrls.isEmpty || hasIncompleteUpload) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasIncompleteUpload
                ? l10n.organizer_uploadFailed
                : l10n.organizer_evidenceRequired,
          ),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post(
        '/admin/verification-tickets',
        data: {'contactPhone': phone, 'evidenceUrls': evidenceUrls},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.organizer_submittedSuccess),
            backgroundColor: context.colors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _log.error('Submit ticket error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _withdrawTicket() async {
    final ticketId = _existingTicket?['id']?.toString();
    if (ticketId == null || ticketId.isEmpty || _isCancelling) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.organizer_cancelPending),
        content: Text(
          AppLocalizations.of(context)!.organizer_cancelPendingConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.organizer_cancelNo),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppLocalizations.of(context)!.organizer_cancelYes),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isCancelling = true);
    try {
      await ref
          .read(dioClientProvider)
          .dio
          .post('/admin/verification-tickets/$ticketId/withdraw');
      await _fetchExistingTicket();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.organizer_cancelSuccess,
            ),
          ),
        );
      }
    } catch (e) {
      _log.error('Withdraw verification ticket error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.organizer_cancelError),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Widget _buildEvidenceItem(
    _EvidenceUploadItem item,
    int index,
    AppColorsExtension colors,
  ) {
    Widget preview;
    if (item.bytes != null) {
      preview = Image.memory(item.bytes!, fit: BoxFit.cover);
    } else if (item.url != null) {
      preview = Image.network(item.url!, fit: BoxFit.cover);
    } else {
      preview = Center(
        child: Icon(AppIcons.image, color: colors.textMuted, size: 28),
      );
    }

    return Container(
      height: 118,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.error != null ? colors.error : colors.border,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          preview,
          if (item.isUploading)
            ColoredBox(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.of(context)!.organizer_uploading,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          if (item.error != null)
            ColoredBox(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.error!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    TextButton.icon(
                      onPressed: item.file == null
                          ? null
                          : () => _uploadEvidenceAt(index),
                      icon: const Icon(AppIcons.refresh, size: 15),
                      label: Text(
                        AppLocalizations.of(context)!.organizer_retry,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: InkWell(
              onTap: () => _removeEvidenceAt(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.close,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final userProfileAsync = ref.watch(userProfileProvider);
    final userProfile = userProfileAsync.asData?.value;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        AppIcons.shieldCheck,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.organizer_registrationTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.organizer_modalDescription,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),

                if (_isLoadingTicket)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  )
                else if (_existingTicket != null &&
                    _existingTicket!['status'] == 'PENDING') ...[
                  // Đang có đơn chờ duyệt
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              AppIcons.hourglass,
                              color: Color(0xFFF59E0B),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.organizer_pendingTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.organizer_pendingDesc,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                        if (_existingTicket!['contactPhone'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'SĐT liên hệ: ${_existingTicket!['contactPhone']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isCancelling ? null : _withdrawTicket,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.error,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isCancelling
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.organizer_cancelPending),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.organizer_cancelNo),
                        ),
                      ),
                    ],
                  ),
                ] else if (_existingTicket != null &&
                    _existingTicket!['status'] == 'APPROVED') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          AppIcons.checkCircle,
                          color: Color(0xFF059669),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.organizer_approvedTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF047857),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                l10n.organizer_approvedDesc,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colors.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.organizer_cancelNo),
                    ),
                  ),
                ] else ...[
                  if (_existingTicket != null &&
                      _existingTicket!['status'] == 'REJECTED') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                AppIcons.cancel,
                                color: Color(0xFFEF4444),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.organizer_rejectedTitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.organizer_rejectedReason}: ${_existingTicket!['rejectReason'] ?? 'Hồ sơ chưa đạt yêu cầu'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Email hiển thị
                  Text(
                    l10n.organizer_contactEmail,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      userProfile?.email ?? '—',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Số điện thoại
                  Text(
                    l10n.organizer_contactPhone,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: l10n.organizer_contactPhonePlaceholder,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colors.textMuted,
                      ),
                      prefixIcon: Icon(
                        AppIcons.phone,
                        size: 18,
                        color: colors.textMuted,
                      ),
                      filled: true,
                      fillColor: colors.bgSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Upload ảnh minh chứng
                  Text(
                    l10n.organizer_evidence,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_evidenceItems.isNotEmpty)
                    Column(
                      children: [
                        for (
                          var index = 0;
                          index < _evidenceItems.length;
                          index++
                        )
                          _buildEvidenceItem(
                            _evidenceItems[index],
                            index,
                            colors,
                          ),
                      ],
                    ),
                  if (_evidenceItems.length < _maxEvidenceImages)
                    InkWell(
                      onTap: _isUploading ? null : _pickAndUploadImages,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (_isUploading) ...[
                              const CircularProgressIndicator(
                                color: AppTheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.organizer_uploading,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                            ] else ...[
                              Icon(
                                AppIcons.upload,
                                size: 36,
                                color: colors.textMuted,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _evidenceItems.isEmpty
                                    ? l10n.organizer_evidenceHint
                                    : l10n.organizer_addMoreEvidence,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Nút Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSubmit ? _submitTicket : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _existingTicket != null &&
                                      _existingTicket!['status'] == 'REJECTED'
                                  ? l10n.organizer_resubmit
                                  : l10n.organizer_submitBtn,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
