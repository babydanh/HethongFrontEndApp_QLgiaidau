import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SocialFindPlayersSheet extends StatelessWidget {
  const SocialFindPlayersSheet({
    super.key,
    required this.session,
    required this.onShareToChat,
  });

  final SocialSessionModel session;
  final VoidCallback onShareToChat;

  static Future<void> show(
    BuildContext context,
    SocialSessionModel session, {
    required VoidCallback onShareToChat,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SocialFindPlayersSheet(
        session: session,
        onShareToChat: onShareToChat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = this.session;
    final colors = context.colors;
    final ctx = context;
    final messenger = ScaffoldMessenger.of(context);
    final shareUrl = session.shareUrl;
    final inviteMessage = shareUrl == null
        ? null
        : '''${session.title}
⏰ ${session.dayOfWeek}, ngày ${session.dayOfMonth.toString().padLeft(2, '0')} Th${session.dateTime.month.toString().padLeft(2, '0')} lúc ${session.timeSlot}
📍 ${session.venueName}

Link: $shareUrl''';

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Tìm thêm người chơi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Preview Card (IMG3)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('⏰ ', style: TextStyle(fontSize: 13)),
                        Text(
                          '${session.dayOfWeek}, ngày ${session.dayOfMonth.toString().padLeft(2, '0')} Th${session.dateTime.month.toString().padLeft(2, '0')} lúc ${session.timeSlot}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('📍 ', style: TextStyle(fontSize: 13)),
                        Expanded(
                          child: Text(
                            session.venueName,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      shareUrl == null
                          ? 'Link rút gọn chưa sẵn sàng. Vui lòng thử lại sau.'
                          : 'Link: $shareUrl',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: colors.border, height: 1),
                    const SizedBox(height: 8),

                    // Button 'Sao chép tin nhắn' inside the card
                    InkWell(
                      onTap: inviteMessage == null
                          ? null
                          : () {
                              Clipboard.setData(
                                ClipboardData(text: inviteMessage),
                              );
                              Navigator.pop(ctx);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Đã sao chép tin nhắn mời!',
                                  ),
                                  backgroundColor: colors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Sao chép tin nhắn',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Option 1: Sao chép tin nhắn
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.copy_rounded,
                  color: colors.textPrimary,
                  size: 22,
                ),
                title: Text(
                  'Sao chép tin nhắn',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                onTap: inviteMessage == null
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: inviteMessage));
                        Navigator.pop(ctx);
                        messenger.showSnackBar(
                          SnackBar(
                            content: const Text('Đã sao chép tin nhắn mời!'),
                            backgroundColor: colors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
              ),

              // Option 2: Chia sẻ trong cuộc trò chuyện (IMG4)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: colors.textPrimary,
                  size: 22,
                ),
                title: Text(
                  'Chia sẻ trong cuộc trò chuyện',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                onTap: shareUrl == null
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        onShareToChat();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
