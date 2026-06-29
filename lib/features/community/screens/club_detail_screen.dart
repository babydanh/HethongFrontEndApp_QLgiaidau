import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

class ClubDetailScreen extends ConsumerStatefulWidget {
  final String clubId;
  const ClubDetailScreen({super.key, required this.clubId});

  @override
  ConsumerState<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends ConsumerState<ClubDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _log = AppLogger('ClubDetail');
  late TabController _tabController;
  CommunityMemberModel? _myMembership;
  bool _isJoinLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMembership());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMembership() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      setState(() => _myMembership = null);
      return;
    }
    try {
      final members = await ref.read(communityRepositoryProvider).getMembers(widget.clubId);
      // Try to match by userId from profile (JWT users)
      final profile = ref.read(userProfileProvider).asData?.value;
      final myUserId = profile?.id;
      CommunityMemberModel? found;
      if (myUserId != null && myUserId.isNotEmpty) {
        found = members.where((m) => m.userId == myUserId).firstOrNull;
      }
      // Fallback: take first JOINED/PENDING member
      found ??= members.where((m) => m.status == 'JOINED' || m.status == 'PENDING').firstOrNull;
      if (mounted) setState(() => _myMembership = found);
    } catch (e, stack) {
      _log.error('Failed to fetch membership', e, stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(communityDetailProvider(widget.clubId));

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      body: clubAsync.when(
        data: (club) {
          final activeClub = club ?? _fallbackClub();
          return _buildContent(activeClub);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, st) {
          _log.error('Lỗi load club detail', e, st);
          return _buildContent(_fallbackClub());
        },
      ),
    );
  }

  Community _fallbackClub() {
    return Community(
      id: widget.clubId,
      name: "CLB Cầu lông ABC",
      description: "Câu lạc bộ cầu lông hàng đầu Việt Nam với hơn 10 năm hoạt động. "
          "Chúng tôi tổ chức các giải đấu thường xuyên và có các huấn luyện viên chuyên nghiệp.",
      memberCount: 128,
      sports: const ["Cầu lông"],
      locationAddress: "Hà Nội",
      joinMode: "OPEN",
    );
  }

  // ─── Helpers ───
  Color _sportColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('badminton') || n.contains('cầu lông')) return const Color(0xFF0284C7);
    if (n.contains('tennis')) return const Color(0xFFEA580C);
    if (n.contains('pickleball')) return const Color(0xFF059669);
    return const Color(0xFF0284C7);
  }

  String _sportEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('badminton') || n.contains('cầu lông')) return '🏸';
    if (n.contains('tennis')) return '🎾';
    if (n.contains('pickleball')) return '🏓';
    return '🏆';
  }

  bool get _isMember => _myMembership?.status == 'JOINED';
  bool get _isPending => _myMembership?.status == 'PENDING';

  Widget _buildContent(Community club) {
    final colors = context.colors;
    final sportName = club.sports.isNotEmpty ? club.sports.first : "Thể thao";
    final Color sColor = _sportColor(sportName);
    final String emoji = _sportEmoji(sportName);

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          pinned: true,
          elevation: 0,
          backgroundColor: colors.bgDark,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.bgCard.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 20),
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(club.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          centerTitle: true,
        ),
        SliverToBoxAdapter(child: _buildClubBanner(club, colors, sColor, emoji)),
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            color: colors.bgDark,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isJoinLoading ? null : () => _handleJoinAction(),
                    icon: _isJoinLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(_getJoinIcon(), size: 18),
                    label: Text(_getJoinLabel(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    style: FilledButton.styleFrom(
                      backgroundColor: _getJoinBgColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
                  child: IconButton(
                    icon: Icon(Icons.share_outlined, size: 18, color: colors.textPrimary),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(tabController: _tabController, colors: colors),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAboutTab(club, colors),
          _buildTournamentsTab(colors),
          _buildMembersTab(colors),
          _buildGalleryTab(colors),
          _buildRankingsTab(colors),
        ],
      ),
    );
  }

  // ─── Join button helpers ───
  IconData _getJoinIcon() {
    if (_isMember) return Icons.check_rounded;
    if (_isPending) return Icons.hourglass_empty_rounded;
    return Icons.add_rounded;
  }

  String _getJoinLabel() {
    if (_isJoinLoading) return 'Đang xử lý...';
    if (_isMember) return 'Đã tham gia';
    if (_isPending) return 'Đang chờ duyệt';
    return 'Tham gia câu lạc bộ';
  }

  Color? _getJoinBgColor() {
    if (_isMember) return const Color(0xFF059669);
    if (_isPending) return Colors.grey;
    return AppTheme.primary;
  }

  Future<void> _handleJoinAction() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      context.push('/login');
      return;
    }
    if (_isMember || _isPending) return;

    setState(() => _isJoinLoading = true);
    try {
      final ok = await ref.read(communityRepositoryProvider).joinCommunity(widget.clubId);
      if (ok && mounted) {
        _log.success('Tham gia CLB thành công');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tham gia câu lạc bộ thành công!'), backgroundColor: Color(0xFF059669)),
        );
        await _fetchMembership();
      } else if (mounted) {
        _log.warning('Tham gia CLB thất bại');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tham gia câu lạc bộ'), backgroundColor: Colors.red),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi khi tham gia CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoinLoading = false);
    }
  }

  Widget _buildClubBanner(Community club, AppColorsExtension colors, Color sColor, String emoji) {
    final bool hasBanner = club.bannerUrl != null && club.bannerUrl!.isNotEmpty;
    final sportName = club.sports.isNotEmpty ? club.sports.first : "Thể thao";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 240, width: double.infinity, color: colors.bgCard,
              child: hasBanner
                  ? Image.network(club.bannerUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _bannerGradient(sColor, emoji))
                  : _bannerGradient(sColor, emoji),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildSportTag(sportName, sColor),
                  const SizedBox(width: 8),
                  _buildJoinModeBadge(club.joinMode),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                club.name.toUpperCase(),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: colors.textPrimary, height: 1.35, letterSpacing: -0.3),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: club.logoUrl != null && club.logoUrl!.isNotEmpty
                          ? Image.network(club.logoUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _logoSportBg(sColor, emoji))
                          : _logoSportBg(sColor, emoji),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("CÂU LẠC BỘ", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 0.5)),
                            if (club.status == 'ACTIVE') const SizedBox(width: 6),
                            if (club.status == 'ACTIVE') Icon(Icons.verified_rounded, size: 14, color: sColor),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12, runSpacing: 6,
                          children: [
                            _iconText(Icons.location_on_outlined, club.locationAddress ?? "Việt Nam", colors),
                            _iconText(Icons.group_rounded, "${club.memberCount} Thành viên", colors),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if ((club.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(club.description ?? '', style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.5)),
              ],
              const SizedBox(height: 16),
              Divider(color: colors.border, height: 1.0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSportTag(String sportName, Color sColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: sColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: sColor.withValues(alpha: 0.2))),
      child: Text(sportName.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: sColor, letterSpacing: 0.8)),
    );
  }

  Widget _buildJoinModeBadge(String mode) {
    String label = 'Tự do';
    Color color = const Color(0xFF059669);
    if (mode == 'INVITE_ONLY') { label = 'Chỉ mời'; color = const Color(0xFFE11D48); }
    else if (mode == 'APPROVAL') { label = 'Xét duyệt'; color = const Color(0xFFF59E0B); }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.8)),
    );
  }

  Widget _iconText(IconData icon, String text, AppColorsExtension colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
      ],
    );
  }

  Widget _bannerGradient(Color c, String emoji) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, c.withValues(alpha: 0.6), context.colors.bgDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(child: Text(emoji, style: TextStyle(fontSize: 80, color: Colors.white.withValues(alpha: 0.12)))),
    );
  }

  Widget _logoSportBg(Color c, String emoji) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c, c.withValues(alpha: 0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
    );
  }

  // ════════════════════════════════════
  //  TAB 1: GIỚI THIỆU
  // ════════════════════════════════════
  Widget _buildAboutTab(Community club, AppColorsExtension colors) {
    final sportName = club.sports.isNotEmpty ? club.sports.first : "Thể thao";
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (club.description != null && club.description!.isNotEmpty) ...[
          _sectionTitle("GIỚI THIỆU", colors),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
            child: Text(club.description!, style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.6)),
          ),
          const SizedBox(height: 24),
        ],
        _sectionTitle("THÔNG TIN", colors),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
          child: Column(
            children: [
              _infoRow(Icons.people_rounded, "Số thành viên", "${club.memberCount}", colors),
              _divider(colors),
              _infoRow(Icons.location_on_rounded, "Địa điểm", club.locationAddress ?? "Chưa cập nhật", colors),
              _divider(colors),
              _infoRow(Icons.how_to_reg_rounded, "Hình thức tham gia",
                  club.joinMode == "OPEN" ? "Tự do" : club.joinMode == "APPROVAL" ? "Cần phê duyệt" : "Chỉ mời", colors),
              _divider(colors),
              _infoRow(Icons.sports_rounded, "Môn thi đấu", sportName, colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, AppColorsExtension colors) {
    return Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colors.textSecondary, letterSpacing: 0.5));
  }

  Widget _infoRow(IconData icon, String label, String value, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.primary, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, color: colors.textPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(AppColorsExtension colors) => Padding(
    padding: const EdgeInsets.only(left: 64),
    child: Divider(height: 1, color: colors.borderLight),
  );

  // ════════════════════════════════════
  //  TAB 2: GIẢI ĐẤU
  // ════════════════════════════════════
  Widget _buildTournamentsTab(AppColorsExtension colors) {
    final tourneysAsync = ref.watch(communityTournamentsProvider(widget.clubId));
    return tourneysAsync.when(
      data: (tourneys) {
        if (tourneys.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: 48, color: colors.textMuted),
                const SizedBox(height: 12),
                Text("Chưa có giải đấu nào", style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.push('/club/${widget.clubId}/create-tournament'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("Tạo giải đấu"),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tourneys.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.icon(
                  onPressed: () => context.push('/club/${widget.clubId}/create-tournament'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("Tạo giải đấu mới"),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              );
            }
            return _buildTourneyCard(tourneys[i - 1], colors);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        _log.error('Lỗi tải giải đấu của CLB', e, st);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text("Lỗi tải dữ liệu", style: TextStyle(color: colors.textSecondary, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTourneyCard(CommunityTournamentModel t, AppColorsExtension colors) {
    String statusLabel;
    Color statusColor;
    switch (t.status) {
      case 'REGISTRATION_OPEN':
      case 'registration':
        statusLabel = 'Đăng ký';
        statusColor = Colors.blue;
        break;
      case 'ONGOING':
      case 'in_progress':
        statusLabel = 'Thi đấu';
        statusColor = Colors.green;
        break;
      case 'COMPLETED':
      case 'completed':
        statusLabel = 'Hoàn thành';
        statusColor = Colors.grey;
        break;
      default:
        statusLabel = t.status;
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.emoji_events_rounded, color: AppTheme.primary, size: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text("${t.teamCount}/${t.maxTeams} đội", style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                    if (t.startDate != null) ...[
                      const SizedBox(width: 8),
                      Container(width: 3, height: 3, decoration: BoxDecoration(color: colors.textMuted, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(t.startDate!, style: TextStyle(fontSize: 11, color: colors.textMuted)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(statusLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════
  //  TAB 3: THÀNH VIÊN
  // ════════════════════════════════════
  Widget _buildMembersTab(AppColorsExtension colors) {
    final membersAsync = ref.watch(communityMembersProvider(widget.clubId));
    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text("Chưa có thành viên", style: TextStyle(color: colors.textSecondary, fontSize: 14)),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, i) => _buildMemberItem(members[i], colors),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        _log.error('Lỗi tải thành viên CLB', e, st);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text("Lỗi tải danh sách", style: TextStyle(color: colors.textSecondary, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberItem(CommunityMemberModel m, AppColorsExtension colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: Text(
              (m.userFullName?.isNotEmpty == true ? m.userFullName![0] : '?').toUpperCase(),
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.userFullName ?? 'Thành viên', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colors.textPrimary)),
                if (m.role != 'MEMBER')
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: m.role == 'OWNER' ? Colors.amber.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      m.role == 'OWNER' ? 'Chủ sở hữu' : 'Quản trị viên',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                        color: m.role == 'OWNER' ? Colors.amber.shade800 : Colors.blue),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════
  //  TAB 4: ẢNH (Gallery)
  // ════════════════════════════════════
  Widget _buildGalleryTab(AppColorsExtension colors) {
    final galleryAsync = ref.watch(communityGalleryProvider(widget.clubId));
    return galleryAsync.when(
      data: (images) {
        if (images.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text("Chưa có ảnh nào", style: TextStyle(color: colors.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Text("Ảnh hoạt động của CLB sẽ hiển thị tại đây", style: TextStyle(color: colors.textMuted, fontSize: 12)),
            ],
          ));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: images.length,
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => _showImagePreview(images[i].imageUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                images[i].imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: colors.bgSurface,
                  child: Icon(Icons.broken_image_rounded, color: colors.textMuted, size: 28),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(color: colors.bgSurface, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                },
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        _log.error('Lỗi tải gallery', e, st);
        return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text("Không thể tải ảnh", style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          ],
        ));
      },
    );
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(url, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 200, color: Colors.black,
                child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════
  //  TAB 5: BẢNG XẾP HẠNG (Rankings)
  // ════════════════════════════════════
  Widget _buildRankingsTab(AppColorsExtension colors) {
    final rankingsAsync = ref.watch(communityRankingsProvider(widget.clubId));
    return rankingsAsync.when(
      data: (rankings) {
        if (rankings.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.leaderboard_outlined, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text("Chưa có xếp hạng", style: TextStyle(color: colors.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Text("Tham gia giải đấu để có ELO", style: TextStyle(color: colors.textMuted, fontSize: 12)),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rankings.length,
          itemBuilder: (context, i) {
            final r = rankings[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: i < 3 ? [Colors.amber, const Color(0xFF94A3B8), const Color(0xFFCD7F32)][i].withValues(alpha: 0.15) : colors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w900,
                        color: i < 3 ? [Colors.amber, const Color(0xFF94A3B8), const Color(0xFFCD7F32)][i] : colors.textSecondary,
                      ),
                    )),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      r.fullName.isNotEmpty ? r.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(r.fullName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: r.eloPoints >= 1000 ? Colors.amber.withValues(alpha: 0.12) : AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.diamond_outlined, size: 10, color: r.eloPoints >= 1000 ? Colors.amber : AppTheme.primary),
                        const SizedBox(width: 4),
                        Text('${r.eloPoints}', style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w900,
                          color: r.eloPoints >= 1000 ? Colors.amber : AppTheme.primary,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        _log.error('Lỗi tải bảng xếp hạng', e, st);
        return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text("Không thể tải xếp hạng", style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          ],
        ));
      },
    );
  }
}

// ═══════════════════════════════════════════
//  TAB BAR DELEGATE
// ═══════════════════════════════════════════
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final AppColorsExtension colors;

  _TabBarDelegate({required this.tabController, required this.colors});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: colors.bgDark,
      child: TabBar(
        controller: tabController,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 3.0,
        labelColor: AppTheme.primary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        isScrollable: true,
        tabs: const [
          Tab(text: "Giới thiệu"),
          Tab(text: "Giải đấu"),
          Tab(text: "Thành viên"),
          Tab(text: "Ảnh"),
          Tab(text: "Xếp hạng"),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48.0;
  @override
  double get minExtent => 48.0;
  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
