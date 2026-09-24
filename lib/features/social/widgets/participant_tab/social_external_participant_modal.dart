import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';

class SocialExternalParticipantModal extends ConsumerStatefulWidget {
  const SocialExternalParticipantModal({
    super.key,
    required this.session,
    required this.slotNumber,
  });

  final SocialSessionModel session;
  final int slotNumber;

  static Future<void> show(
    BuildContext context,
    SocialSessionModel session,
    int slotNumber,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: context.colors.bgCard,
      builder: (_) => SocialExternalParticipantModal(
        session: session,
        slotNumber: slotNumber,
      ),
    );
  }

  @override
  ConsumerState<SocialExternalParticipantModal> createState() =>
      _SocialExternalParticipantModalState();
}

class _SocialExternalParticipantModalState
    extends ConsumerState<SocialExternalParticipantModal> {
  final TextEditingController _nameController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_refresh);
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final successColor = context.colors.success;
    try {
      // Root cause cũ: truyền tên ("Duy") vào field userId (backend @IsUUID)
      // -> 400 "userId must be a UUID".
      // Fix: khách ngoài CLB dùng guestName, không cần userId / tài khoản,
      // backend lưu userId NULL + guestName, chỉ đánh dấu slot đã có người.
      await ref
          .read(socialSessionDetailProvider(widget.session.id).notifier)
          .addGuestParticipant(guestName: name, ticketCount: 1);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm $name vào slot ${widget.slotNumber} thành công!',
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasName = _nameController.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Thêm người ngoài CLB',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: hasName && !_submitting ? _submit : null,
                    child: Text(
                      'Thêm',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: hasName ? AppTheme.primary : colors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryLight.withValues(alpha: 0.35),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 28,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tên',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
