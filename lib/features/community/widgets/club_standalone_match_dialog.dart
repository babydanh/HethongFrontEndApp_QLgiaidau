import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class ClubStandaloneMatchDialog extends ConsumerStatefulWidget {
  final String communityId;
  final String? clubName;
  final String? sessionId;
  final VoidCallback? onMatchCreated;

  const ClubStandaloneMatchDialog({
    super.key,
    required this.communityId,
    this.clubName,
    this.sessionId,
    this.onMatchCreated,
  });

  static Future<MatchModel?> show(
    BuildContext context, {
    required String communityId,
    String? clubName,
    String? sessionId,
    VoidCallback? onMatchCreated,
  }) {
    return showDialog<MatchModel>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ClubStandaloneMatchDialog(
        communityId: communityId,
        clubName: clubName,
        sessionId: sessionId,
        onMatchCreated: onMatchCreated,
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
  bool _isRanked = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
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
        widget.communityId,
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
    final aCount = _sideAUserIds.length;
    final bCount = _sideBUserIds.length;
    return aCount == 2 && bCount == 2;
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
        sideA: sideAList,
        sideB: sideBList,
        key: requestKey,
        isRanked: _isRanked,
        matchType: sideAList.length == 1 ? 'SINGLES' : 'DOUBLES',
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
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sports_tennis_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.club_createMatchStandalone,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          l10n.club_standaloneMatchDesc,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

            // ─── Tóm tắt phe A vs phe B ───
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SizedBox(
                height: 38,
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

            const SizedBox(height: 4),

            // ─── Danh sách thành viên ───
            Expanded(
              child: _isLoadingMembers
                  ? const Center(child: CircularProgressIndicator())
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
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  const SizedBox(height: 8),
                  Text(
                    'Chạm vào avatar để chuyển Đội A → Đội B → Bỏ chọn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  '${userIds.length}/2',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            names.isEmpty ? 'Chưa chọn VĐV' : names.join(' · '),
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
        if (_sideBUserIds.length < 2) {
          _sideBUserIds.add(userId);
        }
      } else if (_sideBUserIds.contains(userId)) {
        _sideBUserIds.remove(userId);
      } else {
        if (_sideAUserIds.length < 2) {
          _sideAUserIds.add(userId);
        } else if (_sideBUserIds.length < 2) {
          _sideBUserIds.add(userId);
        }
      }
    });
  }
}
