import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';

/// Màn hình Điều phối CLB — dành cho OWNER/ADMIN/MODERATOR.
///
/// Gồm: summary stats, duyệt đơn, mời theo role, lời mời đã gửi, thành viên bị cấm.
class ClubManagementScreen extends ConsumerStatefulWidget {
  final String clubId;
  final bool isOwner;

  const ClubManagementScreen({super.key, required this.clubId, required this.isOwner});

  @override
  ConsumerState<ClubManagementScreen> createState() => _ClubManagementScreenState();
}

class _ClubManagementScreenState extends ConsumerState<ClubManagementScreen> {
  static const _log = AppLogger('ClubManagement');
  List<CommunityMemberModel> _allMembers = [];
  List<CommunityMemberModel> _joinRequests = [];
  List<CommunityMemberModel> _invitedMembers = [];
  List<CommunityMemberModel> _bannedMembers = [];
  bool _isLoading = true;

  // Invite state
  final _searchCtrl = TextEditingController();
  List<UserSearchResult> _searchResults = [];
  bool _isSearching = false;
  String _inviteRole = 'MEMBER';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(communityRepositoryProvider);
      final results = await Future.wait<List<CommunityMemberModel>>([
        repo.getMembers(widget.clubId, limit: 200),
        repo.getJoinRequests(widget.clubId),
      ]);
      final all = results[0];
      final requests = results[1];

      setState(() {
        _allMembers = all;
        _joinRequests = requests.where((r) => r.status == 'PENDING').toList();
        _invitedMembers = all.where((m) => m.status.toUpperCase() == 'INVITED').toList();
        _bannedMembers = all.where((m) => m.status.toUpperCase() == 'BANNED').toList();
        _isLoading = false;
      });
    } catch (e, stack) {
      _log.error('Lỗi tải dữ liệu quản lý CLB', e, stack);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Set<String> get _occupiedUserIds =>
      _allMembers.map((m) => m.userId).where((id) => id.isNotEmpty).toSet();

  int get _activeCount => _allMembers.where((m) => m.status == 'JOINED' || m.status.isEmpty).length;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary), onPressed: () => context.pop()),
        title: Text(l10n.club_managementTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
        actions: _isLoading
            ? []
            : [
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: colors.textSecondary, size: 20),
                  onPressed: _loadData,
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _buildStatsRow(colors),
                  const SizedBox(height: 16),
                  _buildJoinRequestsSection(colors),
                  const SizedBox(height: 16),
                  _buildInviteSection(colors),
                  const SizedBox(height: 16),
                  _buildInvitedSection(colors),
                  const SizedBox(height: 16),
                  _buildBannedSection(colors),
                ],
              ),
            ),
    );
  }

  // ─── Stats ───────────────────────────────────────────────────
  Widget _buildStatsRow(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final stats = [
      (l10n.club_activeMembers, '$_activeCount', colors.textPrimary),
      (l10n.club_pendingRequests, '${_joinRequests.length}', const Color(0xFFF59E0B)),
      (l10n.club_invited, '${_invitedMembers.length}', const Color(0xFF6366F1)),
      (l10n.club_banned, '${_bannedMembers.length}', const Color(0xFFEF4444)),
    ];
    return Row(
      children: stats.map((s) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: s != stats.last ? 8 : 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
          child: Column(
            children: [
              Text(s.$2, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: s.$3)),
              const SizedBox(height: 2),
              Text(s.$1, style: TextStyle(fontSize: 9, color: colors.textMuted, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  // ─── Join Requests ───────────────────────────────────────────
  Widget _buildJoinRequestsSection(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    if (_joinRequests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(l10n.club_joinRequestSection(_joinRequests.length), const Color(0xFFF59E0B), colors),
        const SizedBox(height: 8),
        ..._joinRequests.map((req) => _buildRequestCard(req, colors)),
      ],
    );
  }

  Widget _buildRequestCard(CommunityMemberModel req, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            child: Text((req.userFullName?.isNotEmpty == true ? req.userFullName![0] : '?').toUpperCase(),
                style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w800, fontSize: 14))),
          const SizedBox(width: 12),
          Expanded(child: Text(req.userFullName ?? l10n.dashboard_user, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colors.textPrimary))),
          _actionBtn(l10n.club_approve, const Color(0xFF10B981), () => _review(req, 'APPROVE', colors)),
          const SizedBox(width: 6),
          _actionBtn(l10n.club_reject, colors.textSecondary, () => _review(req, 'REJECT', colors), outlined: true),
        ],
      ),
    );
  }

  Future<void> _review(CommunityMemberModel req, String action, AppColorsExtension colors) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(communityRepositoryProvider).reviewJoinRequest(widget.clubId, req.id.isNotEmpty ? req.id : req.userId, action);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(action == 'APPROVE' ? l10n.club_approvedAlert : l10n.club_rejectedAlert),
          backgroundColor: action == 'APPROVE' ? const Color(0xFF10B981) : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorPrefix}: $e'), backgroundColor: Colors.red));
    }
  }

  // ─── Invite ──────────────────────────────────────────────────
  Widget _buildInviteSection(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(l10n.club_inviteMember, AppTheme.primary, colors),
          const SizedBox(height: 8),
          // Role info
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgSurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.borderLight)),
            child: Text(
              widget.isOwner
                  ? l10n.club_ownerInviteInfo
                  : l10n.club_adminInviteInfo,
              style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          // Role selector (only for owner)
          if (widget.isOwner) ...[
            Text(l10n.club_roleLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.textSecondary)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(color: colors.bgSurface, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  _roleChip(l10n.club_memberChip, 'MEMBER', colors),
                  const SizedBox(width: 4),
                  _roleChip(l10n.club_adminChip, 'MODERATOR', colors),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Search
          TextField(
            controller: _searchCtrl,
            onChanged: _searchUsers,
            style: TextStyle(color: colors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: l10n.club_searchHint,
              hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
              prefixIcon: Icon(Icons.search_rounded, color: colors.textMuted, size: 20),
              suffixIcon: _isSearching
                  ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                  : null,
              filled: true,
              fillColor: colors.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          // Search results
          if (_searchResults.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: colors.borderLight),
                itemBuilder: (_, i) {
                  final u = _searchResults[i];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(radius: 16,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      child: Text(u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 12))),
                    title: Text(u.fullName, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: u.email != null ? Text(u.email!, style: TextStyle(color: colors.textMuted, fontSize: 11)) : null,
                    trailing: GestureDetector(
                      onTap: () => _inviteUser(u, colors),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(l10n.club_inviteButton, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 11)),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_searchCtrl.text.trim().length >= 2 && _searchResults.isEmpty && !_isSearching)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(l10n.club_noUsersOrInClub, style: TextStyle(color: colors.textMuted, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _roleChip(String label, String role, AppColorsExtension colors) {
    final selected = _inviteRole == role;
    final enabled = widget.isOwner || role == 'MEMBER';
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? () => setState(() => _inviteRole = role) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.bgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: selected ? colors.textPrimary : (enabled ? colors.textSecondary : colors.textMuted),
            )),
          ),
        ),
      ),
    );
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().length < 2) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/users/search', queryParameters: {'q': query.trim()});
      final raw = response.data;
      final data = raw is Map ? (raw['data'] as List<dynamic>? ?? []) : (raw as List<dynamic>? ?? []);
      final occupied = _occupiedUserIds;
      setState(() {
        _searchResults = data
            .map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>))
            .where((u) => !occupied.contains(u.id))
            .toList();
        _isSearching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _inviteUser(UserSearchResult user, AppColorsExtension colors) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(communityRepositoryProvider).inviteMember(widget.clubId, user.id, role: _inviteRole);
      _searchCtrl.clear();
      setState(() => _searchResults = []);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.club_inviteSent), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorPrefix}: $e'), backgroundColor: Colors.red));
    }
  }

  // ─── Invited List ─────────────────────────────────────────────
  Widget _buildInvitedSection(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    if (_invitedMembers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(l10n.club_invitedSection(_invitedMembers.length), const Color(0xFF6366F1), colors),
        const SizedBox(height: 8),
        ..._invitedMembers.map((m) => _buildInvitedCard(m, colors)),
      ],
    );
  }

  Widget _buildInvitedCard(CommunityMemberModel m, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
            child: Text((m.userFullName?.isNotEmpty == true ? m.userFullName![0] : '?').toUpperCase(),
                style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w800, fontSize: 12))),
          const SizedBox(width: 12),
          Expanded(child: Text(m.userFullName ?? l10n.dashboard_user, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colors.textPrimary))),
          GestureDetector(
            onTap: () async {
              try {
                await ref.read(communityRepositoryProvider).removeMember(widget.clubId, m.userId);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.club_revokeInvite),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorPrefix}: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: colors.bgSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
              child: Text(l10n.club_cancelInvite, style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w700, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Banned List ──────────────────────────────────────────────
  Widget _buildBannedSection(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    if (_bannedMembers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(l10n.club_bannedSection(_bannedMembers.length), const Color(0xFFEF4444), colors),
        const SizedBox(height: 8),
        ..._bannedMembers.map((m) => _buildBannedCard(m, colors)),
      ],
    );
  }

  Widget _buildBannedCard(CommunityMemberModel m, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
            child: Text((m.userFullName?.isNotEmpty == true ? m.userFullName![0] : '?').toUpperCase(),
                style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 12))),
          const SizedBox(width: 12),
          Expanded(child: Text(m.userFullName ?? l10n.dashboard_user, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colors.textPrimary))),
          GestureDetector(
            onTap: () async {
              try {
                await ref.read(communityRepositoryProvider).unbanMember(widget.clubId, m.userId);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.club_unbanned),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorPrefix}: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(8)),
              child: Text(l10n.club_unban, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────
  Widget _sectionHeader(String title, Color accent, AppColorsExtension colors) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.textSecondary)),
      ],
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap, {bool outlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(8),
          border: outlined ? Border.all(color: color.withValues(alpha: 0.3)) : null,
        ),
        child: Text(label, style: TextStyle(
          color: outlined ? color : Colors.white,
          fontWeight: FontWeight.w800, fontSize: 11,
        )),
      ),
    );
  }
}
