import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Admin — Yêu cầu xác thực (Verification Requests)
///
/// Hiển thị các yêu cầu xác thực:
/// - Xác thực tài khoản người dùng
/// - Xác thực CLB
/// - Xác thực giải đấu
class AdminVerificationScreen extends ConsumerStatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  ConsumerState<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends ConsumerState<AdminVerificationScreen> {
  String _typeFilter = 'all'; // all, user, club, tournament
  String _statusFilter = 'all'; // all, pending, verified, rejected

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
          l10n?.adminVerificationTitle ?? 'Verification',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTypeFilter(colors, l10n),
          _buildStatusFilter(colors, l10n),
          Expanded(child: _buildVerificationList(colors, l10n)),
        ],
      ),
    );
  }

  Widget _buildTypeFilter(AppColorsExtension colors, AppLocalizations? l10n) {
    final types = [
      ('all', l10n?.adminVerificationTypeAll ?? 'All', AppTheme.primary),
      ('user', l10n?.adminVerificationTypeUser ?? 'User', const Color(0xFF3B82F6)),
      ('club', l10n?.adminVerificationTypeClub ?? 'Club', const Color(0xFF10B981)),
      ('tournament', l10n?.adminVerificationTypeTournament ?? 'Tournament', const Color(0xFFF59E0B)),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: types.map((t) {
          final selected = _typeFilter == t.$1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: t != types.last ? 6 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _typeFilter = t.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? t.$3.withValues(alpha: 0.12) : colors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? t.$3.withValues(alpha: 0.4) : colors.border,
                    ),
                  ),
                  child: Text(
                    t.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: selected ? t.$3 : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusFilter(AppColorsExtension colors, AppLocalizations? l10n) {
    final statuses = [
      ('all', l10n?.adminVerificationStatusAll ?? 'All', AppTheme.primary),
      ('pending', l10n?.adminVerificationStatusPending ?? 'Pending', const Color(0xFFF59E0B)),
      ('verified', l10n?.adminVerificationStatusVerified ?? 'Verified', const Color(0xFF10B981)),
      ('rejected', l10n?.adminVerificationStatusRejected ?? 'Rejected', const Color(0xFFEF4444)),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: statuses.map((s) {
          final selected = _statusFilter == s.$1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: s != statuses.last ? 6 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _statusFilter = s.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? s.$3.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? s.$3.withValues(alpha: 0.4) : colors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    s.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: selected ? s.$3 : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVerificationList(AppColorsExtension colors, AppLocalizations? l10n) {
    final requestsAsync = ref.watch(_adminVerificationProvider);

    return requestsAsync.when(
      data: (requests) {
        final filtered = requests.where((r) {
          if (_typeFilter != 'all' && r['type']?.toString().toLowerCase() != _typeFilter) return false;
          if (_statusFilter != 'all') {
            final status = r['status']?.toString().toLowerCase() ?? '';
            if (status != _statusFilter) return false;
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_outlined, size: 64, color: colors.textMuted.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text(l10n?.adminVerificationEmpty ?? 'No verification requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: filtered.length,
          itemBuilder: (context, i) => _buildVerificationCard(context, filtered[i], colors),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(l10n?.adminVerificationLoadError ?? 'Unable to load data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          ],
        ),
      ),
    );
  }

    Widget _buildVerificationCard(BuildContext context, Map<String, dynamic> request, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context);
    final type = request['type']?.toString() ?? 'USER';
    final status = request['status']?.toString() ?? 'PENDING';
    final name = request['name']?.toString() ?? request['fullName']?.toString() ?? '---';
    final email = request['email']?.toString() ?? '';
    final reason = request['reason']?.toString() ?? '';
    final createdAt = request['createdAt']?.toString() ?? '';

    final typeLabel = type == 'USER'
        ? (l10n?.adminVerificationTypeUser ?? 'User')
        : type == 'CLUB'
            ? (l10n?.adminVerificationTypeClub ?? 'Club')
            : (l10n?.adminVerificationTypeTournament ?? 'Tournament');
    final typeIcon = type == 'USER'
        ? Icons.person_rounded
        : type == 'CLUB'
            ? Icons.groups_rounded
            : Icons.emoji_events_rounded;
    final typeColor = type == 'USER'
        ? const Color(0xFF3B82F6)
        : type == 'CLUB'
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B);

    final isPending = status.toUpperCase() == 'PENDING';
    final statusColor = status.toUpperCase() == 'VERIFIED'
        ? const Color(0xFF10B981)
        : status.toUpperCase() == 'REJECTED'
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);
    final statusLabel = status.toUpperCase() == 'VERIFIED'
        ? (l10n?.adminVerificationStatusVerifiedLabel ?? 'Verified')
        : status.toUpperCase() == 'REJECTED'
            ? (l10n?.adminVerificationStatusRejectedLabel ?? 'Rejected')
            : (l10n?.adminVerificationStatusPendingLabel ?? 'Pending');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(typeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: typeColor)),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(email, style: TextStyle(fontSize: 11, color: colors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
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
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(reason, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4)),
            ),
          ],
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(createdAt.substring(0, 10), style: TextStyle(fontSize: 10, color: colors.textMuted)),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    l10n?.adminVerificationApprove ?? 'Verify', Icons.check_rounded, const Color(0xFF10B981),
                    () => _handleAction(request['id'], 'VERIFIED', colors),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    l10n?.adminVerificationReject ?? 'Reject', Icons.close_rounded, const Color(0xFFEF4444),
                    () => _handleReject(request['id'], colors),
                    outlined: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap, {bool outlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: outlined ? Border.all(color: color.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: outlined ? color : color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: outlined ? color : color)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(String? id, String status, AppColorsExtension colors) async {
    if (id == null) return;
    final l10n = AppLocalizations.of(context);
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/admin/verification/$id', data: {'status': status});
      ref.invalidate(_adminVerificationProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n?.adminVerificationVerifiedFeedback ?? 'Verification approved'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
            if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n?.adminVerificationActionError ?? 'Unable to process the verification request. Please try again.'),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _handleReject(String? id, AppColorsExtension colors) async {
    if (id == null) return;
    final l10n = AppLocalizations.of(context);
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgCard,
        title: Text(l10n?.adminVerificationRejectTitle ?? 'Reject verification'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          maxLength: 200,
          style: TextStyle(color: colors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: l10n?.adminVerificationRejectReasonHint ?? 'Rejection reason (required)',
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
            filled: true,
            fillColor: colors.bgSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n?.adminVerificationCancel ?? 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n?.adminVerificationReject ?? 'Reject', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonCtrl.text.trim().isEmpty) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/admin/verification/$id', data: {
        'status': 'REJECTED',
        'rejectedReason': reasonCtrl.text.trim(),
      });
      ref.invalidate(_adminVerificationProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n?.adminVerificationRejectedFeedback ?? 'Verification rejected'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
            if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n?.adminVerificationRejectError ?? 'Unable to reject the verification. Please try again.'),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

final _adminVerificationProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/verification', queryParameters: {'limit': 100});
  final data = response.data['data'] as List<dynamic>? ?? [];
  return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
