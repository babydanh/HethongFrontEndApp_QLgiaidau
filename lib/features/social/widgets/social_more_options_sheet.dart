import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum _SocialMoreOptionsAction { repeat, edit, cancel, report, hide }

class SocialMoreOptionsSheet extends StatelessWidget {
  const SocialMoreOptionsSheet({
    super.key,
    required this.session,
    required this.isHost,
  });

  final SocialSessionModel session;
  final bool isHost;

  static Future<void> show(
    BuildContext context,
    SocialSessionModel session, {
    required bool isHost,
    required VoidCallback onRepeat,
    required VoidCallback onEdit,
    required VoidCallback onCancel,
    required VoidCallback onMute,
    required VoidCallback onReport,
  }) async {
    final action = await showModalBottomSheet<_SocialMoreOptionsAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: context.colors.bgCard,
      builder: (_) => SocialMoreOptionsSheet(
        session: session,
        isHost: isHost,
      ),
    );
    // showModalBottomSheet completes after the route's closing transition.
    if (action == _SocialMoreOptionsAction.repeat) onRepeat();
    if (action == _SocialMoreOptionsAction.edit) onEdit();
    if (action == _SocialMoreOptionsAction.cancel) onCancel();
    if (action == _SocialMoreOptionsAction.report) onReport();
  }

  Widget _option(
    BuildContext context,
    String title,
    _SocialMoreOptionsAction action, {
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
      onTap: () => Navigator.pop(context, action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canManageSession = const {'OPEN', 'FULL'}.contains(
      session.status.toUpperCase(),
    );
    if (!isHost) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _option(
                context,
                'Báo cáo buổi Social này',
                _SocialMoreOptionsAction.report,
                icon: Icons.report_problem_outlined,
              ),
              _option(
                context,
                'Ẩn các buổi của Host này',
                _SocialMoreOptionsAction.hide,
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
            _option(
              context,
              AppLocalizations.of(context)!.social_repeat,
              _SocialMoreOptionsAction.repeat,
            ),
            if (canManageSession) ...[
              _option(
                context,
                'Chỉnh sửa kèo',
                _SocialMoreOptionsAction.edit,
              ),
              _option(
                context,
                'Hủy kèo',
                _SocialMoreOptionsAction.cancel,
                destructive: true,
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
