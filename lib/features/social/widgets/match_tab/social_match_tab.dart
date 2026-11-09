import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_standalone_match_dialog.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_standalone_match_result_dialog.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';

/// Tab "Trận đấu" bên trong một buổi Social.
///
/// - Buổi gắn CLB (`communityId`): như mô tả bên dưới.
/// - Buổi cá nhân (không có `communityId`): trận lấy/tạo theo `socialSessionId`;
///   chỉ host tạo được, người chơi là người tham gia đã duyệt của buổi.
///
/// Tái dùng nguyên [ClubStandaloneMatchDialog] (ghép đội thủ công) và
/// [ClubStandaloneMatchResultDialog] (nhập kết quả) của CLB — không viết
/// logic ghép đội mới. Danh sách trận lọc theo `communityId` vì Backend
/// không có liên kết match <-> buổi Social (xem design.md của change
/// `them-tab-tao-tran-trong-social`): trận hiển thị là của cả CLB, không chỉ
/// riêng buổi này.
class SocialMatchTab extends ConsumerStatefulWidget {
  final String sessionId;
  final String? communityId;
  final bool isHost;
  final List<SocialParticipantModel> approvedParticipants;

  const SocialMatchTab({
    super.key,
    required this.sessionId,
    this.communityId,
    required this.isHost,
    required this.approvedParticipants,
  });

  @override
  ConsumerState<SocialMatchTab> createState() => _SocialMatchTabState();
}

class _SocialMatchTabState extends ConsumerState<SocialMatchTab> {
  List<ClubSessionMatchModel> _matches = const [];
  bool _isLoading = true;
  String? _loadError;
  Set<String> _clubMemberUserIds = const {};

  /// Buổi cá nhân không gắn CLB nên không có luật/thành viên CLB.
  bool get _isPersonal => widget.communityId == null;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
    if (!_isPersonal) _fetchClubMemberIds();
  }

  Future<void> _fetchMatches() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final repo = ref.read(clubMatchSessionRepositoryProvider);
      final communityId = widget.communityId;
      final matches = communityId == null
          ? await repo.standaloneMatchesBySocialSession(widget.sessionId)
          : await repo.standaloneMatches(communityId);
      if (!mounted) return;
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  /// Danh sách userId của thành viên CLB đã JOINED — dùng để lọc khách mời /
  /// người không thuộc CLB ra khỏi danh sách ghép đội.
  Future<void> _fetchClubMemberIds() async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      final members = await repo.getMembers(
        widget.communityId!,
        limit: 100,
        status: 'JOINED',
      );
      if (!mounted) return;
      setState(() {
        _clubMemberUserIds = members.map((m) => m.userId).toSet();
      });
    } catch (_) {
      // Giữ danh sách rỗng; ghép đội sẽ không có sẵn gợi ý nhưng không chặn thao tác thủ công.
    }
  }

  /// Người tham gia đã duyệt của buổi Social VÀ là thành viên CLB đã JOINED
  /// (loại khách mời), chuyển sang kiểu thành viên CLB mà
  /// `ClubStandaloneMatchDialog` đã biết cách hiển thị/ghép đội.
  List<CommunityMemberModel> get _preselectedMembers => widget
      .approvedParticipants
      .where(
        (p) =>
            !p.isGuest &&
            (_isPersonal || _clubMemberUserIds.contains(p.userId)),
      )
      .map(
        (p) => CommunityMemberModel(
          id: p.id,
          userId: p.userId,
          communityId: widget.communityId ?? '',
          status: 'JOINED',
          userFullName: p.fullName,
          userAvatarUrl: p.avatarUrl,
          joinedAt: p.joinedAt.toIso8601String(),
        ),
      )
      .toList(growable: false);

  bool _canCreateMatch() {
    final communityId = widget.communityId;
    // Buổi cá nhân: chỉ host (Backend vẫn là chốt cuối).
    if (communityId == null) return widget.isHost;
    final membership = ref
        .watch(myCommunityMembershipProvider(communityId))
        .asData
        ?.value;
    if (membership?.status.toUpperCase() != 'JOINED') return false;
    final role = (membership?.role ?? '').toUpperCase();
    final isManager = const {'OWNER', 'ADMIN', 'MODERATOR'}.contains(role);
    final settings = ref
        .watch(communitySocialSettingsProvider(communityId))
        .asData
        ?.value;
    return isManager || settings?.memberMatchCreationEnabled != false;
  }

  Future<void> _createMatch() async {
    final createdMatch = await ClubStandaloneMatchDialog.show(
      context,
      communityId: widget.communityId,
      socialSessionId: _isPersonal ? widget.sessionId : null,
      preselectedMembers: _preselectedMembers,
      onMatchCreated: _fetchMatches,
    );
    if (!mounted || createdMatch == null) return;
    final action = await ClubStandaloneMatchResultDialog.show(
      context,
      match: createdMatch,
      showScoreboardAction: false,
    );
    if (!mounted || action != ClubStandaloneMatchAction.saved) return;
    unawaited(_fetchMatches());
  }

  Future<void> _openResult(ClubSessionMatchModel match) async {
    final action = await ClubStandaloneMatchResultDialog.show(
      context,
      match: _toMatchModel(match),
      showScoreboardAction: false,
    );
    if (!mounted || action != ClubStandaloneMatchAction.saved) return;
    unawaited(_fetchMatches());
  }

  MatchModel _toMatchModel(ClubSessionMatchModel sm) {
    final sideAMembers = sm.sideAMembers
        .map(
          (m) => MatchMemberInfo(
            userId: m.userId,
            fullName: m.displayName,
            avatarUrl: m.avatarUrl,
            isMock: m.isMock,
          ),
        )
        .toList(growable: false);
    final sideBMembers = sm.sideBMembers
        .map(
          (m) => MatchMemberInfo(
            userId: m.userId,
            fullName: m.displayName,
            avatarUrl: m.avatarUrl,
            isMock: m.isMock,
          ),
        )
        .toList(growable: false);
    final sideAName = sm.sideANames.join(' · ').trim();
    final sideBName = sm.sideBNames.join(' · ').trim();
    return MatchModel(
      id: sm.id,
      isStandaloneMatch: true,
      round: 0,
      matchNumber: 1,
      team1Id: 'SIDE_A',
      team2Id: 'SIDE_B',
      team1Name: sideAName.isEmpty ? 'Đội A' : sideAName,
      team2Name: sideBName.isEmpty ? 'Đội B' : sideBName,
      score1: sm.sideAScore,
      score2: sm.sideBScore,
      status: sm.status,
      bracketPosition: const BracketPosition(round: 1, position: 1),
      scoreDetails: sm.scoreDetails,
      team1MemberInfos: sideAMembers,
      team2MemberInfos: sideBMembers,
      revision: sm.revision,
      updatedAt: sm.updatedAt ?? sm.createdAt ?? DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final canCreateMatch = _canCreateMatch();
    final notEnoughParticipants = _preselectedMembers.length < 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _isPersonal
                    ? const SizedBox.shrink()
                    : Text(
                        l10n.social_matchListNote,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textMuted,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: canCreateMatch ? _createMatch : null,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.club_createMatchStandalone),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (notEnoughParticipants)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.social_matchNotEnoughParticipants,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.error,
              ),
            ),
          ),
        Expanded(child: _buildBody(colors, l10n)),
      ],
    );
  }

  Widget _buildBody(AppColorsExtension colors, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError!,
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
            TextButton(onPressed: _fetchMatches, child: Text(l10n.infoRetry)),
          ],
        ),
      );
    }
    if (_matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_tennis_rounded,
                size: 40,
                color: colors.textMuted,
              ),
              const SizedBox(height: 10),
              Text(
                _isPersonal
                    ? l10n.social_matchEmptyTitleSession
                    : l10n.social_matchEmptyTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchMatches,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _matches.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            _buildMatchCard(_matches[index], colors, l10n),
      ),
    );
  }

  Widget _buildMatchCard(
    ClubSessionMatchModel match,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    final isCompleted = match.status.toUpperCase() == 'COMPLETED';
    final sideAName = match.sideANames.join(' · ').trim();
    final sideBName = match.sideBNames.join(' · ').trim();
    final statusColor = isCompleted ? Colors.green.shade700 : AppTheme.primary;

    return InkWell(
      onTap: () => _openResult(match),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${sideAName.isEmpty ? 'Đội A' : sideAName} vs ${sideBName.isEmpty ? 'Đội B' : sideBName}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isCompleted
                        ? l10n.social_matchStatusCompleted
                        : l10n.social_matchStatusScheduled,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (isCompleted) ...[
              const SizedBox(height: 6),
              Text(
                '${match.sideAScore} - ${match.sideBScore}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
