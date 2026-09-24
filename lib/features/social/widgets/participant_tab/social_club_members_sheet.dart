import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialClubMembersSheet extends ConsumerStatefulWidget {
  const SocialClubMembersSheet({
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
      builder: (_) =>
          SocialClubMembersSheet(session: session, slotNumber: slotNumber),
    );
  }

  @override
  ConsumerState<SocialClubMembersSheet> createState() =>
      _SocialClubMembersSheetState();
}

class _SocialClubMembersSheetState
    extends ConsumerState<SocialClubMembersSheet> {
  final Set<String> _selectedUserIds = {};
  bool _submitting = false;

  String _memberKey(CommunityMemberModel member) {
    return member.userId.isNotEmpty ? member.userId : member.id;
  }

  Future<void> _confirm(List<CommunityMemberModel> visibleMembers) async {
    if (_selectedUserIds.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.colors;
    try {
      final res = await ref
          .read(
            socialSessionDetailProvider(widget.session.id).notifier,
          )
          .addParticipantsBatch(userIds: _selectedUserIds.toList());
      if (!mounted) return;
      Navigator.pop(context);
      final addedCount = res.added.length;
      final skippedCount = res.skipped.length;
      final msg = skippedCount > 0
          ? 'Đã thêm $addedCount thành viên (bỏ qua $skippedCount người đã tham gia)!'
          : 'Đã thêm $addedCount thành viên vào kèo thành công!';
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: colors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: colors.error,
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
    final session = widget.session;
    final colors = context.colors;
    final mCtx = context;
    final clubTitle = session.hostClubName.isNotEmpty
        ? '${session.hostClubName} thành viên'
        : 'Thành viên CLB';

    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.75,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Back arrow + Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                    onPressed: () => Navigator.pop(mCtx),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      clubTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),

            // Body: Danh sách thành viên CLB (lọc người đã tham gia)
            Expanded(
              child: session.communityId == null || session.communityId!.isEmpty
                  ? _buildEmptyClubMembersView(colors, null)
                  : Consumer(
                      builder: (consumerCtx, ref, _) {
                        final membersAsync = ref.watch(
                          communityMembersProvider(session.communityId!),
                        );

                        return membersAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
                          ),
                          error: (err, _) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                err.toString(),
                                style: TextStyle(color: colors.error),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          data: (members) {
                            if (members.isEmpty) {
                              return _buildEmptyClubMembersView(colors, null);
                            }

                            // Ẩn thành viên đã JOINED để chỉ chọn người mới.
                            final joinedIds = session.participants
                                .where((p) => !p.isGuest)
                                .map((p) => p.userId)
                                .toSet();
                            final visible = members.where((m) {
                              final key = _memberKey(m);
                              if (key.isEmpty) return false;
                              return !joinedIds.contains(key) &&
                                  !joinedIds.contains(m.id) &&
                                  !joinedIds.contains(m.userId);
                            }).toList();

                            if (visible.isEmpty) {
                              return _buildEmptyClubMembersView(
                                colors,
                                'Tất cả thành viên đã tham gia kèo này.',
                              );
                            }

                            // Dọn selection nếu member bị lọc (tránh state cũ).
                            final visibleKeys =
                                visible.map(_memberKey).toSet();
                            final stale = _selectedUserIds
                                .where((id) => !visibleKeys.contains(id))
                                .toList();
                            if (stale.isNotEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                setState(() {
                                  for (final id in stale) {
                                    _selectedUserIds.remove(id);
                                  }
                                });
                              });
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: visible.length,
                              separatorBuilder: (_, index) =>
                                  Divider(height: 1, color: colors.border),
                              itemBuilder: (lCtx, idx) {
                                final member = visible[idx];
                                final key = _memberKey(member);
                                final isSelected =
                                    _selectedUserIds.contains(key);
                                final memberName =
                                    member.userFullName?.trim().isNotEmpty ==
                                        true
                                    ? member.userFullName!.trim()
                                    : 'Thành viên CLB';

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primaryLight.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        memberName.isNotEmpty
                                            ? memberName
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                            : 'M',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    memberName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    member.role,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.check_outlined,
                                            color: AppTheme.primary,
                                            size: 24,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _selectedUserIds.remove(key);
                                            });
                                          },
                                        )
                                      : TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedUserIds.add(key);
                                            });
                                          },
                                          child: const Text(
                                            'Chọn',
                                            style: TextStyle(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),

            // Footer: nút Xác nhận
            // - Disabled + nền xám khi chưa có thay đổi (chưa chọn ai).
            // - Enabled + nền primary khi đã chọn ít nhất 1 thành viên.
            // Chỉ dùng màu trong app_theme.dart:
            //   enabled  -> AppTheme.primary
            //   disabled -> colors.textMuted (xám, hoạt động cả dark/light)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Consumer(
                builder: (consumerCtx, ref, _) {
                  final hasChange = _selectedUserIds.isNotEmpty;
                  final enabled = hasChange && !_submitting;
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: enabled
                          ? () {
                              final membersAsync = session.communityId == null ||
                                      session.communityId!.isEmpty
                                  ? null
                                  : ref.read(
                                      communityMembersProvider(
                                        session.communityId!,
                                      ),
                                    ).asData?.value;
                              final joinedIds = session.participants
                                  .where((p) => !p.isGuest)
                                  .map((p) => p.userId)
                                  .toSet();
                              final visible =
                                  (membersAsync ?? const <CommunityMemberModel>[])
                                      .where((m) {
                                final key = _memberKey(m);
                                return key.isNotEmpty &&
                                    !joinedIds.contains(key) &&
                                    !joinedIds.contains(m.id) &&
                                    !joinedIds.contains(m.userId);
                              }).toList();
                              _confirm(visible);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: enabled
                            ? AppTheme.primary
                            : colors.textMuted,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: colors.textMuted,
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _selectedUserIds.isEmpty
                                  ? 'Xác nhận'
                                  : 'Xác nhận (${_selectedUserIds.length})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyClubMembersView(AppColorsExtension colors, String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.borderLight,
            ),
            child: Icon(
              Icons.people_alt_rounded,
              size: 42,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            message ?? 'CLB của bạn chưa có thành viên.',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
