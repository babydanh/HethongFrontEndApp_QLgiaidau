import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Admin quản lý câu lạc bộ — danh sách tất cả CLB, filter theo status, tìm kiếm.
///
/// Actions:
/// - Xem chi tiết CLB
/// - Duyệt CLB (PENDING → ACTIVE)
/// - Từ chối / Vô hiệu hoá CLB
/// - Xoá CLB
class AdminClubsScreen extends ConsumerStatefulWidget {
  const AdminClubsScreen({super.key});

  @override
  ConsumerState<AdminClubsScreen> createState() => _AdminClubsScreenState();
}

class _AdminClubsScreenState extends ConsumerState<AdminClubsScreen> {
  String _statusFilter = 'all'; // all, ACTIVE, PENDING, REJECTED
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n?.adminClubsTitle ?? 'Club management',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(colors, l10n),
          // Status filter chips
          _buildFilterChips(colors, l10n),
          // Club list
          Expanded(child: _buildClubList(colors, l10n)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppColorsExtension colors, AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: l10n?.adminClubsSearchHint ?? 'Search clubs...',
          hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: colors.textMuted, size: 20),
          filled: true,
          fillColor: colors.bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips(AppColorsExtension colors, AppLocalizations? l10n) {
    final filters = [
      ('all', l10n?.adminClubsFilterAll ?? 'All', colors.textPrimary),
      ('ACTIVE', l10n?.adminClubsFilterActive ?? 'Active', const Color(0xFF10B981)),
      ('PENDING', l10n?.adminClubsFilterPending ?? 'Pending', const Color(0xFFF59E0B)),
      ('INACTIVE', l10n?.adminClubsFilterInactive ?? 'Disabled', const Color(0xFFEF4444)),
      ('REJECTED', l10n?.adminClubsFilterRejected ?? 'Rejected', const Color(0xFFEF4444)),
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final selected = _statusFilter == f.$1;
          return GestureDetector(
            onTap: () => setState(() => _statusFilter = f.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? f.$3.withValues(alpha: 0.12) : colors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? f.$3.withValues(alpha: 0.4) : colors.border),
              ),
              child: Text(
                f.$2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? f.$3 : colors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClubList(AppColorsExtension colors, AppLocalizations? l10n) {
    // Dùng pendingCommunitiesProvider cho PENDING, getAll cho phần còn lại
    // Tạm thời dùng FutureProvider tự build
    final clubsAsync = ref.watch(_adminClubsProvider);

    return clubsAsync.when(
      data: (clubs) {
        final filtered = clubs.where((c) {
          if (_statusFilter != 'all') {
            if (_statusFilter == 'INACTIVE' && (c.status == 'INACTIVE' || c.status == 'REJECTED' || c.status == 'DEACTIVATED' || c.status == 'SUSPENDED')) {
              // match
            } else if (_statusFilter == 'REJECTED' && (c.status == 'REJECTED' || c.status == 'INACTIVE' || c.status == 'DEACTIVATED' || c.status == 'SUSPENDED')) {
              // match
            } else if (c.status != _statusFilter) {
              return false;
            }
          }
          if (_searchQuery.isNotEmpty &&
              !c.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
            return false;
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmpty(colors, _statusFilter, l10n);
        }

        // Stats header
        return Column(
          children: [
            _buildStatsRow(colors, clubs, l10n),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _buildClubCard(context, filtered[i], colors),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(l10n?.adminClubsLoadError ?? 'Unable to load the list', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(AppColorsExtension colors, List<Community> clubs, AppLocalizations? l10n) {
    final active = clubs.where((c) => c.status == 'ACTIVE').length;
    final pending = clubs.where((c) => c.status == 'PENDING').length;
    final rejected = clubs.where((c) => c.status == 'REJECTED').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _statChip(colors, l10n?.adminClubsStatTotal ?? 'Total', '${clubs.length}', colors.textPrimary),
          const SizedBox(width: 8),
          _statChip(colors, l10n?.adminClubsStatActive ?? 'Active', '$active', const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _statChip(colors, l10n?.adminClubsStatPending ?? 'Pending', '$pending', const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          _statChip(colors, l10n?.adminClubsStatRejected ?? 'Rejected', '$rejected', const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _statChip(AppColorsExtension colors, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

    Widget _buildClubCard(BuildContext context, Community club, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context);
    final statusColor = club.status == 'ACTIVE'
        ? const Color(0xFF10B981)
        : club.status == 'PENDING'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    final statusLabel = club.status == 'ACTIVE'
        ? (l10n?.adminClubsStatusActive ?? 'Active')
        : club.status == 'PENDING'
            ? (l10n?.adminClubsStatusPending ?? 'Pending')
            : (l10n?.adminClubsStatusRejected ?? 'Rejected');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    (club.name.isNotEmpty ? club.name[0] : '?').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(club.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (club.description != null && club.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(club.description!, style: TextStyle(fontSize: 11, color: colors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.group_outlined, size: 14, color: colors.textMuted),
              const SizedBox(width: 4),
              Text(l10n?.adminClubsMembers(club.memberCount) ?? '${club.memberCount} members', style: TextStyle(fontSize: 11, color: colors.textMuted)),
              const SizedBox(width: 16),
              if (club.locationAddress != null && club.locationAddress!.isNotEmpty) ...[
                Icon(Icons.location_on_outlined, size: 14, color: colors.textMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(club.locationAddress!, style: TextStyle(fontSize: 11, color: colors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            children: [
              // Xem chi tiết
              Expanded(
                child: _actionBtn(
                  icon: Icons.visibility_rounded,
                  label: l10n?.adminClubsView ?? 'View',
                  color: AppTheme.primary,
                  onTap: () => context.push('/club/${club.id}'),
                ),
              ),
              const SizedBox(width: 8),
              // Duyệt (chỉ khi PENDING)
              if (club.status == 'PENDING')
                Expanded(
                  child: _actionBtn(
                    icon: Icons.check_rounded,
                    label: l10n?.adminClubsApprove ?? 'Approve',
                    color: const Color(0xFF10B981),
                    onTap: () => _handleAction(club.id, 'APPROVED', colors),
                  ),
                ),
              if (club.status == 'PENDING') const SizedBox(width: 8),
              // Vô hiệu / Từ chối
              if (club.status != 'REJECTED')
                Expanded(
                  child: _actionBtn(
                    icon: Icons.block_rounded,
                    label: club.status == 'PENDING'
                        ? (l10n?.adminClubsReject ?? 'Reject')
                        : (l10n?.adminClubsDisable ?? 'Disable'),
                    color: colors.textSecondary,
                    outlined: true,
                    onTap: () => _showRejectDialog(context, club, colors),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: outlined ? Border.all(color: color.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: outlined ? color : color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800,
              color: outlined ? color : color,
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(String clubId, String status, AppColorsExtension colors) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(communityRepositoryProvider).reviewCommunity(clubId, status);
      ref.invalidate(_adminClubsProvider);
      invalidateCommunityCollections(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'APPROVED'
              ? (l10n?.adminClubsApprovedFeedback ?? 'Club approved')
              : (l10n?.adminClubsUpdatedFeedback ?? 'Club updated')),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n?.adminClubsActionError ?? 'Unable to update the club. Please try again.'),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showRejectDialog(BuildContext context, Community club, AppColorsExtension colors) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgCard,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            Text(club.status == 'PENDING'
                ? (l10n?.adminClubsRejectTitle ?? 'Reject club')
                : (l10n?.adminClubsDisableTitle ?? 'Disable club'),
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 200,
          style: TextStyle(color: colors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: l10n?.adminClubsReasonHint ?? 'Reason (required)',
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
            filled: true,
            fillColor: colors.bgSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.adminClubsCancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                await ref.read(communityRepositoryProvider).reviewCommunity(
                  club.id,
                  club.status == 'PENDING' ? 'REJECTED' : 'REJECTED',
                  rejectedReason: controller.text.trim(),
                );
                ref.invalidate(_adminClubsProvider);
                invalidateCommunityCollections(ref);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n?.adminClubsRejectError ?? 'Unable to process the club. Please try again.'),
                    backgroundColor: context.colors.error,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n?.adminClubsConfirm ?? 'Confirm', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppColorsExtension colors, String filter, AppLocalizations? l10n) {
    String message;
    if (filter == 'all') {
      message = l10n?.adminClubsEmptyAll ?? 'No clubs yet';
    } else if (filter == 'ACTIVE') {
      message = l10n?.adminClubsEmptyActive ?? 'No active clubs';
    } else if (filter == 'PENDING') {
      message = l10n?.adminClubsEmptyPending ?? 'No clubs pending approval';
    } else {
      message = l10n?.adminClubsEmptyRejected ?? 'No rejected clubs';
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_rounded, size: 64, color: colors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        ],
      ),
    );
  }
}

// Provider: lấy tất cả CLB (admin)
final _adminClubsProvider = FutureProvider<List<Community>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/communities', queryParameters: {'limit': 200, 'all': true});
  if (response.statusCode == 200) {
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => Community.fromJson(e as Map<String, dynamic>)).toList();
  }
  return [];
});
