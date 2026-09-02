import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class ShimmerPlaceholder extends StatelessWidget {
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    this.height = 20.0,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ShimmerBody extends StatelessWidget {
  const ShimmerBody({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            const ShimmerPlaceholder(height: 48, borderRadius: 12),
            const SizedBox(height: 16),
            const ShimmerPlaceholder(height: 100, borderRadius: 16),
            const SizedBox(height: 16),
            const ShimmerPlaceholder(height: 180, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}

class NotFoundView extends StatelessWidget {
  final VoidCallback onGoHome;

  const NotFoundView({super.key, required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 72,
            color: context.colors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tournamentNotFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onGoHome,
            icon: const Icon(Icons.home_rounded),
            label: Text(l10n.matchGoHome),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 72,
              color: context.colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tournamentLoadError,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: context.colors.textMuted),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.infoRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivateTournamentAccessView extends StatefulWidget {
  final String? message;
  final VoidCallback onGoHome;
  final ValueChanged<String>? onSubmitInviteCode;

  const PrivateTournamentAccessView({
    super.key,
    this.message,
    required this.onGoHome,
    this.onSubmitInviteCode,
  });

  @override
  State<PrivateTournamentAccessView> createState() =>
      _PrivateTournamentAccessViewState();
}

class _PrivateTournamentAccessViewState
    extends State<PrivateTournamentAccessView> {
  final TextEditingController _inviteController = TextEditingController();

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDE68A), width: 2),
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 56,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                'GIẢI ĐẤU NỘI BỘ CLB',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB45309),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa Có Quyền Truy Cập',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.message ??
                  'Đây là giải đấu nội bộ dành riêng cho thành viên Câu Lạc Bộ. Bạn cần tham gia Câu Lạc Bộ hoặc nhập mã mời từ ban tổ chức để xem chi tiết.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: colors.textSecondary,
              ),
            ),
            if (widget.onSubmitInviteCode != null) ...[
              const SizedBox(height: 24),
              TextField(
                controller: _inviteController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Nhập mã mời giải đấu (nếu có)',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: colors.bgSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded),
                    onPressed: () {
                      final code = _inviteController.text.trim();
                      if (code.isNotEmpty) {
                        widget.onSubmitInviteCode!(code);
                      }
                    },
                  ),
                ),
                onSubmitted: (code) {
                  if (code.trim().isNotEmpty) {
                    widget.onSubmitInviteCode!(code.trim());
                  }
                },
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: widget.onGoHome,
              icon: const Icon(Icons.home_rounded, size: 18),
              label: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}
