import 'package:app_quanly_giaidau/features/community/widgets/community_skeletons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:app_quanly_giaidau/features/social/widgets/match_tab/social_bracket_form.dart';

class ClubStandaloneMatchDialog extends ConsumerStatefulWidget {
  /// Đúng một trong [communityId] / [socialSessionId] (buổi Social cá nhân
  /// không gắn CLB; khi đó bắt buộc truyền [preselectedMembers]).
  final String? communityId;
  final String? socialSessionId;
  final String? clubName;
  final String? sessionId;
  final VoidCallback? onMatchCreated;

  /// Danh sách người để chọn đã biết trước (vd: người tham gia đã duyệt của
  /// một buổi Social gắn CLB). `null` = hành vi cũ: tự tải toàn bộ thành viên
  /// CLB đã JOIN qua `communityRepositoryProvider`.
  final List<CommunityMemberModel>? preselectedMembers;

  /// Host của buổi Social cá nhân (không CLB) có thể chọn thể thức Bracket.
  /// Chỉ có tác dụng khi [socialSessionId] có giá trị.
  final bool allowBracket;

  /// Gọi sau khi tạo (hoặc gặp sẵn) bracket, trước khi mở màn giải.
  final VoidCallback? onBracketCreated;

  const ClubStandaloneMatchDialog({
    super.key,
    this.communityId,
    this.socialSessionId,
    this.clubName,
    this.sessionId,
    this.onMatchCreated,
    this.preselectedMembers,
    this.allowBracket = false,
    this.onBracketCreated,
  });

  static Future<MatchModel?> show(
    BuildContext context, {
    String? communityId,
    String? socialSessionId,
    String? clubName,
    String? sessionId,
    VoidCallback? onMatchCreated,
    List<CommunityMemberModel>? preselectedMembers,
    bool allowBracket = false,
    VoidCallback? onBracketCreated,
  }) {
    return showDialog<MatchModel>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ClubStandaloneMatchDialog(
        communityId: communityId,
        socialSessionId: socialSessionId,
        clubName: clubName,
        sessionId: sessionId,
        onMatchCreated: onMatchCreated,
        preselectedMembers: preselectedMembers,
        allowBracket: allowBracket,
        onBracketCreated: onBracketCreated,
      ),
    );
  }

  @override
  ConsumerState<ClubStandaloneMatchDialog> createState() =>
      _ClubStandaloneMatchDialogState();
}

class _ClubStandaloneMatchDialogState
    extends ConsumerState<ClubStandaloneMatchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<CommunityMemberModel> _allMembers = [];
  bool _isLoadingMembers = true;
  String? _loadError;
  String _searchQuery = '';

  final Set<String> _sideAUserIds = {};
  final Set<String> _sideBUserIds = {};
  bool _isCreating = false;
  // Mặc định không tính điểm ELO cho trận riêng
  // bool _isRanked = true;
  final bool _isRanked = false;

  /// 'DOUBLES' by default; 'SINGLES' = one player per side.
  String _matchType = 'DOUBLES';
  bool _bracketMode = false;

  int get _sideSize => _matchType == 'SINGLES' ? 1 : 2;
  bool get _bracketAvailable =>
      widget.allowBracket && (widget.socialSessionId ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    final preselected = widget.preselectedMembers;
    if (preselected != null || (widget.communityId ?? '').isEmpty) {
      final uniqueMembers = <String, CommunityMemberModel>{};
      for (final member in preselected ?? const <CommunityMemberModel>[]) {
        final userId = member.userId.trim();
        if (userId.isNotEmpty) uniqueMembers[userId] = member;
      }
      _allMembers = uniqueMembers.values.toList(growable: false);
      _isLoadingMembers = false;
    } else {
      _loadMembers();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoadingMembers = true;
      _loadError = null;
    });

    try {
      final repo = ref.read(communityRepositoryProvider);
      final members = await repo.getMembers(
        widget.communityId!,
        limit: 100,
        status: 'JOINED',
      );
      if (mounted) {
        setState(() {
          final uniqueMembers = <String, CommunityMemberModel>{};
          for (final member in members) {
            final userId = member.userId.trim();
            if (userId.isNotEmpty) uniqueMembers[userId] = member;
          }
          _allMembers = uniqueMembers.values.toList(growable: false);
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
          _loadError = e.toString();
        });
      }
    }
  }

  List<CommunityMemberModel> get _filteredMembers {
    if (_searchQuery.trim().isEmpty) return _allMembers;
    final q = _searchQuery.trim().toLowerCase();
    return _allMembers.where((m) {
      final name = (m.userFullName ?? '').toLowerCase();
      final email = (m.userEmail ?? '').toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  bool get _canSubmit {
    if (_isCreating) return false;
    return _sideAUserIds.length == _sideSize &&
        _sideBUserIds.length == _sideSize;
  }

  void _setMatchType(String matchType) {
    if (matchType == _matchType) return;
    setState(() {
      _matchType = matchType;
      _sideAUserIds.clear();
      _sideBUserIds.clear();
    });
  }

  void _openBracket(String tournamentId) {
    // Capture the router before the dialog's context is popped.
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    widget.onBracketCreated?.call();
    router.push('/tournaments/$tournamentId');
  }

  Future<void> _handleCreateMatch() async {
    if (!_canSubmit) return;
    setState(() => _isCreating = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final requestKey = const Uuid().v4();
      final sideAList = _sideAUserIds.toList();
      final sideBList = _sideBUserIds.toList();

      // Standalone means exactly that: no synthetic club session is created
      // and no participant is moved into one behind the user's back.
      final sessionRepo = ref.read(clubMatchSessionRepositoryProvider);
      final createdSessionMatch = await sessionRepo.createStandaloneMatch(
        communityId: widget.communityId,
        socialSessionId: widget.socialSessionId,
        sideA: sideAList,
        sideB: sideBList,
        key: requestKey,
        isRanked: _isRanked,
        matchType: _matchType,
      );

      final sideAMembersInfo = createdSessionMatch.sideAMembers
          .map(
            (m) => MatchMemberInfo(
              userId: m.userId,
              fullName: m.displayName,
              avatarUrl: m.avatarUrl,
              isMock: m.isMock,
            ),
          )
          .toList(growable: false);

      final sideBMembersInfo = createdSessionMatch.sideBMembers
          .map(
            (m) => MatchMemberInfo(
              userId: m.userId,
              fullName: m.displayName,
              avatarUrl: m.avatarUrl,
              isMock: m.isMock,
            ),
          )
          .toList(growable: false);

      final sideAName = createdSessionMatch.sideANames.join(' · ').trim();
      final sideBName = createdSessionMatch.sideBNames.join(' · ').trim();

      final matchModel = MatchModel(
        id: createdSessionMatch.id,
        isStandaloneMatch: true,
        tournamentName: l10n.club_standaloneMatch,
        round: 0,
        matchNumber: 1,
        team1Id: 'SIDE_A',
        team2Id: 'SIDE_B',
        team1Name: sideAName.isEmpty ? 'Đội A' : sideAName,
        team2Name: sideBName.isEmpty ? 'Đội B' : sideBName,
        score1: 0,
        score2: 0,
        sets: [const SetScore(score1: 0, score2: 0)],
        winnerId: '',
        loserId: '',
        status: createdSessionMatch.status,
        bracketPosition: const BracketPosition(round: 1, position: 1),
        scoreDetails: createdSessionMatch.scoreDetails,
        team1Members: sideAMembersInfo.map((m) => m.fullName).toList(),
        team2Members: sideBMembersInfo.map((m) => m.fullName).toList(),
        team1MemberInfos: sideAMembersInfo,
        team2MemberInfos: sideBMembersInfo,
        team1LogoUrl: sideAMembersInfo.length == 1
            ? sideAMembersInfo.first.avatarUrl
            : null,
        team2LogoUrl: sideBMembersInfo.length == 1
            ? sideBMembersInfo.first.avatarUrl
            : null,
        sportKey: createdSessionMatch.sportKey,
        tournamentConfig: createdSessionMatch.tournamentConfig,
        sportRules: createdSessionMatch.sportRules,
        revision: createdSessionMatch.revision,
        updatedAt: DateTime.now(),
      );

      // Prime match cache
      final matchRepo = ref.read(matchRepositoryProvider);
      if (matchRepo is ApiMatchRepository) {
        matchRepo.primeMatch(matchModel);
      }

      widget.onMatchCreated?.call();

      if (!mounted) return;
      // Tạo record trước; caller sẽ mở popup nhập kết quả ngay sau khi
      // create dialog đã đóng hoàn toàn.
      Navigator.of(context).pop(matchModel);
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? (e.response?.data?['message']?.toString() ??
                        e.message ??
                        '')
                  : e.toString(),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: colors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.club_createMatchStandalone,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            _buildModeSelectors(l10n, colors),

            if (_bracketMode && _bracketAvailable)
              Expanded(
                child: _isLoadingMembers
                    ? const CommunityListSkeleton(itemCount: 6)
                    : SocialBracketForm(
                        key: ValueKey(_matchType),
                        sessionId: widget.socialSessionId!,
                        members: _allMembers,
                        matchType: _matchType,
                        onDone: _openBracket,
                      ),
              )
            else ...[
                // ─── Tóm tắt phe A vs phe B ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSideSummaryCard(
                          title: 'ĐỘI A',
                          userIds: _sideAUserIds,
                          badgeColor: const Color(0xFF2563EB),
                          colors: colors,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildSideSummaryCard(
                          title: 'ĐỘI B',
                          userIds: _sideBUserIds,
                          badgeColor: const Color(0xFFEA580C),
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Thanh tìm kiếm gọn gàng ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(fontSize: 13, color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: l10n.club_searchMemberHint,
                        hintStyle: TextStyle(fontSize: 12, color: colors.textMuted),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 17,
                          color: colors.textMuted,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 15),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        fillColor: colors.bgSurface,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                // ─── Danh sách thành viên ───
                Expanded(
                  child: _isLoadingMembers
                      ? const CommunityListSkeleton(itemCount: 6)
                      : _loadError != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _loadError!,
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              TextButton(
                                onPressed: _loadMembers,
                                child: Text(l10n.infoRetry),
                              ),
                            ],
                          ),
                        )
                      : _filteredMembers.isEmpty
                      ? Center(
                          child: Text(
                            l10n.club_noMembersFound,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          itemCount: _filteredMembers.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final member = _filteredMembers[index];
                            return _buildMemberRow(member, colors);
                          },
                        ),
                ),

                const Divider(height: 1),

                // ─── Bottom Actions ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ẩn option tính điểm ELO khỏi modal (comment lại theo yêu cầu)
                      /*
                      // Checkbox ELO có label giải thích
                      InkWell(
                        onTap: () => setState(() => _isRanked = !_isRanked),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _isRanked,
                                  onChanged: (val) =>
                                      setState(() => _isRanked = val ?? true),
                                  activeColor: AppTheme.primary,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tính điểm ELO cho trận này',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      */
                      // Nút Tạo trận đấu với trạng thái disabled rõ ràng
                      SizedBox(
                        height: 44,
                        child: FilledButton(
                          onPressed: _canSubmit ? _handleCreateMatch : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            disabledBackgroundColor:
                                AppTheme.primary.withValues(alpha: 0.25),
                            disabledForegroundColor:
                                Colors.white.withValues(alpha: 0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isCreating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l10n.club_createMatchStandalone,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelectors(AppLocalizations l10n, dynamic colors) {
    // Compact segments so both toggles fit on one row.
    final segmentStyle = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 6),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
    final matchTypeToggle = SegmentedButton<String>(
      showSelectedIcon: false,
      style: segmentStyle,
      segments: [
        ButtonSegment(
          value: 'SINGLES',
          label: Text(l10n.socialBracket_matchSingles),
        ),
        ButtonSegment(
          value: 'DOUBLES',
          label: Text(l10n.socialBracket_matchDoubles),
        ),
      ],
      selected: {_matchType},
      onSelectionChanged: _isCreating
          ? null
          : (value) => _setMatchType(value.first),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          if (_bracketAvailable) ...[
            Expanded(
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                style: segmentStyle,
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.socialBracket_formatSingle),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.socialBracket_formatBracket),
                  ),
                ],
                selected: {_bracketMode},
                onSelectionChanged: _isCreating
                    ? null
                    : (value) => setState(() => _bracketMode = value.first),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(child: matchTypeToggle),
        ],
      ),
    );
  }

  Widget _buildSideSummaryCard({
    required String title,
    required Set<String> userIds,
    required Color badgeColor,
    required dynamic colors,
  }) {
    final names = _allMembers
        .where((m) => userIds.contains(m.userId))
        .map(
          (m) => m.userFullName?.trim().isNotEmpty == true
              ? m.userFullName!.trim()
              : 'VĐV',
        )
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${userIds.length}/$_sideSize',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            names.isEmpty ? '—' : names.join(' · '),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: names.isEmpty ? colors.textMuted : colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(CommunityMemberModel member, dynamic colors) {
    final isSideA = _sideAUserIds.contains(member.userId);
    final isSideB = _sideBUserIds.contains(member.userId);
    final fullName = member.userFullName?.trim().isNotEmpty == true
        ? member.userFullName!.trim()
        : 'Thành viên';
    final accentColor = isSideA
        ? const Color(0xFF2563EB)
        : isSideB
            ? const Color(0xFFEA580C)
            : null;

    return InkWell(
      onTap: () => _cycleMemberTeam(member.userId),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            // Avatar với viền và badge A/B khi chọn
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor ?? colors.border,
                      width: accentColor != null ? 2.5 : 1.2,
                    ),
                  ),
                  child: ClipOval(
                    child: member.userAvatarUrl?.trim().isNotEmpty == true
                        ? Image.network(
                            member.userAvatarUrl!.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _avatarFallback(fullName, accentColor ?? AppTheme.primary),
                          )
                        : _avatarFallback(fullName, accentColor ?? AppTheme.primary),
                  ),
                ),
                if (accentColor != null)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                        border: Border.all(color: colors.bgCard, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isSideA ? 'A' : 'B',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Tên thành viên & chức vụ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fullName,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (member.role != 'MEMBER')
                    Text(
                      member.role == 'OWNER' ? 'Chủ nhiệm' : 'Quản trị viên',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: member.role == 'OWNER'
                            ? Colors.amber.shade800
                            : Colors.blue.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Badge trạng thái đội
            if (accentColor != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSideA ? 'Đội A' : 'Đội B',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name, Color color) {
    return Container(
      color: color.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  void _cycleMemberTeam(String userId) {
    setState(() {
      if (_sideAUserIds.contains(userId)) {
        _sideAUserIds.remove(userId);
        if (_sideBUserIds.length < _sideSize) {
          _sideBUserIds.add(userId);
        }
      } else if (_sideBUserIds.contains(userId)) {
        _sideBUserIds.remove(userId);
      } else {
        if (_sideAUserIds.length < _sideSize) {
          _sideAUserIds.add(userId);
        } else if (_sideBUserIds.length < _sideSize) {
          _sideBUserIds.add(userId);
        }
      }
    });
  }
}
