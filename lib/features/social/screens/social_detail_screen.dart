import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/club_network_image.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/features/social/widgets/detail_tab/social_join_bottom_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/detail_tab/social_details_tab.dart';
import 'package:app_quanly_giaidau/features/social/widgets/participant_tab/social_participants_tab.dart';
import 'package:app_quanly_giaidau/features/social/widgets/payment_tab/social_payment_tab.dart';
import 'package:app_quanly_giaidau/features/social/widgets/chat_tab/social_chat_tab.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_cancel_session_dialog.dart';
import 'package:app_quanly_giaidau/features/social/widgets/detail_tab/social_contact_host_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/detail_tab/social_find_players_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/participant_tab/social_add_participant_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_more_options_sheet.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/social/screens/create_social_screen.dart';

class SocialDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final bool? isHost;

  const SocialDetailScreen({super.key, required this.sessionId, this.isHost});

  @override
  ConsumerState<SocialDetailScreen> createState() => _SocialDetailScreenState();
}

class _SocialDetailScreenState extends ConsumerState<SocialDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _removingParticipantId;
  bool _withdrawingRequest = false;

  Future<void> _removeParticipant(SocialParticipantModel participant) async {
    if (_removingParticipantId != null || participant.isHost || !_isHost) {
      return;
    }
    final auth = ref.read(authProvider);
    final currentSession = ref
        .read(socialSessionDetailProvider(widget.sessionId))
        .asData
        ?.value;
    if ((currentSession?.status.toUpperCase() ?? '') == 'COMPLETED') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa người tham gia?'),
        content: Text('Xóa ${participant.name} khỏi buổi Social này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        !identical(auth, ref.read(authProvider))) {
      return;
    }
    setState(() => _removingParticipantId = participant.apiIdentifier);
    try {
      await ref
          .read(socialSessionDetailProvider(widget.sessionId).notifier)
          .removeParticipant(participant.apiIdentifier);
      if (mounted && identical(auth, ref.read(authProvider))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa ${participant.name} khỏi buổi Social.'),
          ),
        );
      }
    } catch (error) {
      if (mounted && identical(auth, ref.read(authProvider))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted && identical(auth, ref.read(authProvider))) {
        setState(() => _removingParticipantId = null);
      }
    }
  }

  bool get _isHost =>
      ref
          .read(socialSessionDetailProvider(widget.sessionId))
          .asData
          ?.value
          .isHost ==
      true;

  bool _reviewing = false;
  Future<void> _reviewRequest(
    SocialParticipantModel participant,
    bool approve,
  ) async {
    if (_reviewing || !_isHost) return;
    final auth = ref.read(authProvider);
    setState(() => _reviewing = true);
    try {
      final notifier = ref.read(
        socialSessionDetailProvider(widget.sessionId).notifier,
      );
      if (approve) {
        await notifier.approveParticipant(participant);
      } else {
        await notifier.rejectParticipant(participant);
      }
    } catch (error) {
      if (mounted && identical(auth, ref.read(authProvider))) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted && identical(auth, ref.read(authProvider))) {
        setState(() => _reviewing = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isHost ? 4 : 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionAsync = ref.watch(
      socialSessionDetailProvider(widget.sessionId),
    );

    ref.listen(authProvider, (previous, next) {
      _removingParticipantId = null;
      _reviewing = false;
      _withdrawingRequest = false;
    });
    return sessionAsync.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () => Scaffold(
        backgroundColor: colors.bgDark,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Chi tiết Social',
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: colors.bgDark,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Chi tiết Social',
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  style: TextStyle(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .read(
                        socialSessionDetailProvider(widget.sessionId).notifier,
                      )
                      .refresh(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (session) {
        final host = session.isHost;
        final showPayment = host && session.feePerSlot > 0;
        final tabLength = 3 + (showPayment ? 1 : 0);
        if (_tabController.length != tabLength) {
          _tabController.dispose();
          _tabController = TabController(length: tabLength, vsync: this);
        }

        return Scaffold(
          backgroundColor: colors.bgDark,
          appBar: _buildAppBar(context, colors, session),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session Title Headline (IMG2 & IMG3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  session.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                    letterSpacing: 0.2,
                    height: 1.25,
                  ),
                ),
              ),

              // Horizontal Tabs (4 tabs for Admin, 3 for Member) - style from club_detail_tab_delegate
              SizedBox(
                height: 44.0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final activeIndex = _tabController.index;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTabItem(
                            index: 0,
                            label: 'Chi tiết',
                            isActive: activeIndex == 0,
                            colors: colors,
                          ),
                          const SizedBox(width: 14),
                          _buildTabItem(
                            index: 1,
                            label: 'Người tham gia',
                            isActive: activeIndex == 1,
                            colors: colors,
                          ),
                          if (showPayment) ...[
                            const SizedBox(width: 14),
                            _buildTabItem(
                              index: 2,
                              label: 'Thanh toán',
                              isActive: activeIndex == 2,
                              colors: colors,
                            ),
                          ],
                          const SizedBox(width: 14),
                          _buildTabItem(
                            index: showPayment ? 3 : 2,
                            label: 'Trò chuyện',
                            isActive: activeIndex == (showPayment ? 3 : 2),
                            colors: colors,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SocialDetailsTab(
                      session: session,
                      isHost: host,
                      onContactHost: () => _handleContactHost(session),
                      onFindPlayers: () {
                        if (session.status.toUpperCase() == 'COMPLETED') return;
                        SocialFindPlayersSheet.show(
                          context,
                          session,
                          onShareToChat: () => _shareToClubChat(session),
                        );
                      },
                      viewerFooter: _buildBottomActionBar(
                        context, isDark, session, colors,
                      ),
                    ),
                    SocialParticipantsTab(
                      session: session,
                      isHost: host,
                      onRemoveParticipant: _removeParticipant,
                      removingParticipantId: _removingParticipantId,
                      onAddParticipant: (slot) {
                        if (session.status.toUpperCase() == 'COMPLETED') return;
                        SocialAddParticipantSheet.show(context, session, slot);
                      },
                      onApproveParticipant: host && !_reviewing
                          ? (p) => _reviewRequest(p, true)
                          : null,
                      onRejectParticipant: host && !_reviewing
                          ? (p) => _reviewRequest(p, false)
                          : null,
                    ),
                    if (showPayment) SocialPaymentTab(session: session),
                    SocialChatTab(
                      key: ObjectKey(ref.watch(authProvider)),
                      session: session,
                    ),
                  ],
                ),
              ),

            ],
          ),
        );
      },
    );
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    required bool isActive,
    required AppColorsExtension colors,
  }) {
    return InkWell(
      onTap: () => _tabController.animateTo(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        height: 44.0,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive ? AppTheme.primary : colors.textMuted,
                ),
              ),
            ),
            const Spacer(),
            Container(
              height: 2.5,
              width: 24.0,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppColorsExtension colors,
    SocialSessionModel session,
  ) {
    return AppBar(
      backgroundColor: colors.bgDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colors.textPrimary, size: 24),
        onPressed: () => context.pop(),
      ),
      centerTitle: true,
      title: Text(
        session.dateDisplay,
        style: const TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
        ),
      ),
      actions: [
        IconButton(
          tooltip: MaterialLocalizations.of(
            context,
          ).refreshIndicatorSemanticLabel,
          icon: const Icon(Icons.refresh),
          onPressed: () => ref
              .read(socialSessionDetailProvider(widget.sessionId).notifier)
              .refresh(),
        ),
        IconButton(
          icon: Icon(
            Icons.ios_share_rounded,
            color: colors.textPrimary,
            size: 22,
          ),
          onPressed: () => _handleShare(session),
        ),
        IconButton(
          icon: Icon(
            Icons.more_vert_rounded,
            color: colors.textPrimary,
            size: 22,
          ),
          onPressed: () => _showMoreOptions(session),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 1: CHI TIẾT (IMG2 Upper + IMG3 Lower)
  // ═══════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════
  //  TAB 2: NGƯỜI THAM GIA (Ảnh 3 Reclub)
  // ═══════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════
  //  TAB THANH TOÁN (Dành cho Quản lý CLB)
  // ═══════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════
  //  TAB 3: TRÒ CHUYỆN (IMG4)
  // ═══════════════════════════════════════════════════════

  // ── Card Social Session inside Chat (IMG4) ──

  // ═══════════════════════════════════════════════════════
  //  BOTTOM ACTION BAR (IMG2 & IMG3)
  // ═══════════════════════════════════════════════════════
  Widget _buildBottomActionBar(
    BuildContext context,
    bool isDark,
    SocialSessionModel session,
    AppColorsExtension colors,
  ) {
    if (_isHost) {
      return const SizedBox.shrink();
    }
    final isPending = session.isPending;
    final isJoined = session.isJoined;

    final canJoin =
        session.status == 'OPEN' &&
        session.currentSlots < session.maxSlots &&
        !isJoined &&
        !isPending;
    final joinLabel = isJoined
        ? 'Đã tham gia'
        : isPending
        ? AppLocalizations.of(context)!.socialPending
        : session.status == 'CANCELLED'
        ? 'Đã hủy'
        : session.status == 'COMPLETED'
        ? 'Đã kết thúc'
        : canJoin
        ? 'Yêu cầu tham gia'
        : 'Đã đủ người';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(top: BorderSide(color: colors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left Button: 'Chat với host'
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => _handleContactHost(session),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                    foregroundColor: AppTheme.primary,
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Chat với host',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Right Button: 'Yêu cầu tham gia' / 'Chờ duyệt' / 'Đã tham gia'
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
              onPressed: canJoin
                      ? () => _handleRequestJoin(context, session)
                      : isPending && !_withdrawingRequest
                      ? () => _confirmWithdrawRequest(session)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPending
                        ? AppTheme.primaryLight
                        : isJoined
                        ? colors.success
                        : AppTheme.primary,
                    foregroundColor: isPending
                        ? AppTheme.primaryDark
                        : Colors.white,
                    disabledBackgroundColor: isPending
                        ? AppTheme.primaryLight
                        : isJoined
                        ? colors.success.withValues(alpha: 0.85)
                        : null,
                    disabledForegroundColor: isPending
                        ? AppTheme.primaryDark
                        : isJoined
                        ? Colors.white
                        : null,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isJoined) ...[
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          joinLabel,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isPending
                                ? AppTheme.primaryDark
                                : isJoined
                                ? Colors.white
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmWithdrawRequest(SocialSessionModel session) async {
    final auth = ref.read(authProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.socialCancelRequestTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.socialKeepRequest),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppLocalizations.of(context)!.socialConfirmCancelRequest),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !identical(auth, ref.read(authProvider))) return;
    setState(() => _withdrawingRequest = true);
    try {
      await ref.read(socialSessionDetailProvider(session.id).notifier).withdrawJoinRequest();
    } catch (error) {
      if (mounted && identical(auth, ref.read(authProvider))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString()), backgroundColor: context.colors.error),
        );
      }
    } finally {
      if (mounted && identical(auth, ref.read(authProvider))) {
        setState(() => _withdrawingRequest = false);
      }
    }
  }

  // ── Modal Tìm thêm người chơi (IMG3) ──

  // ── Chia sẻ vào cuộc trò chuyện Câu lạc bộ ──
  String _buildClubChatShareMessage(
    SocialSessionModel session,
    String shareUrl,
  ) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final feeLine = session.pricePerSlot > 0
        ? '💵 Phí: ${currencyFormatter.format(session.pricePerSlot)} / người'
        : '💵 Phí: Miễn phí';
    final timeLine =
        '⏰ ${session.dayOfWeek}, ngày ${session.dayOfMonth.toString().padLeft(2, '0')} Th${session.dateTime.month.toString().padLeft(2, '0')} lúc ${session.timeSlot}';
    return '''${session.title.toUpperCase()}
$timeLine
📍 ${session.venueName}
$feeLine
👥 ${session.currentParticipants}/${session.maxParticipants}

Link: $shareUrl''';
  }

  Future<void> _shareToClubChat(SocialSessionModel session) async {
    final shareUrl = session.shareUrl;
    if (shareUrl == null) {
      _showShortLinkUnavailable();
      return;
    }
    final communityId = session.communityId ?? session.clubId;
    if (communityId == null || communityId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Buổi Social này không thuộc Câu lạc bộ nào.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final message = _buildClubChatShareMessage(session, shareUrl);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(
        '/chat/rooms',
        queryParameters: {'type': 'CLUB', 'communityId': communityId},
      );
      final raw = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      final room = raw is List
          ? (raw.isEmpty ? null : raw.first as Map<String, dynamic>)
          : (raw as Map<String, dynamic>?);
      final roomId = room?['id']?.toString();
      if (roomId == null || roomId.isEmpty) {
        throw Exception('Không tìm thấy phòng chat CLB');
      }
      await dio.post(
        '/chat/messages',
        data: {'roomId': roomId, 'messageText': message},
      );
      if (!mounted) return;
      context.push(
        '/club/$communityId/chat?name=${Uri.encodeComponent(session.hostClubName)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chia sẻ vào cuộc trò chuyện CLB'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleContactHost(SocialSessionModel session) {
    SocialContactHostSheet.show(
      context,
      session,
      onOpenChat: () =>
          _tabController.animateTo((_isHost && session.feePerSlot > 0) ? 3 : 2),
    );
  }

  Future<void> _handleRequestJoin(
    BuildContext context,
    SocialSessionModel session,
  ) async {
    if (ref.read(authProvider).status != AuthStatus.authenticated) {
      context.push(
        '/login?redirect=${Uri.encodeComponent('/social/${session.id}')}',
      );
      return;
    }
    final sent = await SocialJoinBottomSheet.show(context, session);
    if (sent == true && mounted) await _offerCommunityJoin(session);
  }

  Future<void> _offerCommunityJoin(SocialSessionModel session) async {
    final sessionCommunityId = session.communityId?.trim();
    final communityId = sessionCommunityId?.isNotEmpty == true
        ? sessionCommunityId
        : session.community?.id.trim();
    if (communityId == null || communityId.isEmpty) return;
    final auth = ref.read(authProvider);
    try {
      var community = session.community;
      if (community?.name.trim().isNotEmpty != true ||
          community?.logoUrl?.trim().isNotEmpty != true) {
        try {
          final details = await ref.read(
            communityDetailProvider(communityId).future,
          );
          if (details != null) {
            community = SocialCommunitySummary(
              id: details.id,
              name: community?.name.trim().isNotEmpty == true
                  ? community!.name
                  : details.name,
              logoUrl: community?.logoUrl?.trim().isNotEmpty == true
                  ? community!.logoUrl
                  : details.logoUrl,
            );
          }
        } catch (_) {
          // Missing club imagery must not prevent the join invitation.
        }
      }
      final clubName = community?.name.trim() ?? '';
      if (clubName.isEmpty) return;
      ref.invalidate(myCommunityMembershipProvider(communityId));
      final membership = await ref.read(
        myCommunityMembershipProvider(communityId).future,
      );
      if (!mounted ||
          !identical(auth, ref.read(authProvider)) ||
          ref.read(socialSessionDetailProvider(session.id)).asData?.value.isPending != true) {
        return;
      }
      if (membership?.status.toUpperCase() == 'JOINED') return;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final colors = dialogContext.colors;
          final l10n = AppLocalizations.of(dialogContext)!;
          final logoUrl = community?.logoUrl?.trim() ?? '';
          final width = MediaQuery.sizeOf(dialogContext).width;
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            clipBehavior: Clip.none,
            backgroundColor: colors.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(dialogContext).height * .82,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 46),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  clubName,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(dialogContext).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                Divider(height: 1, color: colors.border),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 22),
                                  child: Text(
                                    l10n.socialJoinClubQuestion,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(dialogContext).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 1, color: colors.border),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: width < 340
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, false),
                                      child: Text(l10n.socialSkipClubJoin),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(dialogContext, true),
                                      child: Text(l10n.socialJoinClub),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: Text(l10n.socialSkipClubJoin),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: Text(l10n.socialJoinClub),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -36,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: colors.bgSurface,
                      child: ClipOval(
                        child: logoUrl.isEmpty
                            ? Icon(
                                Icons.groups_rounded,
                                color: colors.textSecondary,
                                size: 36,
                              )
                            : ClubNetworkImage(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.groups_rounded,
                                  color: colors.textSecondary,
                                  size: 36,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      if (accepted == true && mounted && identical(auth, ref.read(authProvider))) {
        // Club detail owns the complete existing join flow (questions, invitation,
        // approval and pending state) and avoids a second social request.
        context.push('/club/$communityId', extra: 'startJoinFlow');
      }
    } catch (_) {
      if (mounted && identical(auth, ref.read(authProvider))) {
        ref.invalidate(myCommunityMembershipProvider(communityId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.socialClubMembershipCheckError),
            backgroundColor: context.colors.error,
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.socialRetryMembership,
              onPressed: () => _offerCommunityJoin(session),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleShare(SocialSessionModel session) async {
    final shareUrl = session.shareUrl;
    if (shareUrl == null) {
      _showShortLinkUnavailable();
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(text: shareUrl, subject: session.title),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: shareUrl));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã sao chép link chia sẻ buổi ${session.title}!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showShortLinkUnavailable() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link rút gọn chưa sẵn sàng. Vui lòng thử lại sau.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMoreOptions(SocialSessionModel session) {
    void comingSoon() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tính năng đang phát triển'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    SocialMoreOptionsSheet.show(
      context,
      session,
      isHost: _isHost,
      onRepeat: comingSoon,
      onEdit: () {
        if (!const {'OPEN', 'FULL'}.contains(session.status.toUpperCase())) {
          return;
        }
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CreateSocialScreen(
            clubId: session.communityId ?? '',
            clubName: session.hostClubName,
            clubLogoUrl: session.hostClubAvatar,
            initialSession: session,
          ),
        );
      },
      onCancel: _cancelSession,
      onMute: comingSoon,
      onReport: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn bạn đã gửi báo cáo.'),
          behavior: SnackBarBehavior.floating,
        ),
      ),
    );
  }

  Future<void> _cancelSession() async {
    final confirmed = await SocialCancelSessionDialog.show(context);
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(socialSessionDetailProvider(widget.sessionId).notifier)
          .cancelSession();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final successColor = context.colors.success;
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Đã hủy buổi Social thành công!'),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
