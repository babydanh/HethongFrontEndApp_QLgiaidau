import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/organizer_verification_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Bottom sheet displaying the two tournament creation paths.
///
/// The actions and routes stay unchanged; this sheet only presents the choices
/// with the same short labels used elsewhere in the app.
void showPublicTournamentTypeSheet(BuildContext context, [WidgetRef? ref]) {
  final colors = context.colors;
  final l10n = AppLocalizations.of(context)!;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            const SizedBox(height: 14),
            Text(
              l10n.club_selectTournamentType,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              l10n.club_selectTournamentDesc,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
            const SizedBox(height: 14),

            // Option 1: Tạo giải CLB Lite. Keep the existing club flow.
            Consumer(
              builder: (consumerCtx, consumerRef, _) {
                final activeRef = ref ?? consumerRef;
                return InkWell(
                  onTap: () => handleClubLiteSelection(context, ctx, activeRef),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Color(0xFFF59E0B),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.publicClubLiteCreateTitle,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                l10n.club_liteDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.textMuted,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Option 2: Tạo giải nhanh. This is the public quick flow.
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                context.push('/tournaments/create');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFF3B82F6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.quickCreateTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l10n.quickCreateDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Dialog thông báo yêu cầu quyền Ban Tổ Chức khi tài khoản chỉ là PLAYER
void showOrganizerRequiredDialog(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onCancel,
}) {
  final colors = context.colors;
  final l10n = AppLocalizations.of(context)!;

  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: colors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.organizer_reqTitle,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        l10n.organizer_reqDesc,
        style: TextStyle(
          fontSize: 13,
          color: colors.textSecondary,
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(dialogCtx);
            if (onCancel != null) {
              onCancel();
            } else {
              // Kích hoạt luồng tạo giải nhanh trong CLB.
              handleClubLiteSelection(context, dialogCtx, ref);
            }
          },
          child: Text(
            l10n.organizer_useLite,
            style: const TextStyle(
              color: Color(0xFFD97706),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(dialogCtx);
            OrganizerVerificationSheet.show(context);
          },
          icon: const Icon(Icons.verified_user_rounded, size: 17),
          label: Text(l10n.organizer_applyNow),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    ),
  );
}

/// Xử lý bấm vào nút Tạo giải nhanh:
/// 1. Đóng sheet chọn loại giải
/// 2. Lấy danh sách CLB của người dùng
/// 3. Nếu chưa có CLB nào -> Hiện Dialog/Sheet dẫn đi tạo CLB trước
/// 4. Nếu có đúng 1 CLB -> Vào thẳng /club/:id/create-tournament
/// 5. Nếu có nhiều CLB -> Mở sheet chọn CLB muốn tổ chức
Future<void> handleClubLiteSelection(
  BuildContext context,
  BuildContext sheetContext,
  WidgetRef ref,
) async {
  Navigator.pop(sheetContext);

  // Hiển thị loading nhẹ trong khi tải danh sách CLB
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
  );

  List<Community> clubs = [];
  try {
    clubs = await ref.read(myCommunitiesProvider.future);
  } catch (e) {
    // Nếu lỗi mạng, thử đọc dữ liệu cache nếu có
    final cached = ref.read(myCommunitiesProvider).asData?.value;
    if (cached != null) {
      clubs = cached;
    }
  } finally {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context); // Tắt loading dialog
    }
  }

  if (!context.mounted) return;

  // Lọc các CLB mà user có quyền tổ chức / quản lý nếu cần,
  // hoặc cho phép tất cả các CLB mà user là thành viên/chủ
  final manageableClubs = clubs.where((c) {
    final role = (c.myRole ?? '').toUpperCase();
    return role == 'OWNER' ||
        role == 'ADMIN' ||
        role == 'MODERATOR' ||
        role == 'LEADER' ||
        role == 'CREATOR' ||
        role.isEmpty; // fallback nếu backend không trả myRole nhưng nằm trong getMyCommunities
  }).toList();

  final effectiveClubs = manageableClubs.isNotEmpty ? manageableClubs : clubs;

  if (effectiveClubs.isEmpty) {
    // Trường hợp 1: Chưa có CLB nào -> Hướng dẫn tạo CLB trước
    _showNoClubDialog(context);
  } else if (effectiveClubs.length == 1) {
    // Trường hợp 2: Có đúng 1 CLB -> Vào thẳng
    context.push('/club/${effectiveClubs.first.id}/create-tournament');
  } else {
    // Trường hợp 3: Có nhiều CLB -> Mở Sheet chọn CLB
    _showSelectClubSheet(context, effectiveClubs);
  }
}

/// Dialog nhắc nhở khi user chưa có Câu lạc bộ nào
void _showNoClubDialog(BuildContext context) {
  final colors = context.colors;
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: colors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Color(0xFFF59E0B),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chưa có Câu Lạc Bộ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'Tạo giải nhanh dành cho các hoạt động nội bộ câu lạc bộ. Bạn cần tạo câu lạc bộ trước khi bắt đầu.',
        style: TextStyle(
          fontSize: 13,
          color: colors.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: Text(
            'Để sau',
            style: TextStyle(
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(dialogCtx);
            context.push('/club-create');
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Tạo CLB ngay'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    ),
  );
}

/// Sheet chọn 1 CLB trong danh sách CLB của user để tạo giải nhanh.
void _showSelectClubSheet(BuildContext context, List<Community> clubs) {
  final colors = context.colors;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) => SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            Text(
              'Chọn Câu Lạc Bộ Tổ Chức',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chọn câu lạc bộ bạn muốn tổ chức giải nhanh:',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: clubs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (itemCtx, index) {
                  final club = clubs[index];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      context.push('/club/${club.id}/create-tournament');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  club.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${club.memberCount} thành viên',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
