import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/models/chat_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum ChatNotificationMode { all, mentionsOnly, muted }

class ChatRoomSettingsSheet extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;
  final String? roomAvatar;
  final String? roomType;
  final String? communityId;
  final ChatMessageModel? pinnedMessage;
  final List<ChatMessageModel> messages;
  final VoidCallback? onUnpinMessage;
  final Function(String messageId)? onJumpToMessage;

  const ChatRoomSettingsSheet({
    super.key,
    required this.roomId,
    required this.roomName,
    this.roomAvatar,
    this.roomType,
    this.communityId,
    this.pinnedMessage,
    this.messages = const [],
    this.onUnpinMessage,
    this.onJumpToMessage,
  });

  static Future<void> show(
    BuildContext context, {
    required String roomId,
    required String roomName,
    String? roomAvatar,
    String? roomType,
    String? communityId,
    ChatMessageModel? pinnedMessage,
    List<ChatMessageModel> messages = const [],
    VoidCallback? onUnpinMessage,
    Function(String messageId)? onJumpToMessage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChatRoomSettingsSheet(
        roomId: roomId,
        roomName: roomName,
        roomAvatar: roomAvatar,
        roomType: roomType,
        communityId: communityId,
        pinnedMessage: pinnedMessage,
        messages: messages,
        onUnpinMessage: onUnpinMessage,
        onJumpToMessage: onJumpToMessage,
      ),
    );
  }

  @override
  ConsumerState<ChatRoomSettingsSheet> createState() => _ChatRoomSettingsSheetState();
}

class _ChatRoomSettingsSheetState extends ConsumerState<ChatRoomSettingsSheet> {
  ChatNotificationMode _notifMode = ChatNotificationMode.all;
  bool _notifyReactions = true;
  bool _notifyReplies = true;
  bool _soundEnabled = true;
  bool _isLoadingMembers = false;
  List<ChatParticipant> _participants = [];

  @override
  void initState() {
    super.initState();
    _loadRoomSettings();
  }

  Future<void> _loadRoomSettings() async {
    setState(() => _isLoadingMembers = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get('/chat/rooms/${widget.roomId}');
      final data = res.data is Map ? (res.data['data'] ?? res.data) : null;
      if (data is Map<String, dynamic> && mounted) {
        final rawParts = data['participants'] ?? data['members'];
        if (rawParts is List) {
          _participants = rawParts
              .whereType<Map<String, dynamic>>()
              .map((p) => ChatParticipant.fromJson(p))
              .toList();
        }
        final notifPref = data['notificationPref']?.toString().toUpperCase();
        if (notifPref == 'MUTED') {
          _notifMode = ChatNotificationMode.muted;
        } else if (notifPref == 'MENTIONS_ONLY' || notifPref == 'MENTIONS') {
          _notifMode = ChatNotificationMode.mentionsOnly;
        } else {
          _notifMode = ChatNotificationMode.all;
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _updateNotifMode(ChatNotificationMode mode) async {
    setState(() => _notifMode = mode);

    try {
      final dio = ref.read(dioClientProvider).dio;
      final prefStr = mode == ChatNotificationMode.muted
          ? 'MUTED'
          : mode == ChatNotificationMode.mentionsOnly
              ? 'MENTIONS'
              : 'ALL';
      await dio.put(
        '/chat/rooms/${widget.roomId}/notifications',
        data: {
          'pref': prefStr,
          'notifyReactions': _notifyReactions,
          'notifyReplies': _notifyReplies,
          'soundEnabled': _soundEnabled,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mode == ChatNotificationMode.muted
                ? 'Đã tắt thông báo phòng chat'
                : mode == ChatNotificationMode.mentionsOnly
                    ? 'Chỉ nhận thông báo khi được nhắc tên (@mention)'
                    : 'Đã bật tất cả thông báo'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (_) {
      // Fallback local state is kept
    }
  }

  List<String> get _allSharedMedia {
    final list = <String>[];
    for (final m in widget.messages) {
      if (m.mediaUrls.isNotEmpty) {
        list.addAll(m.mediaUrls);
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F22) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: colors.borderLight,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    'Tùy chọn & Thông báo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Room Profile Banner Card
                _buildProfileBanner(colors),
                const SizedBox(height: 16),

                // Quick Action Buttons
                _buildQuickActions(colors),
                const SizedBox(height: 20),

                // ── Notification Settings Section ──
                _buildSectionHeader('CÀI ĐẶT THÔNG BÁO', Icons.notifications_active_outlined, colors),
                const SizedBox(height: 8),
                _buildNotificationCard(colors),
                const SizedBox(height: 20),

                // ── Pinned Messages Section ──
                if (widget.pinnedMessage != null) ...[
                  _buildSectionHeader('TIN NHẮN ĐÃ GHIM', Icons.push_pin_outlined, colors),
                  const SizedBox(height: 8),
                  _buildPinnedCard(colors),
                  const SizedBox(height: 20),
                ],

                // ── Shared Media Section ──
                _buildSectionHeader('ẢNH & PHƯƠNG TIỆN ĐÃ CHIA SẺ (${_allSharedMedia.length})', Icons.photo_library_outlined, colors),
                const SizedBox(height: 8),
                _buildMediaGrid(colors),
                const SizedBox(height: 20),

                // ── Members Section ──
                _buildSectionHeader('THÀNH VIÊN TRONG PHÒNG (${_participants.isNotEmpty ? _participants.length : 1})', Icons.people_alt_outlined, colors),
                const SizedBox(height: 8),
                _buildMembersList(colors),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, AppColorsExtension colors) {
    return Row(
      children: [
        Icon(icon, size: 14, color: colors.textMuted),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: colors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileBanner(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.primaryLight,
            backgroundImage: widget.roomAvatar != null && widget.roomAvatar!.isNotEmpty
                ? NetworkImage(widget.roomAvatar!)
                : null,
            child: widget.roomAvatar == null || widget.roomAvatar!.isEmpty
                ? Text(
                    widget.roomName.characters.first.toUpperCase(),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            widget.roomName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.roomType == 'CLUB' ? '👥 CÂU LẠC BỘ' : '💬 TRỰC TIẾP',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
              ),
              if (widget.communityId != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/club/${widget.communityId}');
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Xem trang CLB', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(AppColorsExtension colors) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: _notifMode == ChatNotificationMode.muted
                ? Icons.notifications_off_rounded
                : Icons.notifications_active_rounded,
            label: _notifMode == ChatNotificationMode.muted ? 'Đã tắt âm' : 'Thông báo',
            color: _notifMode == ChatNotificationMode.muted ? colors.error : AppTheme.primary,
            onTap: () {
              _updateNotifMode(_notifMode == ChatNotificationMode.muted
                  ? ChatNotificationMode.all
                  : ChatNotificationMode.muted);
            },
            colors: colors,
          ),
        ),
        const SizedBox(width: 10),
        if (widget.communityId != null)
          Expanded(
            child: _buildActionButton(
              icon: Icons.groups_rounded,
              label: 'Trang CLB',
              color: const Color(0xFF059669),
              onTap: () {
                Navigator.pop(context);
                context.push('/club/${widget.communityId}');
              },
              colors: colors,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppColorsExtension colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          // Radio 1: All notifications
          _buildRadioTile(
            title: 'Tất cả tin nhắn',
            subtitle: 'Nhận thông báo cho mọi tin nhắn, ảnh và bình chọn',
            icon: Icons.notifications_active_outlined,
            selected: _notifMode == ChatNotificationMode.all,
            onTap: () => _updateNotifMode(ChatNotificationMode.all),
            colors: colors,
          ),
          const Divider(height: 1),

          // Radio 2: Mentions only
          _buildRadioTile(
            title: 'Chỉ khi được nhắc tên (@mentions)',
            subtitle: 'Chỉ thông báo khi ai đó nhắc đến bạn (@bạn)',
            icon: Icons.alternate_email_rounded,
            selected: _notifMode == ChatNotificationMode.mentionsOnly,
            onTap: () => _updateNotifMode(ChatNotificationMode.mentionsOnly),
            colors: colors,
          ),
          const Divider(height: 1),

          // Radio 3: Muted
          _buildRadioTile(
            title: 'Tắt thông báo',
            subtitle: 'Tắt toàn bộ thông báo từ phòng chat này',
            icon: Icons.notifications_off_outlined,
            selected: _notifMode == ChatNotificationMode.muted,
            onTap: () => _updateNotifMode(ChatNotificationMode.muted),
            colors: colors,
          ),
          const Divider(height: 1),

          // Sub-toggle: Reactions
          SwitchListTile(
            title: const Text('Thông báo khi thả cảm xúc ❤️', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            subtitle: Text('Nhận thông báo khi thành viên bày tỏ cảm xúc', style: TextStyle(fontSize: 11.5, color: colors.textMuted)),
            value: _notifyReactions,
            activeThumbColor: AppTheme.primary,
            onChanged: (v) {
              setState(() => _notifyReactions = v);
              _updateNotifMode(_notifMode);
            },
          ),
          const Divider(height: 1),

          // Sub-toggle: Replies
          SwitchListTile(
            title: const Text('Thông báo khi có người trả lời 💬', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            subtitle: Text('Nhận thông báo khi ai đó trả lời tin nhắn của bạn', style: TextStyle(fontSize: 11.5, color: colors.textMuted)),
            value: _notifyReplies,
            activeThumbColor: AppTheme.primary,
            onChanged: (v) {
              setState(() => _notifyReplies = v);
              _updateNotifMode(_notifMode);
            },
          ),
          const Divider(height: 1),

          // Sub-toggle: Sound
          SwitchListTile(
            title: const Text('Âm thanh thông báo 🔊', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            subtitle: Text('Phát âm thanh khi có tin nhắn mới', style: TextStyle(fontSize: 11.5, color: colors.textMuted)),
            value: _soundEnabled,
            activeThumbColor: AppTheme.primary,
            onChanged: (v) {
              setState(() => _soundEnabled = v);
              _updateNotifMode(_notifMode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.12) : colors.bgSurface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: selected ? AppTheme.primary : colors.textMuted),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: selected ? FontWeight.bold : FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11.5, color: colors.textMuted),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20)
          : const Icon(Icons.radio_button_unchecked_rounded, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildPinnedCard(AppColorsExtension colors) {
    final pin = widget.pinnedMessage!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.push_pin_rounded, color: Color(0xFFD97706), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ghim từ: ${pin.senderName}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                ),
                const SizedBox(height: 2),
                Text(
                  pin.content.isNotEmpty ? pin.content : '[Hình ảnh/Phương tiện]',
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.onJumpToMessage != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              tooltip: 'Đi đến tin nhắn',
              onPressed: () {
                Navigator.pop(context);
                widget.onJumpToMessage!(pin.id);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(AppColorsExtension colors) {
    final media = _allSharedMedia;
    if (media.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          'Chưa có hình ảnh nào được chia sẻ trong phòng chat này.',
          style: TextStyle(fontSize: 12.5, color: colors.textMuted),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: media.length > 8 ? 8 : media.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemBuilder: (ctx, i) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              media[i],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMembersList(AppColorsExtension colors) {
    if (_isLoadingMembers) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (_participants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tất cả thành viên trong CLB đều có quyền tham gia và nhắn tin.',
                style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: _participants.map((p) {
          final isOwner = p.role == 'OWNER';
          final isAdmin = p.role == 'ADMIN' || p.role == 'MODERATOR';
          return ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryLight,
              backgroundImage: p.avatarUrl != null && p.avatarUrl!.isNotEmpty ? NetworkImage(p.avatarUrl!) : null,
              child: p.avatarUrl == null || p.avatarUrl!.isEmpty
                  ? Text(
                      p.fullName.characters.first.toUpperCase(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                    )
                  : null,
            ),
            title: Text(p.fullName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            trailing: isOwner
                ? _buildRoleBadge('CHỦ NHIỆM', const Color(0xFFEA580C))
                : isAdmin
                    ? _buildRoleBadge('QUẢN TRỊ', AppTheme.primary)
                    : _buildRoleBadge('THÀNH VIÊN', colors.textMuted),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
