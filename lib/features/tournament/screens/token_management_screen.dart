import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/extensions/string_extensions.dart';
import 'package:app_quanly_giaidau/core/dialogs/confirm_dialog.dart';

import 'package:app_quanly_giaidau/data/models/token_model.dart';
import 'package:app_quanly_giaidau/providers/token_management_notifier.dart';

class TokenManagementScreen extends ConsumerWidget {
  final String tournamentId;
  final bool isEmbedded;

  const TokenManagementScreen({
    super.key,
    required this.tournamentId,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokensState = ref.watch(tokenManagementProvider(tournamentId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        leading: isEmbedded
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.go('/admin/tournament/$tournamentId'),
              ),
        title: const Text('Quản lý Mã Truy Cập'),
      ),
      body: tokensState.when(
        data: (tokens) {
          // Lọc ra các token đang active
          final activeTokens = tokens.where((t) => t.isActive).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeTokens.length,
            itemBuilder: (context, index) {
              final token = activeTokens[index];
              return _TokenCard(
                key: ValueKey(
                  token.code,
                ), // ADDED KEY to fix Riverpod hot-reload RangeError
                token: token,
                tournamentId: tournamentId,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Đã xảy ra lỗi: $error',
            style: TextStyle(color: context.colors.error),
          ),
        ),
      ),
    );
  }
}

class _TokenCard extends ConsumerWidget {
  final TokenModel token;
  final String tournamentId;

  const _TokenCard({
    super.key,
    required this.token,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theo dõi số người dùng online thông qua Provider (tối ưu hơn StreamBuilder)
    final onlineCountAsync = ref.watch(
      presenceCountProvider((tournamentId: tournamentId, role: token.role)),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  token.role.toRoleDisplayName(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                onlineCountAsync.when(
                  data: (count) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: count > 0
                            ? context.colors.success.withValues(alpha: 0.1)
                            : context.colors.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: count > 0
                                ? context.colors.success
                                : context.colors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$count online',
                            style: TextStyle(
                              color: count > 0
                                  ? context.colors.success
                                  : context.colors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (error, stackTrace) => const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    token.code,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code, color: AppTheme.primary),
                    onPressed: () => _showQrDialog(context, token.code),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _regenerateToken(context, ref),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Làm mới mã'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.error,
                      side: BorderSide(color: context.colors.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _regenerateToken(BuildContext context, WidgetRef ref) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: 'Xác nhận làm mới',
      content: 'Bạn có chắc muốn làm mới mã ${token.role.toRoleDisplayName()}?\n\n'
          'Những người đang truy cập bằng mã cũ sẽ bị đăng xuất khỏi giải ngay lập tức!',
      confirmText: 'Đồng ý Làm mới',
    );

    if (confirm == true) {
      final success = await ref
          .read(tokenManagementProvider(tournamentId).notifier)
          .regenerateToken(token.role);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo mã mới thành công!')),
        );
      }
    }
  }

  void _showQrDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'QR Code - ${token.role.toRoleDisplayName()}',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: QrImageView(
                data: 'app_quanly_giaidau:join?code=$code',
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mã: $code',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Quét mã này để truy cập trực tiếp vào giải đấu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
