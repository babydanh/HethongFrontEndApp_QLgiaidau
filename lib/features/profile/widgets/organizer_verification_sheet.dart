import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

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
  static const _log = AppLogger('OrganizerVerificationSheet');
  final _phoneCtrl = TextEditingController();
  String? _evidenceUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;
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
      }
    } catch (e) {
      _log.warning('Could not fetch existing ticket: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTicket = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw StateError('Kích thước ảnh tối đa là 5MB');
      }
      final socialRepo = ref.read(communitySocialRepositoryProvider);
      final url = await socialRepo.uploadImage(bytes, file.name);
      if (mounted) {
        setState(() => _evidenceUrl = url);
      }
    } catch (e) {
      _log.error('Upload evidence error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Bad state: ', '')),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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
    if (_evidenceUrl == null || _evidenceUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.organizer_evidenceRequired),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/admin/verification-tickets', data: {
        'contactPhone': phone,
        'evidenceUrls': [_evidenceUrl],
      });

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
                        Icons.verified_user_rounded,
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
                              Icons.hourglass_top_rounded,
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Đã hiểu'),
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
                                Icons.cancel_outlined,
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
                        Icons.phone_outlined,
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
                  if (_evidenceUrl != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _evidenceUrl!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () => setState(() => _evidenceUrl = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: _isUploading ? null : _pickAndUploadImage,
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
                                Icons.cloud_upload_outlined,
                                size: 36,
                                color: colors.textMuted,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.organizer_evidenceHint,
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
                      onPressed: _isSubmitting ? null : _submitTicket,
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
