import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:flutter/material.dart';

class SocialMoreOptionsSheet extends StatelessWidget {
  const SocialMoreOptionsSheet({
    super.key,
    required this.session,
    required this.isHost,
    required this.onRepeat,
    required this.onEdit,
    required this.onCancel,
    required this.onMute,
    required this.onReport,
  });

  final SocialSessionModel session;
  final bool isHost;
  final VoidCallback onRepeat;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onMute;
  final VoidCallback onReport;

  static Future<void> show(
    BuildContext context,
    SocialSessionModel session, {
    required bool isHost,
    required VoidCallback onRepeat,
    required VoidCallback onEdit,
    required VoidCallback onCancel,
    required VoidCallback onMute,
    required VoidCallback onReport,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: context.colors.bgCard,
      builder: (_) => SocialMoreOptionsSheet(
        session: session,
        isHost: isHost,
        onRepeat: onRepeat,
        onEdit: onEdit,
        onCancel: onCancel,
        onMute: onMute,
        onReport: onReport,
      ),
    );
  }

  Widget _option(
    BuildContext context,
    String title,
    VoidCallback action, {
    IconData? icon,
    bool destructive = false,
  }) {
    final colors = context.colors;
    return ListTile(
      leading: icon == null ? null : Icon(icon, color: colors.textPrimary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          color: destructive ? colors.error : colors.textPrimary,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        action();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (!isHost) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _option(
                context,
                'Báo cáo buổi Social này',
                onReport,
                icon: Icons.report_problem_outlined,
              ),
              _option(
                context,
                'Ẩn các buổi của Host này',
                () {},
                icon: Icons.block_outlined,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text(
                session.title,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Divider(height: 1, color: colors.border),
            _option(context, 'Lặp lại kèo', onRepeat),
            Divider(height: 1, color: colors.border),
            _option(context, 'Chỉnh sửa kèo', onEdit),
            Divider(height: 1, color: colors.border),
            _option(context, 'Hủy kèo', onCancel, destructive: true),
            Divider(height: 1, color: colors.border),
            _option(context, 'Tắt thông báo cuộc trò chuyện', onMute),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
