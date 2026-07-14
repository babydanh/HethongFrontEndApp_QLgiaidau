import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';

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
        title: const Text('Quản lý CLB', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(colors),
          // Status filter chips
          _buildFilterChips(colors),
          // Club list
          Expanded(child: _buildClubList(colors)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm CLB...',
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

  Widget _buildFilterChips(AppColorsExtension colors) {
    final filters = [
      ('all', 'Tất cả', colors.textPrimary),
      ('ACTIVE', 'Hoạt động', const Color(0xFF10B981)),
      ('PENDING', 'Chờ duyệt', const Color(0xFFF59E0B)),
      ('REJECTED', 'Từ chối', const Color(0xFFEF4444)),
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

  Widget _buildClubList(AppColorsExtension colors) {
    // Dùng pendingCommunitiesProvider cho PENDING, getAll cho phần còn lại
    // Tạm thời dùng FutureProvider tự build
    final clubsAsync = ref.watch(_adminClubsProvider);

    return clubsAsync.when(
      data: (clubs) {
        final filtered = clubs.where((c) {
          if (_statusFilter != 'all' && c.status != _statusFilter) return false;
          if (_searchQuery.isNotEmpty &&
              !c.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
            return false;
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmpty(colors, _statusFilter);
        }

        // Stats header
        return Column(
          children: [
            _buildStatsRow(colors, clubs),
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
            Text('Lỗi tải danh sách', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(AppColorsExtension colors, List<Community> clubs) {
    final active = clubs.where((c) => c.status == 'ACTIVE').length;
    final pending = clubs.where((c) => c.status == 'PENDING').length;
    final rejected = clubs.where((c) => c.status == 'REJECTED').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _statChip(colors, 'Tổng', '${clubs.length}', colors.textPrimary),
          const SizedBox(width: 8),
          _statChip(colors, 'Hoạt động', '$active', const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _statChip(colors, 'Chờ', '$pending', const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          _statChip(colors, 'Từ chối', '$rejected', const Color(0xFFEF4444)),
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
    final statusColor = club.status == 'ACTIVE'
        ? const Color(0xFF10B981)
        : club.status == 'PENDING'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    final statusLabel = club.status == 'ACTIVE'
        ? 'Hoạt động'
        : club.status == 'PENDING'
            ? 'Chờ duyệt'
            : 'Từ chối';

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
              Text('${club.memberCount} TV', style: TextStyle(fontSize: 11, color: colors.textMuted)),
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
                  label: 'Xem',
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
                    label: 'Duyệt',
                    color: const Color(0xFF10B981),
                    onTap: () => _handleAction(club.id, 'ACTIVE', colors),
                  ),
                ),
              if (club.status == 'PENDING') const SizedBox(width: 8),
              // Vô hiệu / Từ chối
              if (club.status != 'REJECTED')
                Expanded(
                  child: _actionBtn(
                    icon: Icons.block_rounded,
                    label: club.status == 'PENDING' ? 'Từ chối' : 'Vô hiệu',
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
    try {
      await ref.read(communityRepositoryProvider).reviewCommunity(clubId, status);
      ref.invalidate(_adminClubsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'ACTIVE' ? 'Đã duyệt CLB' : 'Đã cập nhật CLB'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showRejectDialog(BuildContext context, Community club, AppColorsExtension colors) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgCard,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            Text(club.status == 'PENDING' ? 'Từ chối CLB' : 'Vô hiệu hoá CLB',
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 200,
          style: TextStyle(color: colors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Lý do (bắt buộc)',
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
            filled: true,
            fillColor: colors.bgSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
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
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: context.colors.error,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppColorsExtension colors, String filter) {
    String message;
    if (filter == 'all') {
      message = 'Chưa có câu lạc bộ nào';
    } else if (filter == 'ACTIVE') {
      message = 'Không có CLB đang hoạt động';
    } else if (filter == 'PENDING') {
      message = 'Không có CLB chờ duyệt';
    } else {
      message = 'Không có CLB bị từ chối';
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
