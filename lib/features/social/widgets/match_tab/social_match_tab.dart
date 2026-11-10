import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/data/models/standalone_match_owner.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_standalone_match_dialog.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_standalone_match_result_dialog.dart';
import 'package:app_quanly_giaidau/features/match/widgets/official_score_modal.dart';
import 'package:app_quanly_giaidau/features/social/widgets/match_tab/social_match_mapper.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';

/// Tab "Trận đấu" bên trong một buổi Social.
///
/// - Buổi gắn CLB (`communityId`): hành vi cũ, danh sách theo CLB.
/// - Buổi cá nhân (không CLB): danh sách lọc đúng theo `socialSessionId`,
///   chỉ host được tạo trận, ghép đội từ người tham gia có tài khoản (như Web).
///
/// Tái dùng nguyên [ClubStandaloneMatchDialog] (ghép đội thủ công) và
/// [ClubStandaloneMatchResultDialog] (nhập kết quả) của CLB — không viết
/// logic ghép đội mới. Danh sách trận lọc theo `communityId` vì Backend
/// không có liên kết match <-> buổi Social (xem design.md của change
/// `them-tab-tao-tran-trong-social`): trận hiển thị là của cả CLB, không chỉ
/// riêng buổi này.
class SocialMatchTab extends ConsumerStatefulWidget {
  final String? communityId;
  final String sessionId;
  final bool isHost;
  final List<SocialParticipantModel> approvedParticipants;

  /// Lite tournament already created from this session (null = none yet).
  final String? bracketTournamentId;

  const SocialMatchTab({
    super.key,
    this.communityId,
    required this.sessionId,
    this.isHost = false,
    required this.approvedParticipants,
    this.bracketTournamentId,
  });

  @override
  ConsumerState<SocialMatchTab> createState() => _SocialMatchTabState();
}

class _SocialMatchTabState extends ConsumerState<SocialMatchTab> {
  List<ClubSessionMatchModel> _matches = const [];
  bool _isLoading = true;
  String? _loadError;
  Set<String> _clubMemberUserIds = const {};

  late final StandaloneMatchOwner _owner = StandaloneMatchOwner.forSession(
    communityId: widget.communityId,
    sessionId: widget.sessionId,
  );

  @override
  void initState() {
    super.initState();
    _fetchMatches();
    if (!_owner.isPersonalSession) _fetchClubMemberIds();
  }

  Future<void> _fetchMatches() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final repo = ref.read(clubMatchSessionRepositoryProvider);
      final matches = await repo.standaloneMatches(
        _owner.communityId,
        socialSessionId: _owner.socialSessionId,
      );
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
        _owner.communityId!,
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
            (_owner.isPersonalSession || _clubMemberUserIds.contains(p.userId)),
      )
      .map(
        (p) => CommunityMemberModel(
          id: p.id,
          userId: p.userId,
          communityId: _owner.communityId ?? '',
          status: 'JOINED',
          userFullName: p.fullName,
          userAvatarUrl: p.avatarUrl,
          joinedAt: p.joinedAt.toIso8601String(),
        ),
      )
      .toList(growable: false);

  bool _canCreateMatch() {
    if (_owner.isPersonalSession) return widget.isHost;
    final communityId = _owner.communityId!;
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

  /// Reload the session so `bracketTournamentId` (and the View button) show up.
  void _refreshSession() {
    unawaited(
      ref
          .read(socialSessionDetailProvider(widget.sessionId).notifier)
          .refresh(),
    );
  }

  Future<void> _createMatch() async {
    final createdMatch = await ClubStandaloneMatchDialog.show(
      context,
      communityId: _owner.communityId,
      socialSessionId: _owner.socialSessionId,
      preselectedMembers: _preselectedMembers,
      onMatchCreated: _fetchMatches,
      // Only the host of a club-less session can turn it into a bracket.
      allowBracket: _owner.isPersonalSession && widget.isHost,
      onBracketCreated: _refreshSession,
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
      match: socialSessionMatchToMatchModel(match),
      showScoreboardAction: false,
    );
    if (!mounted || action != ClubStandaloneMatchAction.saved) return;
    unawaited(_fetchMatches());
  }

  /// Live scoring (same page the CLB tab opens); refreshes the list on return.
  Future<void> _openScoreboard(ClubSessionMatchModel sm) async {
    final match = socialSessionMatchToMatchModel(sm);
    final repository = ref.read(matchRepositoryProvider);
    if (repository is ApiMatchRepository) repository.primeMatch(match);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => OfficialScorePage(
          tournamentId: '',
          matchId: match.id,
          match: match,
        ),
      ),
    );
    if (mounted) unawaited(_fetchMatches());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final canCreateMatch = _canCreateMatch();
    final notEnoughParticipants = _preselectedMembers.length < 4;
    final bracketId = widget.bracketTournamentId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _owner.isPersonalSession
                      ? 'Các trận đấu được tạo trong buổi này.'
                      : l10n.social_matchListNote,
                  style: TextStyle(fontSize: 11.5, color: colors.textMuted),
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
        if (bracketId != null && bracketId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: OutlinedButton.icon(
              onPressed: () => context.push('/tournaments/$bracketId'),
              icon: const Icon(Icons.account_tree_rounded, size: 18),
              label: Text(l10n.socialBracket_view),
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
                _owner.isPersonalSession
                    ? 'Chưa có trận đấu nào trong buổi này.'
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

  List<ParticipantPlayer> _playersOf(
    List<ClubSessionMatchMemberModel> members,
  ) => [
    for (var i = 0; i < members.length; i++)
      if (members[i].displayName.isNotEmpty)
        ParticipantPlayer(
          slot: i,
          userId: members[i].userId,
          fullName: members[i].displayName,
          avatarUrl: members[i].avatarUrl,
          isGuest: members[i].isMock,
        ),
  ];

  Widget _buildMatchCard(
    ClubSessionMatchModel match,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    final isCompleted = match.status.toUpperCase() == 'COMPLETED';
    final statusColor = isCompleted ? Colors.green.shade700 : AppTheme.primary;
    final sideAWon = isCompleted && match.sideAScore > match.sideBScore;
    final sideBWon = isCompleted && match.sideBScore > match.sideAScore;
    // Backend is the real gate (MATCH_SCORE_PERMISSION_REQUIRED shows in the
    // dialog); the app only hides the buttons for signed-out viewers.
    final canScore =
        !isCompleted &&
        ref.watch(authProvider).status == AuthStatus.authenticated;

    TextStyle scoreStyle(bool won) => TextStyle(
      fontSize: 18,
      fontWeight: won ? FontWeight.w900 : FontWeight.w600,
      color: won ? colors.textPrimary : colors.textMuted,
      height: 1.3,
    );

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ParticipantSideLines(
                        key: ValueKey('match-side-a-${match.id}'),
                        teamName: null,
                        players: _playersOf(match.sideAMembers),
                        won: sideAWon,
                        abbreviate: false,
                      ),
                      const SizedBox(height: 6),
                      ParticipantSideLines(
                        key: ValueKey('match-side-b-${match.id}'),
                        teamName: null,
                        players: _playersOf(match.sideBMembers),
                        won: sideBWon,
                        abbreviate: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                    if (isCompleted) ...[
                      const SizedBox(height: 6),
                      Text('${match.sideAScore}', style: scoreStyle(sideAWon)),
                      Text('${match.sideBScore}', style: scoreStyle(sideBWon)),
                    ],
                  ],
                ),
              ],
            ),
            if (canScore) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: ValueKey('match-quick-entry-${match.id}'),
                      onPressed: () => _openResult(match),
                      icon: const Icon(Icons.bolt_rounded, size: 16),
                      label: Text(l10n.social_matchActionQuickEntry),
                      style: _actionStyle(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      key: ValueKey('match-live-score-${match.id}'),
                      onPressed: () => _openScoreboard(match),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(l10n.social_matchActionLiveScore),
                      style: _actionStyle().copyWith(
                        backgroundColor: const WidgetStatePropertyAll(
                          AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  ButtonStyle _actionStyle() => ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(36)),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
