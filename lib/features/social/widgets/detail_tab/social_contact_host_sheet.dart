import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialContactHostSheet extends StatelessWidget {
  const SocialContactHostSheet({
    super.key,
    required this.session,
    required this.onOpenChat,
  });

  final SocialSessionModel session;
  final VoidCallback onOpenChat;

  static Future<void> show(
    BuildContext context,
    SocialSessionModel session, {
    required VoidCallback onOpenChat,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          SocialContactHostSheet(session: session, onOpenChat: onOpenChat),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Liên hệ Host: ${session.hostClubName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (session.hostPhone != null)
              ListTile(
                leading: Icon(Icons.phone, color: colors.success),
                title: Text('Gọi điện: ${session.hostPhone}'),
                onTap: () {
                  Navigator.pop(context);
                  launchUrl(Uri.parse('tel:${session.hostPhone}'));
                },
              ),
            if (session.zaloGroupUrl != null)
              ListTile(
                leading: const Icon(Icons.group, color: AppTheme.primary),
                title: const Text('Tham gia nhóm Zalo'),
                subtitle: Text(session.zaloGroupUrl!),
                onTap: () {
                  Navigator.pop(context);
                  launchUrl(
                    Uri.parse(session.zaloGroupUrl!),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.chat_bubble_outline,
                color: AppTheme.primary,
              ),
              title: const Text('Gửi tin nhắn trong app'),
              onTap: () {
                Navigator.pop(context);
                onOpenChat();
              },
            ),
          ],
        ),
      ),
    );
  }
}
