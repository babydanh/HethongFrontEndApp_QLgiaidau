part of '../screens/club_detail_screen.dart';

extension _ClubDetailJoinActions on _ClubDetailScreenState {
  // ─── Join button helpers ───
  IconData _getJoinIcon() {
    if (_isMember) return Icons.check_rounded;
    if (_isPending) return Icons.hourglass_empty_rounded;
    if (_isInvited) return Icons.mail_rounded;
    return Icons.person_add_alt_1_rounded;
  }

  String _getJoinLabel() {
    final l10n = AppLocalizations.of(context)!;
    if (_isJoinLoading) return l10n.club_joinLoading;
    if (_isMember) return l10n.club_joined;
    if (_isPending) return l10n.club_pendingApproval;
    if (_isInvited) return l10n.club_acceptInvite;
    return l10n.club_joinButton;
  }

  void _showMemberOptionsSheet(BuildContext context, Community club) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _notificationPref == 'MUTED'
                        ? Icons.notifications_off_outlined
                        : Icons.notifications_active_outlined,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.club_notificationSettings,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  _notificationPref == 'MUTED'
                      ? l10n.club_notificationsMuted
                      : _notificationPref == 'MENTIONS_ONLY'
                      ? l10n.club_notificationsMentionsOnly
                      : l10n.club_notificationsAll,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showNotificationPreferenceSheet(context, club);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
                title: Text(
                  l10n.club_leaveClub,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.redAccent,
                  ),
                ),
                subtitle: Text(
                  l10n.club_leaveClubDescription,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmLeaveCommunity();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLeaveCommunity() async {
    final l10n = AppLocalizations.of(context)!;
    final userId = ref.read(userProfileProvider).asData?.value.id;
    if (userId == null || userId.isEmpty || !_isMember) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clubDetailLeaveTitle),
        content: Text(l10n.clubDetailLeaveDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.clubDetailLeaveAction),
          ),
        ],
      ),
    );
    await _waitForUiFrame();
    if (confirmed != true || !mounted) return;
    _updateClubState(() => _isJoinLoading = true);
    try {
      final ok = await ref
          .read(communityRepositoryProvider)
          .leaveCommunity(widget.clubId, userId);
      if (!mounted) return;
      if (ok) {
        await _fetchMembership();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.clubDetailLeftSuccess)));
      }
    } catch (e, stack) {
      _log.error('Lỗi rời CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.clubDetailLeaveError)));
      }
    } finally {
      _updateClubState(() => _isJoinLoading = false);
    }
  }

  Future<void> _confirmCancelJoinRequest() async {
    final l10n = AppLocalizations.of(context)!;
    final userId =
        ref.read(userProfileProvider).asData?.value.id ?? _myMembership?.userId;
    if (userId == null || userId.isEmpty || !_isPending) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clubDetailCancelJoinTitle),
        content: Text(l10n.clubDetailCancelJoinDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.clubDetailCancelJoinAction),
          ),
        ],
      ),
    );
    await _waitForUiFrame();
    if (confirmed != true || !mounted) return;
    _updateClubState(() => _isJoinLoading = true);
    try {
      final ok = await ref
          .read(communityRepositoryProvider)
          .leaveCommunity(widget.clubId, userId);
      if (!mounted) return;
      if (ok) {
        await _fetchMembership();
        ref.invalidate(communityDetailProvider(widget.clubId));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.clubDetailCancelJoinSuccess)),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.clubDetailCancelJoinError)));
      }
    } catch (e, stack) {
      _log.error('Lỗi huỷ yêu cầu tham gia CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.clubDetailCancelJoinError)));
      }
    } finally {
      _updateClubState(() => _isJoinLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _showJoinQuestionsDialog(
    List<String> questions,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // Dialog có State riêng để controller sống tới khi route thực sự được tháo
    // khỏi cây widget. Không dispose controller trong `finally` của
    // `showDialog`: Future trả kết quả ngay lúc pop, sớm hơn lúc reverse
    // transition hoàn tất và có thể làm Flutter báo `_dependents.isEmpty`.
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _JoinQuestionsDialog(
        questions: questions,
        title: l10n.clubDetailJoinQuestionsTitle,
        instruction: l10n.clubDetailJoinQuestionsInstruction,
        requiredMessage: l10n.clubDetailJoinQuestionRequired,
        cancelLabel: l10n.commonCancel,
        submitLabel: l10n.clubDetailSubmitJoinRequest,
      ),
    );
  }

  Color? _getJoinBgColor() {
    if (_isMember) return const Color(0xFF059669);
    if (_isPending) return const Color(0xFFD97706);
    if (_isInvited) return AppTheme.primary;
    return AppTheme.primary;
  }

  Future<void> _handleJoinAction(Community? club) async {
    if (_isJoinLoading || _isJoinFlowActive) return;
    _isJoinFlowActive = true;
    try {
      await _handleJoinActionInternal(club);
    } finally {
      _isJoinFlowActive = false;
    }
  }

  Future<void> _handleJoinActionInternal(Community? club) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      context.push('/login');
      return;
    }
    if (_isMember) return;
    if (_isPending) {
      await _confirmCancelJoinRequest();
      return;
    }

    final community =
        club ?? ref.read(communityDetailProvider(widget.clubId)).value;
    if (community?.joinQuestions.isNotEmpty == true) {
      final answers = await _showJoinQuestionsDialog(community!.joinQuestions);
      await _waitForUiFrame();
      if (answers == null) return;
      if (!mounted) return;
      _updateClubState(() => _isJoinLoading = true);
      try {
        final ok = await ref
            .read(communityRepositoryProvider)
            .joinCommunity(widget.clubId, answers: answers);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok ? l10n.club_joinSuccess : l10n.club_joinFailed),
            ),
          );
          if (ok) await _fetchMembership();
        }
      } catch (e, stack) {
        // joinCommunity ném lỗi kèm message backend (hết chỗ, riêng tư...) —
        // phải bắt để hiện lý do thay vì crash.
        _log.error('Lỗi khi tham gia CLB (có câu hỏi)', e, stack);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.clubDetailJoinRequestError),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        _updateClubState(() => _isJoinLoading = false);
      }
      return;
    }

    _updateClubState(() => _isJoinLoading = true);
    try {
      if (_isInvited) {
        await ref
            .read(communityRepositoryProvider)
            .respondToInvite(widget.clubId, 'accept');
        _log.success('Chấp nhận lời mời CLB thành công');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.clubDetailJoinedSuccess),
              backgroundColor: Color(0xFF059669),
            ),
          );
          await _fetchMembership();
        }
        return;
      }

      final ok = await ref
          .read(communityRepositoryProvider)
          .joinCommunity(widget.clubId);
      if (ok && mounted) {
        _log.success('Tham gia/gửi yêu cầu CLB thành công');
        final isApproval = community?.joinMode.toUpperCase() == 'APPROVAL';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isApproval
                  ? l10n.club_joinPendingApproval
                  : l10n.club_joinSuccess,
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        await _fetchMembership();
      } else if (mounted) {
        _log.warning('Tham gia CLB thất bại');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.club_joinFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi khi tham gia CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.errorPrefix}: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _updateClubState(() => _isJoinLoading = false);
    }
  }
}
